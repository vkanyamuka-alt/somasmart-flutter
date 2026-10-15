// ==============================================================================
// SOMASMART SUPABASE EDGE FUNCTION: fimipay-check-status
// Checks / reconciles order status directly with FimiPay order_status API.
// Supports read-only querying as well as server-authoritative fulfillment.
// ==============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const fimipaySecretKey = Deno.env.get("FIMIPAY_SECRET_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration missing." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Authenticate caller (User token, Service Role Key, or Anon Key)
    const authHeader = req.headers.get("Authorization") || req.headers.get("apikey");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const token = authHeader.replace("Bearer ", "").trim();
    let isAuthorized = false;
    let userId: string | null = null;

    // Parse JWT claims
    try {
      const parts = token.split(".");
      if (parts.length === 3) {
        const payloadStr = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
        const claims = JSON.parse(payloadStr);
        if (claims.role === "service_role" || claims.role === "anon") {
          isAuthorized = true;
        } else if (claims.sub) {
          userId = claims.sub;
          isAuthorized = true;
        }
      }
    } catch {
      // Fallback
    }

    if (!isAuthorized) {
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (!authError && user) {
        userId = user.id;
        isAuthorized = true;
      }
    }

    if (!isAuthorized) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({}));
    const orderId = body.order_id || body.orderId || body.payment_reference;
    const isReadOnly = body.read_only === true;

    if (!orderId) {
      return new Response(
        JSON.stringify({ success: false, error: "order_id is required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Fetch payment record from database to verify ownership & existence
    const { data: paymentRecord } = await supabase
      .from("payments")
      .select("*")
      .or(`order_id.eq.${orderId},payment_reference.eq.${orderId}`)
      .maybeSingle();

    if (!isReadOnly && (!paymentRecord || (userId && paymentRecord.user_id !== userId))) {
      return new Response(
        JSON.stringify({ success: false, error: "Payment not found or access denied." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const targetUserId = paymentRecord?.user_id || userId;

    // If already completed/success in DB and not a read_only live check, return immediately
    if (!isReadOnly && paymentRecord && (paymentRecord.status === "completed" || paymentRecord.status === "success")) {
      const { data: isActive } = await supabase.rpc("has_active_subscription", { p_user_id: targetUserId });
      return new Response(
        JSON.stringify({
          success: true,
          payment_status: "SUCCESS",
          is_active: isActive ?? true,
          payment_reference: paymentRecord.payment_reference,
          payment_record: paymentRecord,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Query FimiPay order_status API if secret key is available
    let latestStatus = paymentRecord ? paymentRecord.status.toUpperCase() : "UNKNOWN";
    let fimipayRawData: any = null;
    let fimipayStatusCode: number | null = null;

    if (fimipaySecretKey) {
      try {
        const FIMIPAY_BASE_URL = "https://fimipay.com/api/v1";
        const fimipayRes = await fetch(`${FIMIPAY_BASE_URL}/payment/order_status`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${fimipaySecretKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ order_id: orderId }),
        });

        fimipayStatusCode = fimipayRes.status;
        if (fimipayRes.ok) {
          const fimipayData = await fimipayRes.json();
          fimipayRawData = fimipayData;
          const remoteStatus = (fimipayData.data?.payment_status || fimipayData.payment_status || "").toString().trim().toUpperCase();
          const transid = fimipayData.data?.transid || fimipayData.transid;
          const channel = fimipayData.data?.channel || fimipayData.channel;

          if (remoteStatus) {
            latestStatus = remoteStatus;

            // In read-only mode, do NOT modify DB
            if (!isReadOnly && paymentRecord) {
              // Update audit info
              await supabase
                .from("payments")
                .update({
                  transid: transid,
                  channel: channel,
                  raw_payload: fimipayData,
                  updated_at: new Date().toISOString(),
                })
                .eq("id", paymentRecord.id);

              const isSuccessStatus = remoteStatus === "SUCCESS" || remoteStatus === "COMPLETED" || remoteStatus === "PAID";
              const isFailedStatus = remoteStatus === "CANCELLED" || remoteStatus === "REJECTED" || remoteStatus === "USERCANCELLED" || remoteStatus === "FAILED";

              if (isSuccessStatus) {
                await supabase.rpc("process_subscription_payment", {
                  p_payment_reference: paymentRecord.order_id,
                });
              } else if (isFailedStatus) {
                await supabase
                  .from("payments")
                  .update({
                    status: "failed",
                    updated_at: new Date().toISOString(),
                  })
                  .eq("id", paymentRecord.id);
              }
            }
          }
        } else {
          fimipayRawData = await fimipayRes.text().catch(() => null);
        }
      } catch (fimiErr) {
        console.warn("[FimiPay] order_status query warning:", fimiErr);
      }
    }

    // Check if subscription is now active
    const { data: isActive } = targetUserId
      ? await supabase.rpc("has_active_subscription", { p_user_id: targetUserId })
      : { data: false };

    return new Response(
      JSON.stringify({
        success: true,
        payment_status: latestStatus,
        is_active: isActive ?? false,
        payment_reference: paymentRecord?.payment_reference || null,
        payment_record_before: paymentRecord || null,
        fimipay_http_status: fimipayStatusCode,
        fimipay_live_response: fimipayRawData,
        read_only: isReadOnly,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[FimiPay] Exception in fimipay-check-status:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Hitilafu ya seva wakati wa kuangalia hali ya malipo." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

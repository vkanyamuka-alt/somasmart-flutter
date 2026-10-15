// ==============================================================================
// SOMASMART SUPABASE EDGE FUNCTION: fimipay-webhook
// Secure FimiPay V4 Webhook Handler with HMAC-SHA256 Raw-Body Signature Verification
// ==============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-fimipay-signature",
};

// Helper: Verify HMAC-SHA256 signature against exact raw request body
export async function verifyFimipaySignature(
  rawBody: string,
  signatureHeader: string | null,
  webhookSecret: string
): Promise<boolean> {
  if (!signatureHeader || !webhookSecret || !rawBody) {
    return false;
  }

  try {
    const encoder = new TextEncoder();
    const cleanSecret = webhookSecret.trim();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(cleanSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(rawBody)
    );

    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("")
      .toLowerCase();

    // Strip common prefix formats: sha256=, hmac-sha256=, bearer, etc.
    const cleanHeader = signatureHeader
      .replace(/^sha256=/i, "")
      .replace(/^hmac-sha256=/i, "")
      .replace(/^hmac\s+/i, "")
      .replace(/^bearer\s+/i, "")
      .trim()
      .toLowerCase();

    // Constant-time comparison
    if (expectedSignature.length !== cleanHeader.length) {
      return false;
    }

    let result = 0;
    for (let i = 0; i < expectedSignature.length; i++) {
      result |= expectedSignature.charCodeAt(i) ^ cleanHeader.charCodeAt(i);
    }

    return result === 0;
  } catch (err) {
    console.error("[Webhook] Signature verification exception:", err);
    return false;
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const webhookSecret = Deno.env.get("FIMIPAY_WEBHOOK_SECRET");

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("[Webhook] Supabase service configuration missing.");
      return new Response(
        JSON.stringify({ error: "Server configuration missing." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!webhookSecret) {
      console.error("[Webhook] FIMIPAY_WEBHOOK_SECRET is not configured.");
      return new Response(
        JSON.stringify({ error: "Webhook secret is not configured." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Read EXACT RAW REQUEST BODY
    const rawBody = await req.text();
    const signature = req.headers.get("x-fimipay-signature") ||
                      req.headers.get("X-FIMIPAY-Signature") ||
                      req.headers.get("X-Fimipay-Signature") ||
                      req.headers.get("x-signature") ||
                      req.headers.get("X-Signature") ||
                      req.headers.get("fimipay-signature") ||
                      req.headers.get("Fimipay-Signature") ||
                      req.headers.get("signature") ||
                      req.headers.get("authorization");

    // 2. Verify HMAC-SHA256 Signature BEFORE parsing JSON
    const isValid = await verifyFimipaySignature(rawBody, signature, webhookSecret);
    if (!isValid) {
      console.warn("[Webhook] Invalid HMAC-SHA256 signature received.");
      return new Response(
        JSON.stringify({ error: "Invalid webhook signature." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Parse JSON only AFTER signature verification
    let payload: any;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return new Response(
        JSON.stringify({ error: "Malformed JSON payload." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const orderId = payload.order_id || payload.data?.order_id;
    const rawStatus = (payload.payment_status || payload.data?.payment_status || "").toString().trim().toUpperCase();
    const event = (payload.event || payload.data?.event || "").toString().trim().toLowerCase();
    const amount = Number(payload.amount ?? payload.data?.amount);
    const currency = (payload.currency || payload.data?.currency || "TZS").toString().trim().toUpperCase();
    const transid = payload.transid || payload.data?.transid || null;
    const channel = payload.channel || payload.data?.channel || "mobile";

    console.log(`[Webhook] Verified payload received for order_id: ${orderId}, status: ${rawStatus}, event: ${event}, amount: ${amount} ${currency}`);

    // 4. Validate core payment integrity
    if (!orderId) {
      return new Response(
        JSON.stringify({ error: "Missing required field: order_id." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify amount is expected 2500 TZS
    if (amount !== 2500 || currency !== "TZS") {
      console.warn(`[Webhook] Invalid payment amount (${amount}) or currency (${currency}) for order ${orderId}`);
      return new Response(
        JSON.stringify({ error: "Amount or currency mismatch." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Update audit details on payments table and execute Server-Authoritative Fulfillment
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Update payment audit columns if present
    await supabase
      .from("payments")
      .update({
        transid: transid,
        channel: channel,
        raw_payload: payload,
        updated_at: new Date().toISOString(),
      })
      .or(`order_id.eq.${orderId},payment_reference.eq.${orderId}`);

    const isSuccess = rawStatus === "SUCCESS" || rawStatus === "COMPLETED" || rawStatus === "PAID" || event === "payment.success";
    const isFailed = rawStatus === "CANCELLED" || rawStatus === "REJECTED" || rawStatus === "USERCANCELLED" || rawStatus === "FAILED" || event === "payment.failed" || event === "payment.cancelled";

    if (isSuccess) {
      const { data: rpcResult, error: rpcError } = await supabase.rpc(
        "process_subscription_payment",
        {
          p_payment_reference: orderId,
        }
      );

      if (rpcError) {
        console.error("[Webhook] Error executing process_subscription_payment RPC:", rpcError);
        return new Response(
          JSON.stringify({ error: "Failed to process payment in database." }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      console.log(`[Webhook] Successfully fulfilled payment for order ${orderId}:`, rpcResult);

      return new Response(
        JSON.stringify({ success: true, profile: rpcResult }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else if (isFailed) {
      // Mark payment status failed/cancelled
      await supabase
        .from("payments")
        .update({
          status: "failed",
          updated_at: new Date().toISOString(),
        })
        .or(`order_id.eq.${orderId},payment_reference.eq.${orderId}`);

      return new Response(
        JSON.stringify({ success: true, message: `Payment recorded with status ${rawStatus || event}` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      return new Response(
        JSON.stringify({ success: true, message: `Webhook received for non-terminal status ${rawStatus || event}` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("[Webhook] Unhandled exception in fimipay-webhook:", error);
    return new Response(
      JSON.stringify({ error: "Internal webhook processing error." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

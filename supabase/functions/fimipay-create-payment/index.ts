// ==============================================================================
// SOMASMART SUPABASE EDGE FUNCTION: fimipay-create-payment
// Initiates server-authoritative mobile payment with FimiPay v1 API.
// ==============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Tanzania mobile phone normalization: converts 07XX, 06XX, +255XX, 255XX -> 255XXXXXXXXX
export function normalizeTanzaniaPhone(rawPhone: string): { valid: boolean; phone: string; error?: string } {
  if (!rawPhone) {
    return { valid: false, phone: "", error: "Phone number is required." };
  }

  // Remove whitespace, dashes, plus signs, brackets
  let cleaned = rawPhone.replace(/[\s\-\+\(\)]/g, "");

  if (cleaned.startsWith("0")) {
    cleaned = "255" + cleaned.substring(1);
  } else if ((cleaned.startsWith("7") || cleaned.startsWith("6")) && cleaned.length === 9) {
    cleaned = "255" + cleaned;
  }

  // Tanzania mobile regex: 255 followed by 6 or 7 and 8 digits (12 digits total)
  const tzRegex = /^255[67]\d{8}$/;
  if (!tzRegex.test(cleaned)) {
    return {
      valid: false,
      phone: cleaned,
      error: "Invalid Tanzania mobile number. Must be a valid 06... or 07... number.",
    };
  }

  return { valid: true, phone: cleaned };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const fimipaySecretKey = Deno.env.get("FIMIPAY_SECRET_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration missing." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!fimipaySecretKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Payment gateway configuration missing." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Authenticate user from JWT token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid or expired session. Please log in again." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse and validate request
    const body = await req.json().catch(() => ({}));
    const rawPhone = (body.phone || body.phoneNumber || "").toString().trim();
    const operator = (body.operator || body.payment_method || "mpesa").toString().trim();

    const phoneValidation = normalizeTanzaniaPhone(rawPhone);
    if (!phoneValidation.valid) {
      return new Response(
        JSON.stringify({ success: false, error: phoneValidation.error }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const normalizedPhone = phoneValidation.phone;

    // 3. Fetch user profile
    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name, email")
      .eq("id", user.id)
      .maybeSingle();

    const buyerName = profile?.full_name || user.user_metadata?.full_name || "SomaSmart Student";
    const buyerEmail = profile?.email || user.email || "student@somasmart.ac.tz";

    // 4. Call FimiPay create_order API
    const FIMIPAY_BASE_URL = "https://fimipay.com/api/v1";
    const fimipayPayload = {
      buyer_email: buyerEmail,
      buyer_name: buyerName,
      buyer_phone: normalizedPhone,
      amount: 2500,
      currency: "TZS",
      payment_method: "mobile",
    };

    console.log(`[FimiPay] Initiating payment for user: ${user.id}, phone: 255***${normalizedPhone.slice(-4)}, amount: 2500 TZS`);

    const fimipayRes = await fetch(`${FIMIPAY_BASE_URL}/payment/create_order`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${fimipaySecretKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fimipayPayload),
    });

    const fimipayData = await fimipayRes.json().catch(() => null);

    if (!fimipayRes.ok || !fimipayData) {
      console.error(`[FimiPay] create_order error status ${fimipayRes.status}:`, fimipayData);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Imeshindikana kuanzisha malipo kupitia mtandao wa simu. Tafadhali jaribu tena.",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Extract FimiPay order_id
    const orderId = fimipayData.order_id || fimipayData.data?.order_id || `fp_${Date.now()}`;
    const initialStatus = fimipayData.payment_status || fimipayData.data?.payment_status || "PENDING";
    const paymentRef = `FP-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    // 5. Store pending payment in Supabase database
    const { error: dbError } = await supabase.from("payments").insert({
      user_id: user.id,
      amount: 2500.00,
      currency: "TZS",
      payment_method: operator,
      provider: "fimipay",
      payment_reference: paymentRef,
      order_id: orderId,
      phone: normalizedPhone,
      status: "pending",
      type: "subscription",
      raw_payload: fimipayData,
    });

    if (dbError) {
      console.error("[FimiPay] Database payment insert error:", dbError);
    }

    return new Response(
      JSON.stringify({
        success: true,
        order_id: orderId,
        payment_reference: paymentRef,
        status: initialStatus,
        message: "Payment request sent. Please approve the prompt on your phone.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[FimiPay] Unhandled exception in fimipay-create-payment:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Hitilafu ya seva wakati wa kuanzisha malipo." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

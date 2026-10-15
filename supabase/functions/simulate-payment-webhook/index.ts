// ==============================================================================
// SOMASMART SUPABASE EDGE FUNCTION: simulate-payment-webhook
// Fallback & Testing simulated payment webhook handler (Preserved)
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

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration missing." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({}));
    const paymentRef = body.payment_reference || body.order_id || body.paymentReference;

    if (!paymentRef) {
      return new Response(
        JSON.stringify({ success: false, error: "payment_reference is required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Call server-authoritative process_subscription_payment RPC
    const { data: rpcResult, error: rpcError } = await supabase.rpc(
      "process_subscription_payment",
      {
        p_order_id: paymentRef,
        p_transid: `SIM-${Math.floor(100000 + Math.random() * 900000)}`,
        p_status: "SUCCESS",
        p_channel: "Simulated",
        p_raw_payload: { simulated: true, timestamp: new Date().toISOString() },
      }
    );

    if (rpcError) {
      console.error("[Simulate] Error executing process_subscription_payment RPC:", rpcError);
      return new Response(
        JSON.stringify({ success: false, error: "Failed to fulfill simulated payment." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, result: rpcResult }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[Simulate] Exception in simulate-payment-webhook:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Hitilafu wakati wa kuthibitisha malipo ya majaribio." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

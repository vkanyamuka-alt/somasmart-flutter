-- ==============================================================================
-- SOMASMART SUPABASE MIGRATION: 1 CALENDAR MONTH SUBSCRIPTION FULFILLMENT
-- File: supabase/migrations/20261003_calendar_month_subscription.sql
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.process_subscription_payment(
  p_payment_reference text
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_payment_id uuid;
  v_payment_user_id uuid;
  v_payment_status public.payment_status_type;
  v_updated_profile public.profiles;
BEGIN
  -- Locate payment record by payment_reference OR order_id and lock row FOR UPDATE
  SELECT id, user_id, status
  INTO v_payment_id, v_payment_user_id, v_payment_status
  FROM public.payments
  WHERE payment_reference = p_payment_reference OR order_id = p_payment_reference
  FOR UPDATE;

  -- Exception check: Payment not found
  IF v_payment_id IS NULL THEN
    RAISE EXCEPTION 'Payment reference not found.' USING ERRCODE = 'P0002';
  END IF;

  -- Idempotency check: If already processed, return existing profile safely without re-extending
  IF v_payment_status = 'success'::public.payment_status_type THEN
    SELECT * INTO v_updated_profile FROM public.profiles WHERE id = v_payment_user_id;
    RETURN v_updated_profile;
  END IF;

  -- Update payment status to success
  UPDATE public.payments
  SET status = 'success'::public.payment_status_type,
      updated_at = timezone('utc'::text, now())
  WHERE id = v_payment_id;

  -- Atomically update ONLY the payment owner's profile entitlement (1 Calendar Month extension)
  UPDATE public.profiles
  SET 
    subscription_status = 'paid'::public.sub_status,
    subscription_started_at = COALESCE(subscription_started_at, timezone('utc'::text, now())),
    subscription_expires_at = GREATEST(COALESCE(subscription_expires_at, timezone('utc'::text, now())), timezone('utc'::text, now())) + INTERVAL '1 month'
  WHERE id = v_payment_user_id
  RETURNING * INTO v_updated_profile;

  IF v_updated_profile.id IS NULL THEN
    RAISE EXCEPTION 'User profile not found.' USING ERRCODE = 'P0002';
  END IF;

  -- Audit log security event
  INSERT INTO public.security_logs (user_id, event_type, details)
  VALUES (
    v_payment_user_id,
    'payment_processed_webhook',
    'Subscription payment verified by webhook/service-role for reference/order: ' || p_payment_reference
  );

  RETURN v_updated_profile;
END;
$$;

-- CRITICAL PRODUCTION SECURITY:
-- Revoke execution from standard users (PUBLIC, anon, authenticated).
-- Grant execution ONLY to service_role (trusted backend / webhook engine).
REVOKE ALL ON FUNCTION public.process_subscription_payment(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_subscription_payment(text) FROM anon;
REVOKE ALL ON FUNCTION public.process_subscription_payment(text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.process_subscription_payment(text) TO service_role;

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- SOMASMART SUPABASE MIGRATION: ONE-TIME DATA CORRECTION FOR USER 3015645f-b625-4868-95ae-b25d6b1962fc
-- File: supabase/migrations/20261003_correct_user_subscription_expiry.sql
-- Description: Corrects historical test/development entitlement contamination on user profile
--              so that the single real successful FimiPay payment (fp_qflf23nmchhv, 2500 TZS)
--              grants exactly one calendar month (2026-10-03 -> 2026-11-03).
-- ==============================================================================

DO $$
DECLARE
  v_user_id uuid := '3015645f-b625-4868-95ae-b25d6b1962fc'::uuid;
  v_payment_count int;
  v_successful_payment record;
BEGIN
  -- 1. Pre-condition safety check: Verify user has exactly one successful payment
  SELECT COUNT(*) INTO v_payment_count
  FROM public.payments
  WHERE user_id = v_user_id AND status = 'success'::public.payment_status_type;

  IF v_payment_count <> 1 THEN
    RAISE EXCEPTION 'Pre-condition failed: Expected exactly 1 successful payment for user %, found %', v_user_id, v_payment_count;
  END IF;

  -- 2. Fetch the legitimate successful payment
  SELECT id, created_at, order_id, amount
  INTO v_successful_payment
  FROM public.payments
  WHERE user_id = v_user_id 
    AND status = 'success'::public.payment_status_type
    AND order_id = 'fp_qflf23nmchhv';

  IF v_successful_payment.id IS NULL THEN
    RAISE EXCEPTION 'Pre-condition failed: Successful payment fp_qflf23nmchhv not found for user %', v_user_id;
  END IF;

  -- 3. Update ONLY this user's profile entitlement to exactly 1 calendar month from the payment
  UPDATE public.profiles
  SET
    subscription_status = 'paid'::public.sub_status,
    subscription_started_at = v_successful_payment.created_at,
    subscription_expires_at = (v_successful_payment.created_at + INTERVAL '1 month')
  WHERE id = v_user_id;

  -- 4. Log the audit event
  INSERT INTO public.security_logs (user_id, event_type, details)
  VALUES (
    v_user_id,
    'subscription_data_correction',
    'Corrected historical test entitlement contamination to 1 calendar month from successful payment fp_qflf23nmchhv.'
  );

END;
$$;

NOTIFY pgrst, 'reload schema';

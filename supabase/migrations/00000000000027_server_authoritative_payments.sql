-- Migration: 00000000000027_server_authoritative_payments.sql
-- Description: Server-authoritative payment creation RPC and webhook-only fulfillment RPC with hardened payments RLS.

-- ============================================================================
-- 1. HARDEN ROW LEVEL SECURITY ON public.payments
-- ============================================================================

-- Drop legacy user policies on public.payments
DROP POLICY IF EXISTS "Users can create payments" ON public.payments;
DROP POLICY IF EXISTS "Users can view their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can create pending payments" ON public.payments;

-- Re-create restricted SELECT policy: Authenticated users can view only their own payments
CREATE POLICY "Users can view their own payments" ON public.payments
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Re-create restricted INSERT policy: Authenticated users can create pending payments only for themselves with enforced fixed amount (2500 TZS)
CREATE POLICY "Users can create pending payments" ON public.payments
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid() 
    AND status = 'pending'::public.payment_status_type
    AND amount = 2500.00
    AND type = 'subscription'::public.payment_txn_type
  );

-- Note: No UPDATE or DELETE policies are granted to standard authenticated users.
-- Standard users cannot update payment status or delete payments directly via PostgREST.
-- Admin full access ("Admins have full access") remains intact.


-- ============================================================================
-- 2. CREATE SERVER-AUTHORITATIVE PAYMENT CREATION RPC
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_subscription_payment(
  p_payment_method public.payment_method_type
)
RETURNS public.payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_user_id uuid;
  v_reference text;
  v_payment public.payments;
BEGIN
  -- Require authenticated caller
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated caller.' USING ERRCODE = '42501';
  END IF;

  -- Generate server-authoritative payment reference: TXN- + random 6-digit integer
  v_reference := 'TXN-' || floor(100000 + random() * 900000)::text;

  -- Insert pending payment with server-enforced amount (2500 TZS) and type ('subscription')
  INSERT INTO public.payments (
    user_id,
    amount,
    currency,
    payment_method,
    payment_reference,
    status,
    type
  ) VALUES (
    v_user_id,
    2500.00,
    'TZS',
    p_payment_method,
    v_reference,
    'pending'::public.payment_status_type,
    'subscription'::public.payment_txn_type
  )
  RETURNING * INTO v_payment;

  RETURN v_payment;
END;
$$;

-- Grant execution for payment creation to authenticated users
REVOKE ALL ON FUNCTION public.create_subscription_payment(public.payment_method_type) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_subscription_payment(public.payment_method_type) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_subscription_payment(public.payment_method_type) TO authenticated;


-- ============================================================================
-- 3. CREATE WEBHOOK / SERVICE-ROLE ONLY PAYMENT FULFILLMENT RPC
-- ============================================================================

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
  -- Locate payment record by reference and lock row FOR UPDATE
  SELECT id, user_id, status
  INTO v_payment_id, v_payment_user_id, v_payment_status
  FROM public.payments
  WHERE payment_reference = p_payment_reference
  FOR UPDATE;

  -- Exception check: Payment not found
  IF v_payment_id IS NULL THEN
    RAISE EXCEPTION 'Payment reference not found.' USING ERRCODE = 'P0002';
  END IF;

  -- Exception check: Payment already processed
  IF v_payment_status <> 'pending'::public.payment_status_type THEN
    RAISE EXCEPTION 'Payment has already been processed.' USING ERRCODE = '22000';
  END IF;

  -- Update payment status to success
  UPDATE public.payments
  SET status = 'success'::public.payment_status_type
  WHERE id = v_payment_id;

  -- Atomically update ONLY the payment owner's profile entitlement
  UPDATE public.profiles
  SET 
    subscription_status = 'paid'::public.sub_status,
    subscription_started_at = COALESCE(subscription_started_at, timezone('utc'::text, now())),
    subscription_expires_at = GREATEST(COALESCE(subscription_expires_at, timezone('utc'::text, now())), timezone('utc'::text, now())) + INTERVAL '30 days'
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
    'Subscription payment verified by webhook/service-role for reference: ' || p_payment_reference
  );

  -- Return updated profile record
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

-- Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- SOMASMART SUPABASE MIGRATION: FIMIPAY SUBSCRIPTION & PAYMENT INFRASTRUCTURE
-- File: supabase/migrations/20261002_fimipay_subscription_payment.sql
-- Revision: 2.0 (Production Verified, Backward-Compatible, Strict Security Definer)
-- ==============================================================================

-- 1. EXTEND PAYMENT_METHOD_TYPE ENUM FOR NEW OPERATORS
ALTER TYPE public.payment_method_type ADD VALUE IF NOT EXISTS 'halopesa';
ALTER TYPE public.payment_method_type ADD VALUE IF NOT EXISTS 'mobile';

-- 2. ENSURE OPTIONAL FIMIPAY AUDIT COLUMNS EXIST ON PAYMENTS TABLE
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'simulated';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS order_id TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS transid TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS channel TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS raw_payload JSONB;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Ensure performant lookup indexes exist
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON public.payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_reference ON public.payments(payment_reference);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);

-- Ensure RLS is active
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;


-- 3. SERVER-AUTHORITATIVE PAYMENT CREATION RPC (MATCHING MIGRATION 27 ENUM SIGNATURE)
CREATE OR REPLACE FUNCTION public.create_subscription_payment(
  p_payment_method public.payment_method_type DEFAULT 'mpesa'::public.payment_method_type
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
    provider,
    status,
    type,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    2500.00,
    'TZS',
    p_payment_method,
    v_reference,
    'simulated',
    'pending'::public.payment_status_type,
    'subscription'::public.payment_txn_type,
    timezone('utc'::text, now()),
    timezone('utc'::text, now())
  )
  RETURNING * INTO v_payment;

  RETURN v_payment;
END;
$$;

-- Secure function permissions: Callable by authenticated users to initiate pending payments
REVOKE ALL ON FUNCTION public.create_subscription_payment(public.payment_method_type) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_subscription_payment(public.payment_method_type) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_subscription_payment(public.payment_method_type) TO authenticated;


-- 4. SERVER-AUTHORITATIVE PAYMENT FULFILLMENT RPC (SERVICE-ROLE ONLY, IDEMPOTENT, ORDER_ID COMPATIBLE)
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

  -- Atomically update ONLY the payment owner's profile entitlement (30-day extension)
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


-- 5. SUBSCRIPTION ENTITLEMENT HELPER RPC (MATCHING MIGRATION 28 EXACT SIGNATURE & 6-DAY TRIAL)
CREATE OR REPLACE FUNCTION public.has_active_subscription(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_caller_id uuid;
  v_target_id uuid;
  v_has_access boolean := false;
BEGIN
  v_caller_id := auth.uid();
  IF v_caller_id IS NULL THEN
    RETURN false;
  END IF;

  v_target_id := COALESCE(p_user_id, v_caller_id);

  -- Prevent cross-user entitlement bypass: Non-admins may only evaluate their own identity
  IF v_target_id <> v_caller_id AND public.get_my_role() <> 'admin'::public.user_role THEN
    RETURN false;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = v_target_id
      AND (
        role = 'admin'::public.user_role
        OR free_access = true
        OR (created_at IS NOT NULL AND timezone('utc'::text, now()) - created_at < INTERVAL '6 days')
        OR (
          subscription_status = 'paid'::public.sub_status
          AND subscription_expires_at IS NOT NULL
          AND subscription_expires_at > timezone('utc'::text, now())
        )
      )
  ) INTO v_has_access;

  RETURN COALESCE(v_has_access, false);
END;
$$;

-- Secure function permissions
REVOKE ALL ON FUNCTION public.has_active_subscription(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_active_subscription(uuid) TO authenticated, service_role;

-- Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';

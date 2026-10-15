-- ==============================================================================
-- SOMASMART SUPABASE PRODUCTION SECURITY HARDENING & RLS MIGRATION
-- File: supabase/migrations/20260918_security_hardening.sql
-- Revision: 2.0 (Production Verified & Aligned to Flutter Client Architecture)
-- ==============================================================================

-- 1. ENSURE TABLES EXIST & ENABLE ROW LEVEL SECURITY ACROSS ALL 17 PUBLIC TABLES
CREATE TABLE IF NOT EXISTS public.syllabus_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  subject_name TEXT NOT NULL,
  education_level TEXT NOT NULL DEFAULT 'o-level',
  coverage TEXT,
  academic_year TEXT,
  file_url TEXT,
  thumbnail_url TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  is_published BOOLEAN NOT NULL DEFAULT true,
  download_allowed BOOLEAN NOT NULL DEFAULT false,
  official_source_url TEXT,
  source_organization TEXT,
  version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.otp_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ,
  is_used BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.account_recovery_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  lost_phone TEXT NOT NULL,
  alternate_contact TEXT,
  issue_description TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shop_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shop_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.learning_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.memorize_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.syllabus_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.discussion_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.account_recovery_requests ENABLE ROW LEVEL SECURITY;


-- ==============================================================================
-- 2. HARDENED HELPER FUNCTION: CHECK IF AUTHENTICATED CALLER IS ADMIN
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path = public;

REVOKE ALL ON FUNCTION public.is_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;

-- ==============================================================================
-- 3. PROFILES TABLE POLICIES & PRIVILEGE ESCALATION SHIELD TRIGGER
-- ==============================================================================
DROP POLICY IF EXISTS "Users can view own profile or admins view all" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile safe columns" ON public.profiles;

-- Read policy: Authenticated users can read profiles (required for forum author display and self profile)
CREATE POLICY "Allow authenticated read profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- Insert policy: Users can only create their own profile row
CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Update policy: Users can only update their own row (or admin all)
CREATE POLICY "Users can update own profile safe columns"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

-- TRIGGER FUNCTION: Detects service_role JWT / Postgres Superuser / Admin and blocks student privilege tampering
CREATE OR REPLACE FUNCTION public.protect_profile_privileged_fields()
RETURNS TRIGGER AS $$
DECLARE
  v_jwt_role TEXT;
BEGIN
  -- 1. Extract PostgREST JWT role if present
  BEGIN
    v_jwt_role := coalesce(
      auth.jwt() ->> 'role',
      current_setting('request.jwt.claim.role', true)
    );
  EXCEPTION WHEN OTHERS THEN
    v_jwt_role := NULL;
  END;

  -- 2. Bypass restrictions for backend service_role, edge functions, or database administrator
  IF v_jwt_role = 'service_role' OR current_user = 'service_role' OR current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- 3. Bypass restrictions for verified application administrators
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  -- 4. Enforce strict restrictions on normal students attempting privilege escalation
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Unauthorized: Only administrators can modify user roles.';
  END IF;
  IF NEW.subscription_status IS DISTINCT FROM OLD.subscription_status THEN
    RAISE EXCEPTION 'Unauthorized: Subscription status must be updated through the payment system.';
  END IF;
  IF NEW.free_access IS DISTINCT FROM OLD.free_access THEN
    RAISE EXCEPTION 'Unauthorized: Free access overrides can only be granted by administrators.';
  END IF;
  IF NEW.subscription_expires_at IS DISTINCT FROM OLD.subscription_expires_at THEN
    RAISE EXCEPTION 'Unauthorized: Subscription expiration can only be modified via payment verification.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_profile_privileged_fields ON public.profiles;
CREATE TRIGGER trg_protect_profile_privileged_fields
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_profile_privileged_fields();

-- ==============================================================================
-- 4. STUDENT PROFILES POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Users can view own student profile" ON public.student_profiles;
DROP POLICY IF EXISTS "Users can manage own student profile" ON public.student_profiles;

CREATE POLICY "Users can view own student profile"
ON public.student_profiles FOR SELECT
TO authenticated
USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can manage own student profile"
ON public.student_profiles FOR ALL
TO authenticated
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

-- ==============================================================================
-- 5. PAYMENTS POLICIES (PREVENT FRAUDULENT STATUS UPDATES)
-- ==============================================================================
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can initiate pending payments" ON public.payments;
DROP POLICY IF EXISTS "No client-side payment update" ON public.payments;

CREATE POLICY "Users can view own payments"
ON public.payments FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can initiate pending payments"
ON public.payments FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id AND status = 'pending');

CREATE POLICY "No client-side payment update"
ON public.payments FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ==============================================================================
-- 6. SHOP PURCHASES & CATALOG POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Users can view own shop purchases" ON public.shop_purchases;
DROP POLICY IF EXISTS "Users can insert own shop purchases" ON public.shop_purchases;
DROP POLICY IF EXISTS "Public shop items catalog view" ON public.shop_items;

CREATE POLICY "Users can view own shop purchases"
ON public.shop_purchases FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can insert own shop purchases"
ON public.shop_purchases FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Public shop items catalog view"
ON public.shop_items FOR SELECT
TO authenticated, anon
USING (is_archived = false OR public.is_admin());

-- ==============================================================================
-- 7. QUIZ ATTEMPTS & ACADEMIC CURRICULUM CONTENT POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Users view own quiz attempts" ON public.quiz_attempts;
DROP POLICY IF EXISTS "Users insert own quiz attempts" ON public.quiz_attempts;
DROP POLICY IF EXISTS "Public view quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Public view quiz questions" ON public.quiz_questions;
DROP POLICY IF EXISTS "Public view academic resources" ON public.subjects;
DROP POLICY IF EXISTS "Public view notes" ON public.notes;
DROP POLICY IF EXISTS "Public view learning materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Public view memorize items" ON public.memorize_items;
DROP POLICY IF EXISTS "Public view syllabus" ON public.syllabus_documents;

CREATE POLICY "Users view own quiz attempts"
ON public.quiz_attempts FOR SELECT
TO authenticated
USING (auth.uid() = student_id OR public.is_admin());

CREATE POLICY "Users insert own quiz attempts"
ON public.quiz_attempts FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Public view quizzes" ON public.quizzes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public view quiz questions" ON public.quiz_questions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public view academic resources" ON public.subjects FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public view notes" ON public.notes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public view learning materials" ON public.learning_materials FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public view memorize items" ON public.memorize_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public view syllabus" ON public.syllabus_documents FOR SELECT TO authenticated USING (true);

-- ==============================================================================
-- 8. FORUM DISCUSSIONS & REPLIES POLICIES
-- ==============================================================================
DROP POLICY IF EXISTS "Authenticated users view discussions" ON public.discussions;
DROP POLICY IF EXISTS "Authenticated users create discussions" ON public.discussions;
DROP POLICY IF EXISTS "Authors or admins update discussions" ON public.discussions;
DROP POLICY IF EXISTS "Authors or admins delete discussions" ON public.discussions;

CREATE POLICY "Authenticated users view discussions"
ON public.discussions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users create discussions"
ON public.discussions FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authors or admins update discussions"
ON public.discussions FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Authors or admins delete discussions"
ON public.discussions FOR DELETE TO authenticated
USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Authenticated users view replies" ON public.discussion_replies;
DROP POLICY IF EXISTS "Authenticated users create replies" ON public.discussion_replies;
DROP POLICY IF EXISTS "Authors or admins update replies" ON public.discussion_replies;
DROP POLICY IF EXISTS "Authors or admins delete replies" ON public.discussion_replies;

CREATE POLICY "Authenticated users view replies"
ON public.discussion_replies FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users create replies"
ON public.discussion_replies FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authors or admins update replies"
ON public.discussion_replies FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Authors or admins delete replies"
ON public.discussion_replies FOR DELETE TO authenticated
USING (auth.uid() = user_id OR public.is_admin());

-- ==============================================================================
-- 9. SECURE OTP VERIFICATION & RECOVERY ARCHITECTURE
-- ==============================================================================
-- Table RLS: Client SELECT is strictly forbidden to prevent OTP credential leaks
DROP POLICY IF EXISTS "Insert OTP records" ON public.otp_verifications;
CREATE POLICY "Insert OTP records"
ON public.otp_verifications FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Rate-limiting trigger for OTP generation: max 3 requests per phone per 10-minute window
CREATE OR REPLACE FUNCTION public.check_otp_insert_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_recent_count INT;
  v_jwt_role TEXT;
BEGIN
  -- Allow service_role / postgres to bypass rate limits
  BEGIN
    v_jwt_role := coalesce(
      auth.jwt() ->> 'role',
      current_setting('request.jwt.claim.role', true)
    );
  EXCEPTION WHEN OTHERS THEN
    v_jwt_role := NULL;
  END;

  IF v_jwt_role = 'service_role' OR current_user = 'service_role' OR current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- Count OTP requests for this phone number in the last 10 minutes
  SELECT COUNT(*) INTO v_recent_count
  FROM public.otp_verifications
  WHERE phone = NEW.phone
    AND created_at > (now() - INTERVAL '10 minutes');

  IF v_recent_count >= 3 THEN
    RAISE EXCEPTION 'Too many OTP requests for this phone number. Please wait 10 minutes before requesting a new code.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_otp_insert_rate_limit ON public.otp_verifications;
CREATE TRIGGER trg_check_otp_insert_rate_limit
BEFORE INSERT ON public.otp_verifications
FOR EACH ROW
EXECUTE FUNCTION public.check_otp_insert_rate_limit();

-- Atomic Server-side OTP Verification RPC (Zero client SELECT exposure)
CREATE OR REPLACE FUNCTION public.verify_phone_otp(
  p_phone TEXT,
  p_otp_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_otp_id UUID;
BEGIN
  -- Look for active, unexpired, unused matching OTP
  SELECT id INTO v_otp_id
  FROM public.otp_verifications
  WHERE phone = p_phone
    AND otp_code = p_otp_code
    AND is_used = false
    AND (expires_at IS NULL OR expires_at > now())
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_otp_id IS NOT NULL THEN
    -- Mark OTP as used (Prevent Replay Attacks)
    UPDATE public.otp_verifications
    SET is_used = true
    WHERE id = v_otp_id;

    -- Update profile verified status
    IF auth.uid() IS NOT NULL THEN
      UPDATE public.profiles
      SET is_verified = true
      WHERE id = auth.uid();
    ELSE
      UPDATE public.profiles
      SET is_verified = true
      WHERE phone = p_phone;
    END IF;

    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.verify_phone_otp(TEXT, TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.verify_phone_otp(TEXT, TEXT) TO anon, authenticated, service_role;

-- Account recovery submissions
DROP POLICY IF EXISTS "Insert account recovery request" ON public.account_recovery_requests;
DROP POLICY IF EXISTS "Admins view recovery requests" ON public.account_recovery_requests;

CREATE POLICY "Insert account recovery request"
ON public.account_recovery_requests FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Rate-limiting trigger for Account Recovery submissions: max 3 requests per phone per 1 hour window
CREATE OR REPLACE FUNCTION public.check_recovery_insert_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_recent_count INT;
  v_jwt_role TEXT;
BEGIN
  -- Allow service_role / postgres to bypass rate limits
  BEGIN
    v_jwt_role := coalesce(
      auth.jwt() ->> 'role',
      current_setting('request.jwt.claim.role', true)
    );
  EXCEPTION WHEN OTHERS THEN
    v_jwt_role := NULL;
  END;

  IF v_jwt_role = 'service_role' OR current_user = 'service_role' OR current_user = 'postgres' THEN
    RETURN NEW;
  END IF;

  -- Count recovery requests for this lost_phone in the last 1 hour
  SELECT COUNT(*) INTO v_recent_count
  FROM public.account_recovery_requests
  WHERE lost_phone = NEW.lost_phone
    AND created_at > (now() - INTERVAL '1 hour');

  IF v_recent_count >= 3 THEN
    RAISE EXCEPTION 'Too many recovery requests for this phone number. Please wait 1 hour before submitting another request.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_recovery_insert_rate_limit ON public.account_recovery_requests;
CREATE TRIGGER trg_check_recovery_insert_rate_limit
BEFORE INSERT ON public.account_recovery_requests
FOR EACH ROW
EXECUTE FUNCTION public.check_recovery_insert_rate_limit();

CREATE POLICY "Admins view recovery requests"
ON public.account_recovery_requests FOR SELECT
TO authenticated
USING (public.is_admin());


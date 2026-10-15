-- Migration 28: Enforce Database-Level Content Entitlement & Subscription Paywall Security

-- 1. Create SECURITY DEFINER helper function to safely check user subscription entitlement
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

-- 2. Update SELECT RLS policies on proprietary premium content tables

-- public.notes
DROP POLICY IF EXISTS "Allow public read approved notes" ON public.notes;
DROP POLICY IF EXISTS "Subscribed users can read approved notes" ON public.notes;
CREATE POLICY "Subscribed users can read approved notes"
  ON public.notes
  FOR SELECT
  TO authenticated
  USING (
    (status = 'approved'::public.note_status OR public.get_my_role() = 'admin'::public.user_role)
    AND public.has_active_subscription(auth.uid())
  );

-- public.quizzes
DROP POLICY IF EXISTS "Allow authenticated read quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Subscribed users can read quizzes" ON public.quizzes;
CREATE POLICY "Subscribed users can read quizzes"
  ON public.quizzes
  FOR SELECT
  TO authenticated
  USING (
    public.has_active_subscription(auth.uid())
  );

-- public.quiz_questions
DROP POLICY IF EXISTS "Quiz questions are readable by everyone" ON public.quiz_questions;
DROP POLICY IF EXISTS "Allow authenticated read quiz_questions" ON public.quiz_questions;
DROP POLICY IF EXISTS "Subscribed users can read quiz questions" ON public.quiz_questions;
CREATE POLICY "Subscribed users can read quiz questions"
  ON public.quiz_questions
  FOR SELECT
  TO authenticated
  USING (
    public.has_active_subscription(auth.uid())
  );

-- public.practicals
DROP POLICY IF EXISTS "Allow public read approved practicals" ON public.practicals;
DROP POLICY IF EXISTS "Subscribed users can read approved practicals" ON public.practicals;
CREATE POLICY "Subscribed users can read approved practicals"
  ON public.practicals
  FOR SELECT
  TO authenticated
  USING (
    (status = 'approved'::public.note_status OR public.get_my_role() = 'admin'::public.user_role)
    AND public.has_active_subscription(auth.uid())
  );

-- public.learning_materials
DROP POLICY IF EXISTS "Allow public read published learning_materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Subscribed users can read published learning_materials" ON public.learning_materials;
CREATE POLICY "Subscribed users can read published learning_materials"
  ON public.learning_materials
  FOR SELECT
  TO authenticated
  USING (
    (status = 'published'::public.material_status OR public.get_my_role() = 'admin'::public.user_role)
    AND public.has_active_subscription(auth.uid())
  );

-- public.memorize_items
DROP POLICY IF EXISTS "Published memorize items are readable by everyone" ON public.memorize_items;
DROP POLICY IF EXISTS "Subscribed users can read published memorize_items" ON public.memorize_items;
CREATE POLICY "Subscribed users can read published memorize_items"
  ON public.memorize_items
  FOR SELECT
  TO authenticated
  USING (
    (is_published = true OR public.get_my_role() = 'admin'::public.user_role)
    AND public.has_active_subscription(auth.uid())
  );

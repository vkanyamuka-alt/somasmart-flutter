-- Phase 2 security foundation: Harden profile and discussion table RLS policies.
-- Migration 25: Remove direct client table write access to profile tables and clean up legacy roles.

-- 1. Update public.get_my_role() to align with admin/student architecture (legacy teacher references removed)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role AS $$
DECLARE
  v_role public.user_role;
BEGIN
  SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
  RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- 2. Lockdown public.profiles table write policies:
-- Drop legacy direct INSERT and UPDATE policies for standard authenticated clients.
-- Profile creation and modifications are restricted to SECURITY DEFINER RPCs (handle_new_user, ensure_my_student_profile, update_my_profile, set_user_free_access) and Admins.
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- Ensure SELECT policy remains non-recursive and secure
DROP POLICY IF EXISTS "Students read own profile, teachers/admins read all" ON public.profiles;
DROP POLICY IF EXISTS "Users read own profile, admins read all" ON public.profiles;
CREATE POLICY "Users read own profile, admins read all" ON public.profiles
  FOR SELECT TO authenticated USING (
    auth.uid() = id OR public.get_my_role() = 'admin'::public.user_role
  );

-- Ensure Admins maintain full table management on public.profiles
DROP POLICY IF EXISTS "Admins have full access" ON public.profiles;
CREATE POLICY "Admins have full access" ON public.profiles
  FOR ALL TO authenticated
  USING (public.get_my_role() = 'admin'::public.user_role)
  WITH CHECK (public.get_my_role() = 'admin'::public.user_role);

-- 3. Lockdown public.student_profiles table write policies:
DROP POLICY IF EXISTS "Students can insert their own subprofile" ON public.student_profiles;

DROP POLICY IF EXISTS "Students read own subprofile, teachers/admins read all" ON public.student_profiles;
DROP POLICY IF EXISTS "Students read own subprofile, admins read all" ON public.student_profiles;
CREATE POLICY "Students read own subprofile, admins read all" ON public.student_profiles
  FOR SELECT TO authenticated USING (
    auth.uid() = id OR public.get_my_role() = 'admin'::public.user_role
  );

DROP POLICY IF EXISTS "Admins have full access" ON public.student_profiles;
CREATE POLICY "Admins have full access" ON public.student_profiles
  FOR ALL TO authenticated
  USING (public.get_my_role() = 'admin'::public.user_role)
  WITH CHECK (public.get_my_role() = 'admin'::public.user_role);

-- 4. Secure Discussions and Discussion Replies RLS policies
DROP POLICY IF EXISTS "Discussions are readable by everyone" ON public.discussions;
DROP POLICY IF EXISTS "Authenticated users can create discussions" ON public.discussions;
DROP POLICY IF EXISTS "Users can delete their own discussions" ON public.discussions;
DROP POLICY IF EXISTS "Admins have full access" ON public.discussions;

CREATE POLICY "Discussions are readable by authenticated users" ON public.discussions
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can create discussions" ON public.discussions
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own discussions" ON public.discussions
  FOR DELETE TO authenticated USING (
    auth.uid() = user_id OR public.get_my_role() = 'admin'::public.user_role
  );

CREATE POLICY "Admins have full access" ON public.discussions
  FOR ALL TO authenticated
  USING (public.get_my_role() = 'admin'::public.user_role)
  WITH CHECK (public.get_my_role() = 'admin'::public.user_role);

-- Discussion Replies policies
DROP POLICY IF EXISTS "Replies are readable by everyone" ON public.discussion_replies;
DROP POLICY IF EXISTS "Authenticated users can create replies" ON public.discussion_replies;
DROP POLICY IF EXISTS "Users can delete their own replies" ON public.discussion_replies;
DROP POLICY IF EXISTS "Admins have full access" ON public.discussion_replies;

CREATE POLICY "Replies are readable by authenticated users" ON public.discussion_replies
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can create replies" ON public.discussion_replies
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own replies" ON public.discussion_replies
  FOR DELETE TO authenticated USING (
    auth.uid() = user_id OR public.get_my_role() = 'admin'::public.user_role
  );

CREATE POLICY "Admins have full access" ON public.discussion_replies
  FOR ALL TO authenticated
  USING (public.get_my_role() = 'admin'::public.user_role)
  WITH CHECK (public.get_my_role() = 'admin'::public.user_role);

-- 5. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';

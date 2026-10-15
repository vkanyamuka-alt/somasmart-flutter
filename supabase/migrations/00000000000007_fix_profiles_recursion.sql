-- Fix infinite recursion in RLS policies for profiles and student_profiles

-- 1. Create a helper function to retrieve the user's role safely.
-- By using SECURITY DEFINER and setting search_path, we run with owner privileges
-- which bypasses RLS and prevents recursion.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role AS $$
DECLARE
  v_role public.user_role;
BEGIN
  SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
  RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Drop the recursive policy on public.profiles
DROP POLICY IF EXISTS "Students read own profile, teachers/admins read all" ON public.profiles;

-- 3. Re-create the secure, non-recursive policy on public.profiles
CREATE POLICY "Students read own profile, teachers/admins read all" ON public.profiles
  FOR SELECT USING (
    auth.uid() = id OR public.get_my_role() IN ('teacher', 'admin')
  );

-- 4. Drop the recursive policy on public.student_profiles
DROP POLICY IF EXISTS "Students read own subprofile, teachers/admins read all" ON public.student_profiles;

-- 5. Re-create the secure, non-recursive policy on public.student_profiles
CREATE POLICY "Students read own subprofile, teachers/admins read all" ON public.student_profiles
  FOR SELECT USING (
    auth.uid() = id OR public.get_my_role() IN ('teacher', 'admin')
  );

-- Drop old insecure policies
DROP POLICY IF EXISTS "Public profiles are viewable by anyone" ON public.profiles;
DROP POLICY IF EXISTS "Student profiles are viewable by authenticated users" ON public.student_profiles;

-- Create new secure select policies
CREATE POLICY "Students read own profile, teachers/admins read all" ON public.profiles
  FOR SELECT USING (
    auth.uid() = id OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND (profiles.role = 'teacher' OR profiles.role = 'admin')
    )
  );

CREATE POLICY "Students read own subprofile, teachers/admins read all" ON public.student_profiles
  FOR SELECT USING (
    auth.uid() = id OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND (profiles.role = 'teacher' OR profiles.role = 'admin')
    )
  );

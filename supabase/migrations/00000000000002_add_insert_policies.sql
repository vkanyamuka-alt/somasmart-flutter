-- SomaSmart: Add missing INSERT RLS policies for profile tables
-- These allow the client-side fallback in syncUserProfile to work
-- when the database trigger doesn't fire (edge cases).

-- Allow authenticated users to insert their own profile row
CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow authenticated students to insert their own student sub-profile
CREATE POLICY "Students can insert their own subprofile" ON public.student_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow authenticated teachers to insert their own teacher sub-profile  
CREATE POLICY "Teachers can insert their own subprofile" ON public.teacher_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert their own security logs
CREATE POLICY "Users can insert their own security logs" ON public.security_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

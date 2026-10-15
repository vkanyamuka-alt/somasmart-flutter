-- SomaSmart Redesign: Admin Policies, Teacher Isolation, Security Triggers, and Alias Views

-- 1. Create a helper to check if user role column is being changed maliciously
CREATE OR REPLACE FUNCTION public.check_profile_role_update()
RETURNS trigger AS $$
BEGIN
  -- If role is being changed, check if the executing user is an admin
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    ) THEN
      RAISE EXCEPTION 'Only administrators can change user roles.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Drop trigger if exists, then create it
DROP TRIGGER IF EXISTS tr_check_profile_role_update ON public.profiles;
CREATE TRIGGER tr_check_profile_role_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.check_profile_role_update();


-- 2. Drop existing restrictive policies to prevent duplicates/conflicts
DROP POLICY IF EXISTS "Admins can update notes (for approvals)" ON public.notes;
DROP POLICY IF EXISTS "Admins can manage all practicals" ON public.practicals;
DROP POLICY IF EXISTS "Admins can delete materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Admins and teachers can insert memorize items" ON public.memorize_items;
DROP POLICY IF EXISTS "Admins can update memorize items" ON public.memorize_items;
DROP POLICY IF EXISTS "Admins can delete memorize items" ON public.memorize_items;
DROP POLICY IF EXISTS "Admins can manage announcements" ON public.announcements;
DROP POLICY IF EXISTS "Admins can manage permitted_teachers" ON public.permitted_teachers;

-- 3. Define standard helper policy for admins (granting full access across all tables)
-- Rather than write individual policies for each operation, we grant FOR ALL TO authenticated USING (admin check)
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'profiles', 'student_profiles', 'teacher_profiles', 'subjects', 'notes', 
    'quizzes', 'quiz_questions', 'quiz_attempts', 'teacher_earnings', 'payments', 
    'practicals', 'discussions', 'discussion_replies', 'security_logs', 
    'learning_materials', 'memorize_items', 'announcements', 'permitted_teachers'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Admins have full access" ON public.%I', t);
    EXECUTE format('CREATE POLICY "Admins have full access" ON public.%I FOR ALL TO authenticated USING (public.get_my_role() = %L) WITH CHECK (public.get_my_role() = %L)', t, 'admin', 'admin');
  END LOOP;
END $$;


-- 4. Secure Teacher Access Policies (Strict Isolation)
-- Teachers must only read/update/delete their own uploads.

-- Notes
DROP POLICY IF EXISTS "Approved notes are readable by anyone" ON public.notes;
DROP POLICY IF EXISTS "Select policy for notes" ON public.notes;
CREATE POLICY "Select policy for notes" ON public.notes
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'student' AND status = 'approved') OR
    (public.get_my_role() = 'teacher' AND teacher_id = auth.uid())
  );

DROP POLICY IF EXISTS "Teachers can insert notes" ON public.notes;
CREATE POLICY "Teachers can insert notes" ON public.notes
  FOR INSERT TO authenticated WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can update their own notes" ON public.notes;
CREATE POLICY "Teachers can update their own notes" ON public.notes
  FOR UPDATE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  ) WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can delete their own notes" ON public.notes;
CREATE POLICY "Teachers can delete their own notes" ON public.notes
  FOR DELETE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

-- Learning Materials
DROP POLICY IF EXISTS "Published materials are readable by everyone" ON public.learning_materials;
DROP POLICY IF EXISTS "Select policy for learning_materials" ON public.learning_materials;
CREATE POLICY "Select policy for learning_materials" ON public.learning_materials
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'student' AND status = 'published') OR
    (public.get_my_role() = 'teacher' AND teacher_id = auth.uid())
  );

DROP POLICY IF EXISTS "Teachers and admins can insert materials" ON public.learning_materials;
CREATE POLICY "Teachers can insert materials" ON public.learning_materials
  FOR INSERT TO authenticated WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can update their own materials" ON public.learning_materials;
CREATE POLICY "Teachers can update their own materials" ON public.learning_materials
  FOR UPDATE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  ) WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can delete their own materials" ON public.learning_materials;
CREATE POLICY "Teachers can delete their own materials" ON public.learning_materials
  FOR DELETE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

-- Practicals
DROP POLICY IF EXISTS "Approved practicals are readable by everyone" ON public.practicals;
DROP POLICY IF EXISTS "Select policy for practicals" ON public.practicals;
CREATE POLICY "Select policy for practicals" ON public.practicals
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'student' AND status = 'approved') OR
    (public.get_my_role() = 'teacher' AND teacher_id = auth.uid())
  );

DROP POLICY IF EXISTS "Teachers can insert practicals" ON public.practicals;
CREATE POLICY "Teachers can insert practicals" ON public.practicals
  FOR INSERT TO authenticated WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can update their own practicals" ON public.practicals;
CREATE POLICY "Teachers can update their own practicals" ON public.practicals
  FOR UPDATE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  ) WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can delete their own practicals" ON public.practicals;
CREATE POLICY "Teachers can delete their own practicals" ON public.practicals
  FOR DELETE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

-- Quizzes
DROP POLICY IF EXISTS "Quizzes are readable by everyone" ON public.quizzes;
DROP POLICY IF EXISTS "Select policy for quizzes" ON public.quizzes;
CREATE POLICY "Select policy for quizzes" ON public.quizzes
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    public.get_my_role() = 'student' OR
    (public.get_my_role() = 'teacher' AND teacher_id = auth.uid())
  );

DROP POLICY IF EXISTS "Teachers can create quizzes" ON public.quizzes;
CREATE POLICY "Teachers can create quizzes" ON public.quizzes
  FOR INSERT TO authenticated WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can edit their own quizzes" ON public.quizzes;
CREATE POLICY "Teachers can update their own quizzes" ON public.quizzes
  FOR UPDATE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  ) WITH CHECK (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

DROP POLICY IF EXISTS "Teachers can delete their own quizzes" ON public.quizzes;
CREATE POLICY "Teachers can delete their own quizzes" ON public.quizzes
  FOR DELETE TO authenticated USING (
    public.get_my_role() = 'teacher' AND teacher_id = auth.uid()
  );

-- Quiz Questions
DROP POLICY IF EXISTS "Teachers can edit questions" ON public.quiz_questions;
DROP POLICY IF EXISTS "Teachers can manage questions for their quizzes" ON public.quiz_questions;
CREATE POLICY "Teachers can manage questions for their quizzes" ON public.quiz_questions
  FOR ALL TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'teacher' AND EXISTS (
      SELECT 1 FROM public.quizzes WHERE quizzes.id = quiz_questions.quiz_id AND quizzes.teacher_id = auth.uid()
    ))
  );


-- 5. Create Alias Views for Target Database Schema
CREATE OR REPLACE VIEW public.students AS
  SELECT * FROM public.profiles WHERE role = 'student';

CREATE OR REPLACE VIEW public.teachers AS
  SELECT * FROM public.profiles WHERE role = 'teacher';

CREATE OR REPLACE VIEW public.categories AS
  SELECT * FROM public.subjects;

CREATE OR REPLACE VIEW public.videos AS
  SELECT * FROM public.learning_materials WHERE material_type = 'video';

CREATE OR REPLACE VIEW public.audio AS
  SELECT * FROM public.learning_materials WHERE material_type = 'audio';

CREATE OR REPLACE VIEW public.documents AS
  SELECT * FROM public.learning_materials WHERE material_type = 'pdf' OR material_type = 'document';

CREATE OR REPLACE VIEW public.subscriptions AS
  SELECT * FROM public.payments WHERE type = 'subscription';


-- 6. Seed default admin account securely (using postgres crypt/bcrypt)
DO $$
DECLARE
  v_admin_id UUID;
BEGIN
  -- Get existing admin user ID if it exists
  SELECT id INTO v_admin_id FROM auth.users WHERE email = 'admin@somasmart.com';
  
  -- If it doesn't exist, create it with our custom UUID
  IF v_admin_id IS NULL THEN
    v_admin_id := 'a1b2c3d4-e5f6-7a8b-9c0d-e1f2a3b4c5d6';
    INSERT INTO auth.users (
      instance_id, id, role, aud, email, encrypted_password, 
      email_confirmed_at, recovery_sent_at, last_sign_in_at, 
      raw_app_meta_data, raw_user_meta_data, 
      created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_admin_id,
      'authenticated',
      'authenticated',
      'admin@somasmart.com',
      crypt('AdminPassword123!', gen_salt('bf')),
      now(), null, null,
      '{"provider":"email","providers":["email"]}',
      '{"role":"admin","full_name":"SomaSmart Admin"}',
      now(), now(), '', '', '', ''
    );
  END IF;

  -- Ensure public profile matches admin
  INSERT INTO public.profiles (
    id, phone, email, role, full_name, subscription_status, subscription_started_at, subscription_expires_at
  )
  VALUES (
    v_admin_id,
    null,
    'admin@somasmart.com',
    'admin'::public.user_role,
    'SomaSmart Admin',
    'paid'::public.sub_status,
    now(),
    now() + interval '100 years'
  )
  ON CONFLICT (id) DO UPDATE 
  SET role = 'admin', subscription_status = 'paid', email = EXCLUDED.email;
END $$;

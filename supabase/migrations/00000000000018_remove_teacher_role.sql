-- 1. Drop FK constraints on teacher_id first to prevent violations
ALTER TABLE public.learning_materials DROP CONSTRAINT IF EXISTS learning_materials_teacher_id_fkey CASCADE;
ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_teacher_id_fkey CASCADE;
ALTER TABLE public.practicals DROP CONSTRAINT IF EXISTS practicals_teacher_id_fkey CASCADE;
ALTER TABLE public.quizzes DROP CONSTRAINT IF EXISTS quizzes_teacher_id_fkey CASCADE;

-- 2. Nullify teacher_id on content tables (migration 23 will drop the column and add admin_id)
UPDATE public.learning_materials SET teacher_id = NULL WHERE teacher_id IS NOT NULL;
UPDATE public.notes SET teacher_id = NULL WHERE teacher_id IS NOT NULL;
UPDATE public.practicals SET teacher_id = NULL WHERE teacher_id IS NOT NULL;
UPDATE public.quizzes SET teacher_id = NULL WHERE teacher_id IS NOT NULL;

-- 3. Reassign discussion content from teacher users before deleting them
DO $$
DECLARE
  v_admin_id uuid;
BEGIN
  SELECT id INTO v_admin_id FROM public.profiles WHERE role = 'admin' LIMIT 1;
  IF v_admin_id IS NOT NULL THEN
    UPDATE public.discussions SET user_id = v_admin_id
    WHERE user_id IN (SELECT id FROM public.profiles WHERE role = 'teacher');
    UPDATE public.discussion_replies SET user_id = v_admin_id
    WHERE user_id IN (SELECT id FROM public.profiles WHERE role = 'teacher');
  END IF;
END $$;



-- 2. Delete teacher authentication accounts (this cascades to public.profiles)
DELETE FROM auth.users 
WHERE id IN (SELECT id FROM public.profiles WHERE role = 'teacher');


-- 3. Drop teacher-specific structures
DROP TABLE IF EXISTS public.teacher_profiles CASCADE;
DROP TABLE IF EXISTS public.permitted_teachers CASCADE;
DROP TABLE IF EXISTS public.teacher_earnings CASCADE;
DROP VIEW IF EXISTS public.teachers CASCADE;

DROP FUNCTION IF EXISTS public.validate_invitation_token CASCADE;
DROP FUNCTION IF EXISTS public.use_invitation_token CASCADE;
DROP FUNCTION IF EXISTS public.check_teacher_registration_status CASCADE;


-- 4. Clean up handle_new_user() trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role public.user_role;
  v_fullname text;
  v_form_level int;
  v_stream text;
BEGIN
  -- Determine role from metadata or fallback
  v_role := COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role);
  v_fullname := COALESCE(new.raw_user_meta_data->>'full_name', 'Mtumiaji mpya');
  v_form_level := COALESCE((new.raw_user_meta_data->>'form_level')::integer, 1);
  v_stream := COALESCE(new.raw_user_meta_data->>'stream', 'none');

  -- If a profile with this email already exists, delete it first to prevent conflicts
  IF EXISTS (SELECT 1 FROM public.profiles WHERE email = new.email) THEN
    DELETE FROM public.profiles WHERE email = new.email;
  END IF;

  -- Insert profile
  INSERT INTO public.profiles (id, phone, email, role, full_name, subscription_status, subscription_started_at, subscription_expires_at)
  VALUES (
    new.id,
    new.phone,
    new.email,
    v_role,
    v_fullname,
    'free'::public.sub_status,
    now(),
    now() + interval '6 months'
  );

  -- Insert sub-profiles
  IF v_role = 'student' THEN
    INSERT INTO public.student_profiles (id, form_level, stream)
    VALUES (new.id, v_form_level, v_stream)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 5. Drop views that depend on teacher_status before dropping the column
DROP VIEW IF EXISTS public.students CASCADE;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS teacher_status CASCADE;


-- 6. Clean up RLS policies (redefining selector policies to exclude teacher access)

-- Notes
DROP POLICY IF EXISTS "Select policy for notes" ON public.notes;
DROP POLICY IF EXISTS "Teachers can insert notes" ON public.notes;
DROP POLICY IF EXISTS "Teachers can update their own notes" ON public.notes;
DROP POLICY IF EXISTS "Teachers can delete their own notes" ON public.notes;

CREATE POLICY "Select policy for notes" ON public.notes
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'student' AND status = 'approved')
  );

-- Learning Materials
DROP POLICY IF EXISTS "Select policy for learning_materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can insert materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can update their own materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can delete their own materials" ON public.learning_materials;

CREATE POLICY "Select policy for learning_materials" ON public.learning_materials
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'student' AND status = 'published')
  );

-- Practicals
DROP POLICY IF EXISTS "Select policy for practicals" ON public.practicals;
DROP POLICY IF EXISTS "Teachers can insert practicals" ON public.practicals;
DROP POLICY IF EXISTS "Teachers can update their own practicals" ON public.practicals;
DROP POLICY IF EXISTS "Teachers can delete their own practicals" ON public.practicals;

CREATE POLICY "Select policy for practicals" ON public.practicals
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    (public.get_my_role() = 'student' AND status = 'approved')
  );

-- Quizzes
DROP POLICY IF EXISTS "Select policy for quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Teachers can create quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Teachers can update their own quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Teachers can delete their own quizzes" ON public.quizzes;

CREATE POLICY "Select policy for quizzes" ON public.quizzes
  FOR SELECT TO authenticated USING (
    public.get_my_role() = 'admin' OR
    public.get_my_role() = 'student'
  );

-- Quiz Questions
DROP POLICY IF EXISTS "Teachers can manage questions for their quizzes" ON public.quiz_questions;

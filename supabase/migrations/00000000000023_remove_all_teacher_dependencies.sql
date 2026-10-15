-- Migration 23: Complete Transition to Admin-Only Architecture (Option A)
-- Platform is admin-managed: content belongs to Admins via admin_id referencing public.profiles(id)

-- 1. Ensure admin_id columns exist on content tables
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS admin_id UUID;
ALTER TABLE public.learning_materials ADD COLUMN IF NOT EXISTS admin_id UUID;
ALTER TABLE public.practicals ADD COLUMN IF NOT EXISTS admin_id UUID;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS admin_id UUID;

-- 2. Data Migration: Copy teacher_id to admin_id if teacher_id exists, or assign default admin
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notes' AND column_name = 'teacher_id'
    ) THEN
        UPDATE public.notes 
        SET admin_id = teacher_id 
        WHERE admin_id IS NULL AND teacher_id IS NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'learning_materials' AND column_name = 'teacher_id'
    ) THEN
        UPDATE public.learning_materials 
        SET admin_id = teacher_id 
        WHERE admin_id IS NULL AND teacher_id IS NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'practicals' AND column_name = 'teacher_id'
    ) THEN
        UPDATE public.practicals 
        SET admin_id = teacher_id 
        WHERE admin_id IS NULL AND teacher_id IS NOT NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'quizzes' AND column_name = 'teacher_id'
    ) THEN
        UPDATE public.quizzes 
        SET admin_id = teacher_id 
        WHERE admin_id IS NULL AND teacher_id IS NOT NULL;
    END IF;
END $$;

-- 3. Drop all foreign key constraints referencing teacher_id or teacher tables dynamically
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT constraint_name, table_name
        FROM information_schema.table_constraints
        WHERE table_schema = 'public'
          AND (constraint_name LIKE '%teacher%' OR constraint_name LIKE '%teacher_id%')
    ) LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.table_name) || ' DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name) || ' CASCADE;';
    END LOOP;
END $$;

-- Explicitly drop notes_teacher_id_fkey if still present
ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_teacher_id_fkey CASCADE;

-- 4. Drop teacher_id columns from content tables
ALTER TABLE public.notes DROP COLUMN IF EXISTS teacher_id CASCADE;
ALTER TABLE public.learning_materials DROP COLUMN IF EXISTS teacher_id CASCADE;
ALTER TABLE public.practicals DROP COLUMN IF EXISTS teacher_id CASCADE;
ALTER TABLE public.quizzes DROP COLUMN IF EXISTS teacher_id CASCADE;

-- 5. Create explicit foreign key relationships referencing public.profiles(id)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'notes_admin_id_fkey'
    ) THEN
        ALTER TABLE public.notes 
        ADD CONSTRAINT notes_admin_id_fkey 
        FOREIGN KEY (admin_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'learning_materials_admin_id_fkey'
    ) THEN
        ALTER TABLE public.learning_materials 
        ADD CONSTRAINT learning_materials_admin_id_fkey 
        FOREIGN KEY (admin_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'practicals_admin_id_fkey'
    ) THEN
        ALTER TABLE public.practicals 
        ADD CONSTRAINT practicals_admin_id_fkey 
        FOREIGN KEY (admin_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'quizzes_admin_id_fkey'
    ) THEN
        ALTER TABLE public.quizzes 
        ADD CONSTRAINT quizzes_admin_id_fkey 
        FOREIGN KEY (admin_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 6. Row Level Security (RLS) Policies for public.notes
DROP POLICY IF EXISTS "Select policy for notes" ON public.notes;
DROP POLICY IF EXISTS "Admin full management of notes" ON public.notes;
DROP POLICY IF EXISTS "Allow public read approved notes" ON public.notes;
DROP POLICY IF EXISTS "Teachers can insert notes" ON public.notes;
DROP POLICY IF EXISTS "Teachers can update their own notes" ON public.notes;
DROP POLICY IF EXISTS "Teachers can delete their own notes" ON public.notes;

CREATE POLICY "Allow public read approved notes" ON public.notes
  FOR SELECT USING (
    status = 'approved' OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin full management of notes" ON public.notes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 7. RLS Policies for public.learning_materials
DROP POLICY IF EXISTS "Select policy for learning_materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Admin full management of learning_materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Allow public read published learning_materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can insert materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can update their own materials" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can delete their own materials" ON public.learning_materials;

CREATE POLICY "Allow public read published learning_materials" ON public.learning_materials
  FOR SELECT USING (
    status = 'published' OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin full management of learning_materials" ON public.learning_materials
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 8. RLS Policies for public.practicals
DROP POLICY IF EXISTS "Select policy for practicals" ON public.practicals;
DROP POLICY IF EXISTS "Admin full management of practicals" ON public.practicals;
DROP POLICY IF EXISTS "Allow public read approved practicals" ON public.practicals;
DROP POLICY IF EXISTS "Teachers can insert practicals" ON public.practicals;
DROP POLICY IF EXISTS "Teachers can update their own practicals" ON public.practicals;
DROP POLICY IF EXISTS "Teachers can delete their own practicals" ON public.practicals;

CREATE POLICY "Allow public read approved practicals" ON public.practicals
  FOR SELECT USING (
    status = 'approved' OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin full management of practicals" ON public.practicals
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 9. RLS Policies for public.quizzes & quiz_questions
DROP POLICY IF EXISTS "Select policy for quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Admin full management of quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Allow authenticated read quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Teachers can create quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Teachers can update their own quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "Teachers can delete their own quizzes" ON public.quizzes;

CREATE POLICY "Allow authenticated read quizzes" ON public.quizzes
  FOR SELECT USING (TRUE);

CREATE POLICY "Admin full management of quizzes" ON public.quizzes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Teachers can manage questions for their quizzes" ON public.quiz_questions;
DROP POLICY IF EXISTS "Admin full management of quiz_questions" ON public.quiz_questions;
DROP POLICY IF EXISTS "Allow authenticated read quiz_questions" ON public.quiz_questions;

CREATE POLICY "Allow authenticated read quiz_questions" ON public.quiz_questions
  FOR SELECT USING (TRUE);

CREATE POLICY "Admin full management of quiz_questions" ON public.quiz_questions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 10. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';

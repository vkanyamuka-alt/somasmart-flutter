-- ElimuHub Database Migration Schema

-- Create custom types and domains
CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin');
CREATE TYPE sub_status AS ENUM ('free', 'paid', 'expired');
CREATE TYPE note_type AS ENUM ('pdf', 'image', 'text');
CREATE TYPE note_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE question_type AS ENUM ('mcq', 'true_false', 'short');
CREATE TYPE payment_method_type AS ENUM ('mpesa', 'airtel', 'tigo', 'card');
CREATE TYPE payment_status_type AS ENUM ('pending', 'success', 'failed');
CREATE TYPE payment_txn_type AS ENUM ('subscription', 'premium_notes', 'mock_exam');
CREATE TYPE difficulty_level AS ENUM ('easy', 'medium', 'hard');

-- 1. Profiles (Watumiaji wote)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY,
  phone VARCHAR(20) UNIQUE,
  email VARCHAR(255) UNIQUE,
  role user_role NOT NULL DEFAULT 'student',
  full_name VARCHAR(255) NOT NULL,
  subscription_status sub_status NOT NULL DEFAULT 'free',
  subscription_started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  subscription_expires_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now() + interval '6 months'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Student Profiles (Wasifu wa Wanafunzi)
CREATE TABLE IF NOT EXISTS public.student_profiles (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  form_level INT NOT NULL CHECK (form_level BETWEEN 1 AND 6),
  stream VARCHAR(20) DEFAULT 'none' CHECK (stream IN ('science', 'arts', 'commerce', 'none'))
);

ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;

-- 3. Teacher Profiles (Wasifu wa Walimu)
CREATE TABLE IF NOT EXISTS public.teacher_profiles (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  bio TEXT,
  school VARCHAR(255),
  verified BOOLEAN DEFAULT false,
  total_earnings DECIMAL(10,2) DEFAULT 0.00,
  balance DECIMAL(10,2) DEFAULT 0.00
);

ALTER TABLE public.teacher_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Subjects (Masomo)
CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_sw VARCHAR(100) NOT NULL,
  name_en VARCHAR(100) NOT NULL,
  form_levels INT[] NOT NULL, -- e.g. [1,2,3,4]
  icon VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

-- 5. Notes (Content / Summaries)
CREATE TABLE IF NOT EXISTS public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES public.teacher_profiles(id) ON DELETE SET NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  form_level INT NOT NULL CHECK (form_level BETWEEN 1 AND 6),
  language VARCHAR(10) NOT NULL CHECK (language IN ('sw', 'en', 'both')),
  file_url VARCHAR(500), -- Path in Supabase Storage or text content
  file_type note_type NOT NULL DEFAULT 'text',
  status note_status NOT NULL DEFAULT 'pending',
  price DECIMAL(8,2) DEFAULT 0.00,
  downloads INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  approved_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 6. Quizzes (Majaribio)
CREATE TABLE IF NOT EXISTS public.quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES public.teacher_profiles(id) ON DELETE SET NULL,
  notes_id UUID REFERENCES public.notes(id) ON DELETE SET NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  form_level INT NOT NULL CHECK (form_level BETWEEN 1 AND 6),
  difficulty difficulty_level NOT NULL DEFAULT 'medium',
  total_questions INT DEFAULT 0,
  time_limit_minutes INT DEFAULT 15,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

-- 7. Quiz Questions (Maswali ya Quiz)
CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_type question_type NOT NULL DEFAULT 'mcq',
  options JSONB, -- list of options: [{"text": "...", "correct": boolean}]
  correct_answer TEXT,
  explanation TEXT,
  difficulty difficulty_level NOT NULL DEFAULT 'medium',
  order_num INT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

-- 8. Quiz Attempts (Matokeo ya Quiz)
CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES public.student_profiles(id) ON DELETE CASCADE,
  quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE,
  score DECIMAL(5,2) NOT NULL, -- percentage score
  time_taken_seconds INT NOT NULL,
  answers JSONB, -- key-value answers: {"question_id": "submitted_text"}
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

-- 9. Teacher Earnings (Mapato ya Walimu)
CREATE TABLE IF NOT EXISTS public.teacher_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES public.teacher_profiles(id) ON DELETE CASCADE,
  student_id UUID REFERENCES public.student_profiles(id) ON DELETE SET NULL,
  notes_id UUID REFERENCES public.notes(id) ON DELETE SET NULL,
  amount DECIMAL(8,2) NOT NULL,
  platform_fee DECIMAL(8,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.teacher_earnings ENABLE ROW LEVEL SECURITY;

-- 10. Payments (Malipo ya Wanafunzi)
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount DECIMAL(8,2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'TZS',
  payment_method payment_method_type NOT NULL,
  payment_reference VARCHAR(255) NOT NULL UNIQUE,
  status payment_status_type NOT NULL DEFAULT 'pending',
  type payment_txn_type NOT NULL DEFAULT 'subscription',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;


-- ==========================================
-- Triggers and Functions for Auth integration
-- ==========================================

-- Function to handle public profile creation when a new user registers in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role public.user_role;
  v_fullname text;
  v_form_level int;
  v_stream text;
BEGIN
  v_role := COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role);
  v_fullname := COALESCE(new.raw_user_meta_data->>'full_name', 'Mtumiaji mpya');
  v_form_level := COALESCE((new.raw_user_meta_data->>'form_level')::integer, 1);
  v_stream := COALESCE(new.raw_user_meta_data->>'stream', 'none');

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
    VALUES (new.id, v_form_level, v_stream);
  ELSIF v_role = 'teacher' THEN
    INSERT INTO public.teacher_profiles (id, bio, school, verified, total_earnings, balance)
    VALUES (new.id, 'Mwalimu katika ElimuHub', '', false, 0.00, 0.00);
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute on auth.users insert
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ==========================================
-- RLS Security Policies
-- ==========================================

-- Profiles
CREATE POLICY "Public profiles are viewable by anyone" ON public.profiles
  FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Student Profiles
CREATE POLICY "Student profiles are viewable by authenticated users" ON public.student_profiles
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Students can update their own subprofile" ON public.student_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Teacher Profiles
CREATE POLICY "Teacher profiles are viewable by anyone" ON public.teacher_profiles
  FOR SELECT USING (true);
CREATE POLICY "Teachers can update their own subprofile" ON public.teacher_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Subjects
CREATE POLICY "Subjects are viewable by everyone" ON public.subjects
  FOR SELECT USING (true);
CREATE POLICY "Only admins can edit subjects" ON public.subjects
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Notes
CREATE POLICY "Approved notes are readable by anyone" ON public.notes
  FOR SELECT USING (status = 'approved' OR auth.uid() = (SELECT profiles.id FROM public.profiles JOIN public.teacher_profiles ON profiles.id = teacher_profiles.id WHERE teacher_profiles.id = notes.teacher_id));
CREATE POLICY "Teachers can insert notes" ON public.notes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'teacher'
    )
  );
CREATE POLICY "Teachers can update their own notes" ON public.notes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.teacher_profiles
      WHERE teacher_profiles.id = notes.teacher_id AND teacher_profiles.id = auth.uid()
    )
  );
CREATE POLICY "Admins can update notes (for approvals)" ON public.notes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Quizzes
CREATE POLICY "Quizzes are readable by everyone" ON public.quizzes
  FOR SELECT USING (true);
CREATE POLICY "Teachers can create quizzes" ON public.quizzes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'teacher'
    )
  );
CREATE POLICY "Teachers can edit their own quizzes" ON public.quizzes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.teacher_profiles
      WHERE teacher_profiles.id = quizzes.teacher_id AND teacher_profiles.id = auth.uid()
    )
  );

-- Quiz Questions
CREATE POLICY "Quiz questions are readable by everyone" ON public.quiz_questions
  FOR SELECT USING (true);
CREATE POLICY "Teachers can edit questions" ON public.quiz_questions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.quizzes
      WHERE quizzes.id = quiz_questions.quiz_id AND quizzes.teacher_id = auth.uid()
    )
  );

-- Quiz Attempts
CREATE POLICY "Students can read their own attempts" ON public.quiz_attempts
  FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Students can insert their own attempts" ON public.quiz_attempts
  FOR INSERT WITH CHECK (student_id = auth.uid());

-- Teacher Earnings
CREATE POLICY "Teachers can view their own earnings" ON public.teacher_earnings
  FOR SELECT USING (teacher_id = auth.uid());

-- Payments
CREATE POLICY "Users can view their own payments" ON public.payments
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create payments" ON public.payments
  FOR INSERT WITH CHECK (user_id = auth.uid());


-- ==========================================
-- Seed Data for Subjects
-- ==========================================

INSERT INTO public.subjects (id, name_sw, name_en, form_levels, icon)
VALUES 
  ('8b5e28a5-d8cf-4351-a982-1df3e0cf5581', 'Hisabati', 'Mathematics', ARRAY[1,2,3,4,5,6], 'calculator'),
  ('c4a631bf-9d0a-42c2-8411-9f9361ad22f0', 'Fizikia', 'Physics', ARRAY[1,2,3,4,5,6], 'atom'),
  ('a5e01df3-8f0a-493e-bc5d-6c1f2ea8b21c', 'Kemia', 'Chemistry', ARRAY[1,2,3,4,5,6], 'flask'),
  ('58d0421e-1f7c-473d-bd83-aa1e8f25b290', 'Biolojia', 'Biology', ARRAY[1,2,3,4,5,6], 'dna'),
  ('fb4e29c8-d1ff-4841-b0db-e3a2410a8d67', 'Kiswahili', 'Kiswahili', ARRAY[1,2,3,4], 'book-open')
ON CONFLICT (id) DO NOTHING;

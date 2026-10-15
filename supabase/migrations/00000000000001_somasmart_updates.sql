-- SomaSmart Extensions Schema Migration

-- 1. Add current_device_id column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS current_device_id TEXT;

-- 2. Create Practicals table
CREATE TABLE IF NOT EXISTS public.practicals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES public.teacher_profiles(id) ON DELETE SET NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  form_level INT NOT NULL CHECK (form_level BETWEEN 1 AND 6),
  file_url VARCHAR(500),
  file_type VARCHAR(20) DEFAULT 'text', -- 'text', 'pdf', 'video'
  status note_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.practicals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Approved practicals are readable by everyone" ON public.practicals
  FOR SELECT USING (status = 'approved' OR auth.uid() = (SELECT profiles.id FROM public.profiles JOIN public.teacher_profiles ON profiles.id = teacher_profiles.id WHERE teacher_profiles.id = practicals.teacher_id));

CREATE POLICY "Teachers can insert practicals" ON public.practicals
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'teacher'
    )
  );

CREATE POLICY "Teachers can update their own practicals" ON public.practicals
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.teacher_profiles
      WHERE teacher_profiles.id = practicals.teacher_id AND teacher_profiles.id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all practicals" ON public.practicals
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 3. Create Discussions table
CREATE TABLE IF NOT EXISTS public.discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.discussions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Discussions are readable by everyone" ON public.discussions
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create discussions" ON public.discussions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own discussions" ON public.discussions
  FOR DELETE USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('teacher', 'admin')
  ));

-- 4. Create Discussion Replies table
CREATE TABLE IF NOT EXISTS public.discussion_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID REFERENCES public.discussions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.discussion_replies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Replies are readable by everyone" ON public.discussion_replies
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create replies" ON public.discussion_replies
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own replies" ON public.discussion_replies
  FOR DELETE USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('teacher', 'admin')
  ));

-- 5. Create Security Logs table
CREATE TABLE IF NOT EXISTS public.security_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own security logs" ON public.security_logs
  FOR SELECT USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  ));

CREATE POLICY "System can insert security logs" ON public.security_logs
  FOR INSERT WITH CHECK (true);

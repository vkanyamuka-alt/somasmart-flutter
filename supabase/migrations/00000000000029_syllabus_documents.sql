-- Migration: 00000000000029_syllabus_documents.sql
-- Description: Creates public.syllabus_documents table for official curriculum PDFs with multi-form coverage support and RLS.

CREATE TABLE IF NOT EXISTS public.syllabus_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  education_level VARCHAR(20) NOT NULL CHECK (education_level IN ('o-level', 'a-level')),
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  subject_name VARCHAR(100) NOT NULL,
  title VARCHAR(255) NOT NULL,
  coverage VARCHAR(100) NOT NULL, -- e.g. "Form I – IV" or "Form V – VI"
  form_levels INT[] NOT NULL DEFAULT '{}', -- e.g. [1, 2, 3, 4]
  academic_year VARCHAR(50) DEFAULT '2023',
  version VARCHAR(50) DEFAULT 'Current', -- e.g. 'Current', '2023', '2019'
  source_organization VARCHAR(255) NOT NULL DEFAULT 'Tanzania Institute of Education (TIE)',
  official_source_url TEXT,
  file_url TEXT NOT NULL,
  file_name VARCHAR(255),
  file_size BIGINT,
  mime_type VARCHAR(100) DEFAULT 'application/pdf',
  thumbnail_url TEXT,
  is_verified BOOLEAN DEFAULT true,
  is_published BOOLEAN DEFAULT true,
  download_allowed BOOLEAN DEFAULT true,
  uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Index for fast lookup by education level, subject and published state
CREATE INDEX IF NOT EXISTS idx_syllabus_docs_level_subject ON public.syllabus_documents(education_level, subject_name, is_published);
CREATE INDEX IF NOT EXISTS idx_syllabus_docs_published ON public.syllabus_documents(is_published);

-- Enable Row Level Security
ALTER TABLE public.syllabus_documents ENABLE ROW LEVEL SECURITY;

-- 1. Public / Student Read Access Policy (Only published documents)
CREATE POLICY "Public & students can view published syllabus documents"
ON public.syllabus_documents FOR SELECT
USING (
  is_published = true 
  OR 
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

-- 2. Admin Insert Policy
CREATE POLICY "Admins can insert syllabus documents"
ON public.syllabus_documents FOR INSERT
WITH CHECK (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

-- 3. Admin Update Policy
CREATE POLICY "Admins can update syllabus documents"
ON public.syllabus_documents FOR UPDATE
USING (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
)
WITH CHECK (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

-- 4. Admin Delete Policy
CREATE POLICY "Admins can delete syllabus documents"
ON public.syllabus_documents FOR DELETE
USING (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

-- Ensure storage bucket 'learning-materials' allows syllabus documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('learning-materials', 'learning-materials', true)
ON CONFLICT (id) DO NOTHING;

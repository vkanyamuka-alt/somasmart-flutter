-- SomaSmart: Learning Materials, Memorize Items, and Announcements
-- This migration adds the external-content architecture tables

-- 1. Create material_type enum
DO $$ BEGIN
  CREATE TYPE material_type AS ENUM ('video', 'audio', 'pdf', 'document', 'other');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Create material_section enum
DO $$ BEGIN
  CREATE TYPE material_section AS ENUM ('understand_master', 'memorize');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 3. Create material_status enum
DO $$ BEGIN
  CREATE TYPE material_status AS ENUM ('published', 'draft', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 4. Create memorize_item_type enum
DO $$ BEGIN
  CREATE TYPE memorize_item_type AS ENUM ('formula', 'mnemonic', 'memory_trick');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 5. Create announcement_priority enum
DO $$ BEGIN
  CREATE TYPE announcement_priority AS ENUM ('low', 'medium', 'high');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ==========================================
-- Learning Materials Table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.learning_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  topic VARCHAR(500),
  title VARCHAR(500) NOT NULL,
  description TEXT,
  material_type material_type NOT NULL DEFAULT 'video',
  external_url TEXT,
  wistia_video_id VARCHAR(255),
  thumbnail_url TEXT,
  duration_seconds INT,
  file_size_bytes BIGINT,
  form_level INT NOT NULL CHECK (form_level BETWEEN 1 AND 6),
  language VARCHAR(10) NOT NULL DEFAULT 'both' CHECK (language IN ('sw', 'en', 'both')),
  section material_section NOT NULL DEFAULT 'understand_master',
  status material_status NOT NULL DEFAULT 'draft',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.learning_materials ENABLE ROW LEVEL SECURITY;

-- Published materials readable by all authenticated users
CREATE POLICY "Published materials are readable by everyone" ON public.learning_materials
  FOR SELECT USING (status = 'published' OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role IN ('teacher', 'admin')
  ));

-- Teachers can insert materials
CREATE POLICY "Teachers and admins can insert materials" ON public.learning_materials
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role IN ('teacher', 'admin')
    )
  );

-- Teachers can update their own materials
CREATE POLICY "Teachers can update their own materials" ON public.learning_materials
  FOR UPDATE USING (
    teacher_id = auth.uid() OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Admins can delete materials
CREATE POLICY "Admins can delete materials" ON public.learning_materials
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );


-- ==========================================
-- Memorize Items Table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.memorize_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  topic VARCHAR(500),
  form_level INT NOT NULL CHECK (form_level BETWEEN 1 AND 6),
  item_type memorize_item_type NOT NULL DEFAULT 'formula',
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.memorize_items ENABLE ROW LEVEL SECURITY;

-- Published memorize items readable by all
CREATE POLICY "Published memorize items are readable by everyone" ON public.memorize_items
  FOR SELECT USING (is_published = true OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND profiles.role IN ('teacher', 'admin')
  ));

-- Admins and teachers can insert
CREATE POLICY "Admins and teachers can insert memorize items" ON public.memorize_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role IN ('teacher', 'admin')
    )
  );

-- Admins can update
CREATE POLICY "Admins can update memorize items" ON public.memorize_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Admins can delete
CREATE POLICY "Admins can delete memorize items" ON public.memorize_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );


-- ==========================================
-- Announcements Table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  priority announcement_priority NOT NULL DEFAULT 'medium',
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Active announcements readable by all
CREATE POLICY "Active announcements are readable by everyone" ON public.announcements
  FOR SELECT USING (true);

-- Admins can manage announcements
CREATE POLICY "Admins can manage announcements" ON public.announcements
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );


-- ==========================================
-- Add missing columns to existing tables
-- ==========================================

-- Add teacher_status to profiles if not exists
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS teacher_status VARCHAR(20);

-- Add text_content to notes if not exists
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS text_content TEXT;

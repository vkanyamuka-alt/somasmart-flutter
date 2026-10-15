-- Migration: Update learning_materials table to support educational video library metadata
ALTER TABLE public.learning_materials ADD COLUMN IF NOT EXISTS short_description TEXT;
ALTER TABLE public.learning_materials ADD COLUMN IF NOT EXISTS full_description TEXT;
ALTER TABLE public.learning_materials ADD COLUMN IF NOT EXISTS published_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());
ALTER TABLE public.learning_materials ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'General';

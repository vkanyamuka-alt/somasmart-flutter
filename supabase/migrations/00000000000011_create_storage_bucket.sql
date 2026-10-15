-- Migration 11: Create storage bucket (migration 5 was never applied to live DB)
-- Run this in Supabase SQL Editor or via supabase db push

-- Create the learning-materials bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('learning-materials', 'learning-materials', true)
ON CONFLICT (id) DO NOTHING;

-- Public read access
DROP POLICY IF EXISTS "Public Access to learning materials" ON storage.objects;
CREATE POLICY "Public Access to learning materials"
ON storage.objects FOR SELECT
USING (bucket_id = 'learning-materials');

-- Admin and teacher write access
DROP POLICY IF EXISTS "Admin and teacher CRUD access to learning materials" ON storage.objects;
CREATE POLICY "Admin and teacher CRUD access to learning materials"
ON storage.objects FOR ALL
USING (bucket_id = 'learning-materials')
WITH CHECK (bucket_id = 'learning-materials');

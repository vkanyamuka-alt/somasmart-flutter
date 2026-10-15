-- Create a public bucket for learning materials
INSERT INTO storage.buckets (id, name, public)
VALUES ('learning-materials', 'learning-materials', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for public access to the bucket
CREATE POLICY "Public Access to learning materials" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'learning-materials');

CREATE POLICY "Admin and teacher CRUD access to learning materials" 
ON storage.objects FOR ALL 
USING (bucket_id = 'learning-materials')
WITH CHECK (bucket_id = 'learning-materials');

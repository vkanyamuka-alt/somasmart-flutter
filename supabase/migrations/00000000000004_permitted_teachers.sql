-- Create permitted_teachers table
CREATE TABLE IF NOT EXISTS public.permitted_teachers (
  email TEXT PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS
ALTER TABLE public.permitted_teachers ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Admins can manage permitted_teachers" ON public.permitted_teachers 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Public read for permitted_teachers" ON public.permitted_teachers 
  FOR SELECT USING (true);

-- Insert demo teacher email by default
INSERT INTO public.permitted_teachers (email) VALUES ('teacher@somasmart.com') ON CONFLICT DO NOTHING;
INSERT INTO public.permitted_teachers (email) VALUES ('teacher@elimuhub.com') ON CONFLICT DO NOTHING;

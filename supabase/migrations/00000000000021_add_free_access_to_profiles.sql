-- Migration: Add free_access column to public.profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS free_access BOOLEAN DEFAULT FALSE;

-- Ensure RLS policies permit admins to update free_access on profiles
CREATE POLICY "Admins can update all profiles free_access"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

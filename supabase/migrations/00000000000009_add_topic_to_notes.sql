-- Add topic column to notes table for precise topic matching
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS topic VARCHAR(500);

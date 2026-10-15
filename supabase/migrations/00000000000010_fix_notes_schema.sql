-- Migration 10: Fix missing topic column and enum mismatch
-- Run this in the Supabase SQL Editor

-- 1. Add topic column to notes (if migration 9 was never applied to the live DB)
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS topic VARCHAR(500);

-- 2. Add text_content to notes (if migration 3 was never applied to the live DB)
ALTER TABLE public.notes ADD COLUMN IF NOT EXISTS text_content TEXT;

-- 3. Fix the note_type enum to include 'summary' used by the admin panel
-- Note: PostgreSQL doesn't allow DROP of enum values, so we add 'summary'
DO $$
BEGIN
  BEGIN
    ALTER TYPE note_type ADD VALUE IF NOT EXISTS 'summary';
  EXCEPTION WHEN others THEN
    -- ignore if already exists or not supported
    NULL;
  END;
END $$;

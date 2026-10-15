-- Migration 22: Remove teacher_id dependency on public.notes
-- Platform is admin-managed and does not use teacher accounts

-- 1. Ensure teacher_id column on public.notes is optional (DROP NOT NULL if present)
ALTER TABLE public.notes ALTER COLUMN teacher_id DROP NOT NULL;

-- 2. Drop any foreign key constraints on teacher_id if they exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'notes' AND constraint_name LIKE '%teacher_id%'
  ) THEN
    EXECUTE (
      SELECT 'ALTER TABLE public.notes DROP CONSTRAINT ' || quote_ident(constraint_name)
      FROM information_schema.table_constraints
      WHERE table_name = 'notes' AND constraint_name LIKE '%teacher_id%'
      LIMIT 1
    );
  END IF;
END $$;

-- 3. Ensure RLS policies allow full admin management and public/student reading without requiring teacher_id
DROP POLICY IF EXISTS "Select policy for notes" ON public.notes;
DROP POLICY IF EXISTS "Admin full management of notes" ON public.notes;
DROP POLICY IF EXISTS "Allow public read approved notes" ON public.notes;

CREATE POLICY "Allow public read approved notes" ON public.notes
  FOR SELECT USING (
    status = 'approved' OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin full management of notes" ON public.notes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

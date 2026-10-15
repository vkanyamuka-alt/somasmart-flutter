-- Migration 16: Update handle_new_user trigger to set status to active upon teacher registration
-- Run this in Supabase SQL Editor or via supabase db push

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role public.user_role;
  v_fullname text;
  v_form_level int;
  v_stream text;
BEGIN
  -- Determine role from metadata or fallback
  v_role := COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role);
  v_fullname := COALESCE(new.raw_user_meta_data->>'full_name', 'Mtumiaji mpya');
  v_form_level := COALESCE((new.raw_user_meta_data->>'form_level')::integer, 1);
  v_stream := COALESCE(new.raw_user_meta_data->>'stream', 'none');

  -- If a profile with this email already exists (e.g. invited teacher with random UUID),
  -- delete it first to prevent unique constraint or foreign key violations when inserting.
  IF EXISTS (SELECT 1 FROM public.profiles WHERE email = new.email) THEN
    DELETE FROM public.profiles WHERE email = new.email;
  END IF;

  -- Insert profile
  INSERT INTO public.profiles (id, phone, email, role, full_name, subscription_status, subscription_started_at, subscription_expires_at, teacher_status)
  VALUES (
    new.id,
    new.phone,
    new.email,
    v_role,
    v_fullname,
    'free'::public.sub_status,
    now(),
    now() + interval '6 months',
    CASE WHEN v_role = 'teacher' THEN 'active'::varchar ELSE null END
  );

  -- Insert sub-profiles
  IF v_role = 'student' THEN
    INSERT INTO public.student_profiles (id, form_level, stream)
    VALUES (new.id, v_form_level, v_stream)
    ON CONFLICT (id) DO NOTHING;
  ELSIF v_role = 'teacher' THEN
    INSERT INTO public.teacher_profiles (id, bio, school, verified, total_earnings, balance)
    VALUES (new.id, 'Mwalimu katika ElimuHub', '', false, 0.00, 0.00)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

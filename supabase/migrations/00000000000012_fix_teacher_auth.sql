-- Migration 12: Fix Teacher Auth Trigger and add registration check function
-- Run this in Supabase SQL Editor or via supabase db push

-- 1. Update public.handle_new_user() trigger function
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

  -- Check if a profile with this email already exists (e.g. invited teacher)
  IF EXISTS (SELECT 1 FROM public.profiles WHERE email = new.email) THEN
    -- Update the existing profile. Change its id to the actual auth user id.
    UPDATE public.profiles
    SET id = new.id,
        phone = COALESCE(new.phone, phone),
        role = v_role,
        full_name = CASE WHEN full_name = 'Mtumiaji mpya' THEN v_fullname ELSE COALESCE(v_fullname, full_name) END
    WHERE email = new.email;
  ELSE
    -- Insert new profile
    INSERT INTO public.profiles (id, phone, email, role, full_name, subscription_status, subscription_started_at, subscription_expires_at)
    VALUES (
      new.id,
      new.phone,
      new.email,
      v_role,
      v_fullname,
      'free'::public.sub_status,
      now(),
      now() + interval '6 months'
    );
  END IF;

  -- Insert sub-profiles if they do not exist
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

-- 2. Add public.check_teacher_registration_status(p_email text) helper function
CREATE OR REPLACE FUNCTION public.check_teacher_registration_status(p_email text)
RETURNS text AS $$
DECLARE
  v_status text;
  v_exists_permitted boolean;
  v_exists_profile boolean;
BEGIN
  -- Check if email is in permitted_teachers
  SELECT EXISTS(SELECT 1 FROM public.permitted_teachers WHERE email = p_email) INTO v_exists_permitted;
  IF NOT v_exists_permitted THEN
    RETURN 'not_invited';
  END IF;

  -- Check if profile exists and has been activated (registered)
  -- Since the admin inserts the profile with status 'invited' (or null/other), we check if the profile's id is in auth.users
  SELECT EXISTS(
    SELECT 1 FROM public.profiles p
    JOIN auth.users u ON p.id = u.id
    WHERE p.email = p_email
  ) INTO v_exists_profile;

  IF v_exists_profile THEN
    RETURN 'already_registered';
  END IF;

  -- Also check if status is active (just in case)
  SELECT teacher_status INTO v_status FROM public.profiles WHERE email = p_email;
  IF v_status = 'active' THEN
    RETURN 'already_registered';
  END IF;

  RETURN 'allowed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

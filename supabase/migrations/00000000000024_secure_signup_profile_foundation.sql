-- Phase 1 security foundation: safe public signup and profile-write RPCs.
-- This migration is additive. It does not delete or rewrite existing profile data.

-- Public signup metadata is not an authorization boundary. Every Auth-created
-- profile is therefore a student profile; administrators are provisioned only
-- through a trusted administrative process outside the public signup flow.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_full_name text;
  v_form_level integer;
  v_stream text;
BEGIN
  v_full_name := left(
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Mtumiaji mpya'
    ),
    255
  );

  v_form_level := CASE
    WHEN (new.raw_user_meta_data ->> 'form_level') ~ '^[1-6]$'
      THEN (new.raw_user_meta_data ->> 'form_level')::integer
    ELSE 1
  END;

  v_stream := CASE
    WHEN new.raw_user_meta_data ->> 'stream' IN ('science', 'arts', 'commerce', 'none')
      THEN new.raw_user_meta_data ->> 'stream'
    ELSE 'none'
  END;

  INSERT INTO public.profiles (
    id,
    phone,
    email,
    role,
    full_name,
    subscription_status,
    subscription_started_at,
    subscription_expires_at
  )
  VALUES (
    new.id,
    new.phone,
    new.email,
    'student'::public.user_role,
    v_full_name,
    'free'::public.sub_status,
    now(),
    now() + interval '6 months'
  )
  ON CONFLICT (id) DO NOTHING;

  -- Never alter an existing profile here. If it is a student profile, ensure
  -- its required student detail row exists without changing stored user data.
  IF EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = new.id
      AND role = 'student'::public.user_role
  ) THEN
    INSERT INTO public.student_profiles (id, form_level, stream)
    VALUES (new.id, v_form_level, v_stream)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN new;
END;
$$;

-- Trigger functions are not callable application APIs.
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM authenticated;

-- Safe, idempotent fallback for the rare case where an authenticated user has
-- no profile. It derives every identity and role value from the database/Auth,
-- accepts no caller-controlled inputs, and can only create a student profile.
CREATE OR REPLACE FUNCTION public.ensure_my_student_profile()
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_user auth.users%ROWTYPE;
  v_full_name text;
  v_form_level integer;
  v_stream text;
  v_profile public.profiles%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_user
  FROM auth.users
  WHERE id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Authenticated user was not found.' USING ERRCODE = '28000';
  END IF;

  v_full_name := left(
    coalesce(
      nullif(btrim(v_user.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(v_user.email, ''), '@', 1), ''),
      'Mtumiaji mpya'
    ),
    255
  );

  v_form_level := CASE
    WHEN (v_user.raw_user_meta_data ->> 'form_level') ~ '^[1-6]$'
      THEN (v_user.raw_user_meta_data ->> 'form_level')::integer
    ELSE 1
  END;

  v_stream := CASE
    WHEN v_user.raw_user_meta_data ->> 'stream' IN ('science', 'arts', 'commerce', 'none')
      THEN v_user.raw_user_meta_data ->> 'stream'
    ELSE 'none'
  END;

  INSERT INTO public.profiles (
    id,
    phone,
    email,
    role,
    full_name,
    subscription_status,
    subscription_started_at,
    subscription_expires_at
  )
  VALUES (
    v_user.id,
    v_user.phone,
    v_user.email,
    'student'::public.user_role,
    v_full_name,
    'free'::public.sub_status,
    now(),
    now() + interval '6 months'
  )
  ON CONFLICT (id) DO NOTHING;

  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile could not be created safely.' USING ERRCODE = 'P0001';
  END IF;

  IF v_profile.role = 'student'::public.user_role THEN
    INSERT INTO public.student_profiles (id, form_level, stream)
    VALUES (v_user.id, v_form_level, v_stream)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN v_profile;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_my_student_profile() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.ensure_my_student_profile() FROM anon;
GRANT EXECUTE ON FUNCTION public.ensure_my_student_profile() TO authenticated;

-- Browser clients can update only the account fields exposed by the account UI.
CREATE OR REPLACE FUNCTION public.update_my_profile(
  p_full_name text,
  p_phone text
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_profile public.profiles%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.' USING ERRCODE = '28000';
  END IF;

  IF nullif(btrim(p_full_name), '') IS NULL THEN
    RAISE EXCEPTION 'Full name is required.' USING ERRCODE = '22023';
  END IF;

  IF char_length(btrim(p_full_name)) > 255 THEN
    RAISE EXCEPTION 'Full name is too long.' USING ERRCODE = '22001';
  END IF;

  IF p_phone IS NOT NULL AND char_length(btrim(p_phone)) > 20 THEN
    RAISE EXCEPTION 'Phone number is too long.' USING ERRCODE = '22001';
  END IF;

  UPDATE public.profiles
  SET
    full_name = btrim(p_full_name),
    phone = nullif(btrim(p_phone), '')
  WHERE id = auth.uid()
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile was not found.' USING ERRCODE = 'P0001';
  END IF;

  RETURN v_profile;
END;
$$;

REVOKE ALL ON FUNCTION public.update_my_profile(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_my_profile(text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_my_profile(text, text) TO authenticated;

-- The role check is performed against the authoritative profiles table inside
-- PostgreSQL. The caller supplies only a target and boolean; neither can grant
-- authorization without a database-backed admin profile.
CREATE OR REPLACE FUNCTION public.set_user_free_access(
  p_target_user_id uuid,
  p_enabled boolean
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
  v_profile public.profiles%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.' USING ERRCODE = '28000';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'::public.user_role
  ) THEN
    RAISE EXCEPTION 'Administrator access is required.' USING ERRCODE = '42501';
  END IF;

  UPDATE public.profiles
  SET free_access = p_enabled
  WHERE id = p_target_user_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Target profile was not found.' USING ERRCODE = 'P0001';
  END IF;

  RETURN v_profile;
END;
$$;

REVOKE ALL ON FUNCTION public.set_user_free_access(uuid, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_user_free_access(uuid, boolean) FROM anon;
GRANT EXECUTE ON FUNCTION public.set_user_free_access(uuid, boolean) TO authenticated;

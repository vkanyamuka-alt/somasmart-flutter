-- Migration 17: Create security definer function to allow admins to delete authentication accounts
-- Run this in Supabase SQL Editor or via supabase db push

CREATE OR REPLACE FUNCTION public.delete_auth_user(user_id UUID)
RETURNS void AS $$
DECLARE
  v_role public.user_role;
BEGIN
  -- Check if calling user is admin
  SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
  IF v_role <> 'admin' THEN
    RAISE EXCEPTION 'Access Denied: Only administrators can delete authentication accounts.';
  END IF;

  DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = auth, public;

-- Migration 15: Add secure invitation token columns to permitted_teachers and create validation RPCs
ALTER TABLE public.permitted_teachers
ADD COLUMN IF NOT EXISTS token UUID DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '7 days'),
ADD COLUMN IF NOT EXISTS token_used BOOLEAN DEFAULT false;

-- Create RPC to validate invitation token
CREATE OR REPLACE FUNCTION public.validate_invitation_token(p_token UUID)
RETURNS TABLE(email TEXT, valid BOOLEAN, error_message TEXT) AS $$
DECLARE
  v_email TEXT;
  v_expires_at TIMESTAMP WITH TIME ZONE;
  v_used BOOLEAN;
BEGIN
  SELECT pt.email, pt.token_expires_at, pt.token_used
  INTO v_email, v_expires_at, v_used
  FROM public.permitted_teachers pt
  WHERE pt.token = p_token;

  IF v_email IS NULL THEN
    RETURN QUERY SELECT NULL::TEXT, FALSE, 'invalid'::TEXT;
  ELSIF v_used THEN
    RETURN QUERY SELECT v_email, FALSE, 'used'::TEXT;
  ELSIF v_expires_at < now() THEN
    RETURN QUERY SELECT v_email, FALSE, 'expired'::TEXT;
  ELSE
    RETURN QUERY SELECT v_email, TRUE, NULL::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create RPC to use/invalidate invitation token
CREATE OR REPLACE FUNCTION public.use_invitation_token(p_token UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.permitted_teachers
  SET token_used = TRUE
  WHERE token = p_token;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

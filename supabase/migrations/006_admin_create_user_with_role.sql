-- ─── SEASAME Assist-Pro — Admin create user with Role ──────────────────────────
-- Problem: The admin needs to set the role when creating the user, and the user
-- must have an identity row to log in.
--
-- Run this in: Supabase Dashboard → SQL Editor → New query → Run
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_create_user(
  user_email    TEXT,
  user_password TEXT,
  user_role     TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- ── Guard: only admins may call this ──────────────────────────────────────────
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Forbidden: caller is not an admin';
  END IF;

  -- ── Basic validation ──────────────────────────────────────────────────────────
  IF user_email IS NULL OR trim(user_email) = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;
  IF user_password IS NULL OR length(trim(user_password)) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;
  IF user_role IS NULL OR trim(user_role) = '' THEN
    RAISE EXCEPTION 'Role is required';
  END IF;

  -- ── Check for duplicate email ─────────────────────────────────────────────────
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(trim(user_email))) THEN
    RAISE EXCEPTION 'A user with this email already exists';
  END IF;

  new_user_id := gen_random_uuid();

  -- ── 1. Insert into auth.users ─────────────────────────────────────────────────
  -- Set raw_user_meta_data to include the role, so the trigger picks it up!
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,   -- mark confirmed so user can log in immediately
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role,
    aud
  ) VALUES (
    new_user_id,
    lower(trim(user_email)),
    crypt(user_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('role', user_role),
    FALSE,
    'authenticated',
    'authenticated'
  );

  -- ── 2. Insert into auth.identities ───────────────────────────────────────────
  -- REQUIRED for email/password login to work!
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    new_user_id,
    lower(trim(user_email)),
    jsonb_build_object(
      'sub',   new_user_id::text,
      'email', lower(trim(user_email))
    ),
    'email',
    NOW(),
    NOW(),
    NOW()
  );

  -- ── 3. Profile row ────────────────────────────────────────────────────────────
  -- The trigger trg_on_auth_user_created (handle_new_user) on auth.users
  -- already inserts a profile row automatically because of the trigger.
  -- This explicit insert ensures the role is definitely applied.
  INSERT INTO public.profiles (id, role, created_at, updated_at)
  VALUES (new_user_id, user_role::public.user_role, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;

  RETURN new_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT, TEXT) TO authenticated;

-- Also we drop the old version of the function that took 2 arguments
DROP FUNCTION IF EXISTS public.admin_create_user(TEXT, TEXT);

-- ─── Repair existing broken users again ───────────────────────────────────────
-- Back-fills the missing auth.identities rows for any existing user created without one.
INSERT INTO auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  gen_random_uuid(),
  u.id,
  u.email,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.created_at,
  u.created_at,
  u.updated_at
FROM auth.users u
WHERE
  EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = u.id AND i.provider = 'email'
  )
ON CONFLICT DO NOTHING;

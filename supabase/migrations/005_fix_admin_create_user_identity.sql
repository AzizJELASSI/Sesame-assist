-- ─── SEASAME Assist-Pro — Fix admin_create_user (add auth.identities) ──────────
-- Problem: migration 004 inserted into auth.users but NOT auth.identities.
-- Supabase email/password login requires a matching row in auth.identities
-- (provider = 'email').  Without it the user exists in the DB but cannot log in.
--
-- Run this in: Supabase Dashboard → SQL Editor → New query → Run
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_create_user(
  user_email    TEXT,
  user_password TEXT
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

  -- ── Check for duplicate email ─────────────────────────────────────────────────
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(trim(user_email))) THEN
    RAISE EXCEPTION 'A user with this email already exists';
  END IF;

  new_user_id := gen_random_uuid();

  -- ── 1. Insert into auth.users ─────────────────────────────────────────────────
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
    '{}'::jsonb,
    FALSE,
    'authenticated',
    'authenticated'
  );

  -- ── 2. Insert into auth.identities ───────────────────────────────────────────
  -- This is the row that Supabase's GoTrue uses to resolve email+password login.
  -- Without it the encrypted_password above is never checked during sign-in.
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
    lower(trim(user_email)),   -- for email provider, provider_id = email
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
  -- already inserts a profile row automatically after step 1.
  -- This explicit insert is a safety net in case the trigger is missing.
  INSERT INTO public.profiles (id, role, created_at, updated_at)
  VALUES (new_user_id, 'student', NOW(), NOW())
  ON CONFLICT (id) DO NOTHING;

  RETURN new_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT) TO authenticated;


-- ─── Also fix admin_delete_user: rely on CASCADE instead of manual deletes ─────
-- auth.identities.user_id → auth.users.id ON DELETE CASCADE
-- public.profiles.id      → auth.users.id ON DELETE CASCADE
-- So deleting from auth.users is enough; everything cascades automatically.

CREATE OR REPLACE FUNCTION public.admin_delete_user(
  target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Guard: only admins may call this
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Forbidden: caller is not an admin';
  END IF;

  -- Prevent self-deletion
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Admins cannot delete their own account';
  END IF;

  -- Deleting from auth.users cascades to:
  --   • auth.identities  (user_id FK → auth.users.id CASCADE)
  --   • public.profiles  (id FK → auth.users.id CASCADE)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_delete_user(UUID) TO authenticated;


-- ─── Repair existing broken users ─────────────────────────────────────────────
-- If you already have profiles rows whose auth.users counterpart was created
-- without an identity row, this block back-fills the missing auth.identities rows.
-- Safe to run even if identities already exist (ON CONFLICT DO NOTHING).

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
  -- only users that have a profile (i.e. created by our RPC)
  EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
  -- but are missing their identity row
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = u.id AND i.provider = 'email'
  )
ON CONFLICT DO NOTHING;

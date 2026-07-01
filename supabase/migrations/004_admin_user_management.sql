-- ─── SEASAME Assist-Pro — Admin User Management RPCs ──────────────────────────
-- Run this migration in the Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- These SECURITY DEFINER functions run with elevated privileges so the Flutter
-- client (using the anon key) can create / delete auth users when the caller is
-- an admin profile.

-- ── 1. Create a new Supabase Auth user ────────────────────────────────────────
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
  -- Guard: only admins may call this
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Forbidden: caller is not an admin';
  END IF;

  -- Validate inputs
  IF user_email IS NULL OR trim(user_email) = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;
  IF user_password IS NULL OR length(trim(user_password)) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
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
    NOW(),           -- mark email as already confirmed
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    FALSE,
    'authenticated',
    'authenticated'
  );

  -- The existing handle_new_user trigger will insert a profile row automatically.
  -- If your project does NOT have that trigger, uncomment the block below:
  --
  -- INSERT INTO public.profiles (id, role, created_at, updated_at)
  -- VALUES (new_user_id, 'student', NOW(), NOW())
  -- ON CONFLICT (id) DO NOTHING;

  RETURN new_user_id;
END;
$$;

-- Grant execute to authenticated users (the guard above limits actual use to admins)
GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT) TO authenticated;


-- ── 2. Delete a Supabase Auth user ────────────────────────────────────────────
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

  -- Delete from auth.users; profile row will cascade if FK is set up, otherwise:
  DELETE FROM public.profiles WHERE id = target_user_id;
  DELETE FROM auth.users     WHERE id = target_user_id;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.admin_delete_user(UUID) TO authenticated;


-- ── 3. (Optional) Ensure the handle_new_user trigger exists ───────────────────
-- If your DB already has this trigger from migration 001, skip this block.
-- It creates a minimal profile row whenever a new auth user is inserted.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, created_at, updated_at)
  VALUES (NEW.id, 'student', NOW(), NOW())
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Only create the trigger if it doesn't already exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
END;
$$;

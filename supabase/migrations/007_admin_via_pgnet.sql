-- ─── SEASAME Assist-Pro — Admin User Management via pg_net ────────────────────
-- WHY THIS APPROACH:
--   All previous approaches failed on Flutter Web because:
--   - Direct auth.users INSERT: blocked by Supabase (GoTrue owns that schema)
--   - SDK admin client: blocked ("Forbidden use of secret API key in browser")
--   - Raw http package: still blocked (browser XMLHttpRequest adds Origin header)
--
--   Solution: PostgreSQL calls the GoTrue Admin REST API via pg_net.
--   pg_net runs on the database SERVER, not in a browser → GoTrue accepts the
--   service-role key with no restriction whatsoever.
--
-- HOW TO APPLY:
--   Supabase Dashboard → SQL Editor → New query → paste → Run
-- ──────────────────────────────────────────────────────────────────────────────

-- Make sure the pg_net extension is enabled (it is by default on Supabase)
CREATE EXTENSION IF NOT EXISTS pg_net;


-- ── 1. Create a Supabase Auth user ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_create_user(
  user_email    TEXT,
  user_password TEXT,
  user_role     TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  request_id   BIGINT;
  result       net.http_response_result;
  response_json JSONB;
  new_user_id  UUID;
BEGIN
  -- ── Guard: only admins may call this ────────────────────────────────────────
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Forbidden: caller is not an admin';
  END IF;

  IF coalesce(trim(user_email), '') = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;
  IF length(coalesce(user_password, '')) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  -- ── POST to GoTrue Admin API (server-side → no browser restriction) ─────────
  SELECT net.http_post(
    url     := 'https://your-project.supabase.co/auth/v1/admin/users',
    headers := jsonb_build_object(
                 'Content-Type',  'application/json',
                 'Authorization', 'Bearer YOUR_SUPABASE_SERVICE_ROLE_KEY',
                 'apikey',        'YOUR_SUPABASE_SERVICE_ROLE_KEY'
               ),
    body := jsonb_build_object(
                 'email',         lower(trim(user_email)),
                 'password',      user_password,
                 'email_confirm', true,
                 'user_metadata', jsonb_build_object('role', user_role)
               ),
    timeout_milliseconds := 15000
  ) INTO request_id;

  -- ── Block until the HTTP response arrives ──────────────────────────────────
  result := net.http_collect_response(request_id, async := false);

  IF result.status = 'ERROR' THEN
    RAISE EXCEPTION 'Network error creating user: %', result.message;
  END IF;

  IF (result.response).status_code NOT IN (200, 201) THEN
    RAISE EXCEPTION 'GoTrue error: %', (result.response).body;
  END IF;

  -- ── Parse the returned user ID ─────────────────────────────────────────────
  response_json := ((result.response).body)::JSONB;
  new_user_id   := (response_json->>'id')::UUID;

  -- ── Ensure profile row exists with the right role ──────────────────────────
  -- (The handle_new_user trigger should have created it already, but just in case)
  INSERT INTO public.profiles (id, role, created_at, updated_at)
  VALUES (new_user_id, user_role::public.user_role, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;

  RETURN new_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT, TEXT) TO authenticated;

-- Drop old 2-argument version from migration 004 if it still exists
DROP FUNCTION IF EXISTS public.admin_create_user(TEXT, TEXT);


-- ── 2. Delete a Supabase Auth user ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_delete_user(
  target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  request_id BIGINT;
  result     net.http_response_result;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Forbidden: caller is not an admin';
  END IF;

  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Admins cannot delete their own account';
  END IF;

  SELECT net.http_delete(
    url     := 'https://your-project.supabase.co/auth/v1/admin/users/'
               || target_user_id::text,
    headers := jsonb_build_object(
                 'Content-Type',  'application/json',
                 'Authorization', 'Bearer YOUR_SUPABASE_SERVICE_ROLE_KEY',
                 'apikey',        'YOUR_SUPABASE_SERVICE_ROLE_KEY'
               ),
    timeout_milliseconds := 10000
  ) INTO request_id;

  result := net.http_collect_response(request_id, async := false);

  IF result.status = 'ERROR' THEN
    RAISE EXCEPTION 'Network error deleting user: %', result.message;
  END IF;

  IF (result.response).status_code NOT IN (200, 204) THEN
    RAISE EXCEPTION 'GoTrue error: %', (result.response).body;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_delete_user(UUID) TO authenticated;

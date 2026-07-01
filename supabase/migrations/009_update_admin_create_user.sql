-- ─── SEASAME Assist-Pro — Update Admin Create User ──────────────────────────────
-- Add optional full_name and department_id arguments to admin_create_user so the 
-- admin can optionally fill them out during creation.
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_create_user(
  user_email         TEXT,
  user_password      TEXT,
  user_role          TEXT,
  user_full_name     TEXT DEFAULT NULL,
  user_department_id TEXT DEFAULT NULL
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
                 'user_metadata', jsonb_build_object(
                     'role', user_role,
                     'full_name', user_full_name,
                     'department_id', user_department_id
                 )
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

  -- ── Ensure profile row exists with the right role, name, and department ────
  -- (The handle_new_user trigger should have created it already, but just in case)
  INSERT INTO public.profiles (id, role, full_name, department_id, created_at, updated_at)
  VALUES (new_user_id, user_role::public.user_role, user_full_name, user_department_id, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET 
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    department_id = EXCLUDED.department_id;

  RETURN new_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_create_user(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Drop old 3-argument version so it's clean
DROP FUNCTION IF EXISTS public.admin_create_user(TEXT, TEXT, TEXT);

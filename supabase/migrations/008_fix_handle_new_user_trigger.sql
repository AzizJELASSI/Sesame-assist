-- ─── SEASAME Assist-Pro — Fix handle_new_user trigger ─────────────────────────
-- Problem: The handle_new_user trigger does:
--   COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'student')
--
-- In PostgreSQL, the cast happens BEFORE COALESCE evaluates.  If the value is
-- NULL or an unrecognised string, the cast itself raises an exception — GoTrue
-- catches it as "Database error checking email" (a 500 that bubbles up).
--
-- Fix: Use a CASE expression to guard the cast, plus a top-level EXCEPTION
-- block so the trigger NEVER aborts user creation.
--
-- Apply in: Supabase Dashboard → SQL Editor → New query → Run
-- ──────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _role      public.user_role := 'student';
  _full_name TEXT             := NULL;
  _raw_role  TEXT;
BEGIN
  -- Read raw values from metadata
  _full_name := NEW.raw_user_meta_data->>'full_name';
  _raw_role  := NEW.raw_user_meta_data->>'role';

  -- Safe cast: only attempt cast when value is a known enum member
  -- Casting NULL or an unknown string directly to an enum raises an error in PG,
  -- so we guard with CASE before the cast.
  IF _raw_role IN ('student', 'teacher', 'agent', 'admin') THEN
    _role := _raw_role::public.user_role;
  END IF;

  INSERT INTO public.profiles (id, full_name, role, created_at, updated_at)
  VALUES (NEW.id, _full_name, _role, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE
    SET
      full_name  = EXCLUDED.full_name,
      role       = EXCLUDED.role,
      updated_at = NOW()
    WHERE
      -- only update role if the existing row still has the default 'student'
      -- (avoids overwriting an admin-set role on re-trigger)
      public.profiles.role = 'student';

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Log the error but do NOT re-raise it.
  -- Aborting the trigger would abort the auth.users INSERT and GoTrue reports
  -- this as "Database error checking email" — a very confusing 500.
  -- The profile can be repaired later; the auth user must be created.
  RAISE WARNING '[handle_new_user] Could not create profile for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- The trigger itself does not need to be recreated — it already exists and
-- points to this function.  Just replacing the function body is sufficient.
-- (Running CREATE OR REPLACE FUNCTION is safe and idempotent.)

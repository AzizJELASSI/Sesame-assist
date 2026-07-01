-- ============================================================
-- Migration 003: Replace department_enum with full school structure
--                and drop filiere_enum
-- ============================================================

-- ── 0. Drop RLS policies that depend on get_my_department() ──────────────────
DROP POLICY IF EXISTS "Tickets: agents can read department tickets"  ON public.tickets;
DROP POLICY IF EXISTS "Tickets: agents can update department tickets" ON public.tickets;
DROP POLICY IF EXISTS "Comments: agents read all comments in department" ON public.ticket_comments;

-- ── 1. Drop dependent function ────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_my_department();

-- ── 2. Drop NOT NULL constraints so we can safely null out stale enum values ──
ALTER TABLE public.tickets  ALTER COLUMN department_id DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN department_id DROP NOT NULL;

-- ── 3. Convert enum columns to TEXT (nulling existing values) ─────────────────
--      profiles
ALTER TABLE public.profiles
  ALTER COLUMN department_id TYPE TEXT USING NULL;

ALTER TABLE public.profiles
  ALTER COLUMN filiere_id TYPE TEXT USING NULL;

--      tickets
ALTER TABLE public.tickets
  ALTER COLUMN department_id TYPE TEXT USING NULL;

ALTER TABLE public.tickets
  ALTER COLUMN filiere_id TYPE TEXT USING NULL;

-- ── 4. Drop old enum types ────────────────────────────────────────────────────
DROP TYPE IF EXISTS public.department_enum;
DROP TYPE IF EXISTS public.filiere_enum;

-- ── 5. Create new department enum with all 11 units/departments ───────────────
CREATE TYPE public.department_enum AS ENUM (
  'uniteIT',
  'uniteFinance',
  'uniteStage',
  'uniteScolarite',
  'uniteMarketing',
  'uniteRH',
  'uniteCertification',
  'deptBusiness',
  'deptINGPREPA',
  'deptTA',
  'deptLIM'
);

-- ── 6. Grant usage to anon & authenticated ────────────────────────────────────
GRANT USAGE ON TYPE public.department_enum TO anon, authenticated;

-- ── 7. Convert department_id columns to the new enum (nullable) ──────────────
ALTER TABLE public.profiles
  ALTER COLUMN department_id TYPE public.department_enum
    USING department_id::public.department_enum;

ALTER TABLE public.tickets
  ALTER COLUMN department_id TYPE public.department_enum
    USING department_id::public.department_enum;

-- ── 8. Drop filiere_id columns (no longer needed) ────────────────────────────
ALTER TABLE public.profiles DROP COLUMN IF EXISTS filiere_id;
ALTER TABLE public.tickets  DROP COLUMN IF EXISTS filiere_id;

-- ── 9. Recreate get_my_department() ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_department()
RETURNS public.department_enum LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT department_id FROM public.profiles WHERE id = auth.uid();
$$;

-- ── 10. Recreate dependent RLS policies ──────────────────────────────────────
CREATE POLICY "Tickets: agents can read department tickets"
  ON public.tickets FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'agent'
    AND department_id = public.get_my_department()
  );

CREATE POLICY "Tickets: agents can update department tickets"
  ON public.tickets FOR UPDATE
  TO authenticated
  USING (
    public.get_my_role() = 'agent'
    AND department_id = public.get_my_department()
  )
  WITH CHECK (
    public.get_my_role() = 'agent'
    AND department_id = public.get_my_department()
  );

CREATE POLICY "Comments: agents read all comments in department"
  ON public.ticket_comments FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'agent'
    AND ticket_id IN (
      SELECT id FROM public.tickets
      WHERE department_id = public.get_my_department()
    )
  );

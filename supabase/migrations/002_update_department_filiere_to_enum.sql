-- ============================================================
-- Migration: Update department_id and filiere_id to PostgreSQL Enums
-- ============================================================

-- 0. Drop dependent RLS policies first
DROP POLICY IF EXISTS "Tickets: agents can read department tickets" ON public.tickets;
DROP POLICY IF EXISTS "Tickets: agents can update department tickets" ON public.tickets;
DROP POLICY IF EXISTS "Comments: agents read all comments in department" ON public.ticket_comments;

-- 1. Drop the views or functions that depend on the column type.
-- The function get_my_department returns UUID currently.
DROP FUNCTION IF EXISTS public.get_my_department();

-- 2. Drop the existing tables with CASCADE to automatically drop 
-- the foreign key constraints from `profiles` and `tickets`.
DROP TABLE IF EXISTS public.filieres CASCADE;
DROP TABLE IF EXISTS public.departments CASCADE;

-- 3. Create the new ENUM types
CREATE TYPE public.department_enum AS ENUM (
  'it',
  'management'
);

CREATE TYPE public.filiere_enum AS ENUM (
  'softwareEngineering',
  'dataScience',
  'networks',
  'businessAdministration',
  'marketing'
);

-- IMPORTANT: Grant usage on the new types to anon and authenticated roles
-- Without this, Supabase will throw a "permission denied for schema public" error!
GRANT USAGE ON TYPE public.department_enum TO anon, authenticated;
GRANT USAGE ON TYPE public.filiere_enum TO anon, authenticated;

-- 4. Alter the columns in `profiles` to be of the new ENUM type
ALTER TABLE public.profiles
  ALTER COLUMN department_id TYPE public.department_enum USING NULL,
  ALTER COLUMN filiere_id TYPE public.filiere_enum USING NULL;

-- 5. Alter the columns in `tickets` to be of the new ENUM type
ALTER TABLE public.tickets
  ALTER COLUMN department_id TYPE public.department_enum USING NULL,
  ALTER COLUMN filiere_id TYPE public.filiere_enum USING NULL;

-- 6. Recreate the get_my_department function with the new ENUM return type
CREATE OR REPLACE FUNCTION public.get_my_department()
RETURNS public.department_enum LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT department_id FROM public.profiles WHERE id = auth.uid();
$$;

-- 7. Recreate the dependent RLS policies

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

-- 011_ticket_role_adjustments.sql

-- 1. Restrict ticket creation to only student and teacher roles
DROP POLICY IF EXISTS "Tickets: students & teachers can insert" ON public.tickets;

CREATE POLICY "Tickets: students & teachers can insert"
  ON public.tickets FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = auth.uid()
    AND public.get_my_role() IN ('student', 'teacher')
  );

-- 2. Allow agents to read all tickets (remove department restriction)
DROP POLICY IF EXISTS "Tickets: agents can read department tickets" ON public.tickets;

CREATE POLICY "Tickets: agents can read all tickets"
  ON public.tickets FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() = 'agent'
  );

-- 3. Allow agents to update all tickets (remove department restriction)
DROP POLICY IF EXISTS "Tickets: agents can update department tickets" ON public.tickets;

CREATE POLICY "Tickets: agents can update all tickets"
  ON public.tickets FOR UPDATE
  TO authenticated
  USING (
    public.get_my_role() = 'agent'
  )
  WITH CHECK (
    public.get_my_role() = 'agent'
  );

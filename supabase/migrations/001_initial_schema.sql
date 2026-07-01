-- ============================================================
-- SEASAME Assist-Pro — Initial Schema
-- Phase 1: Tables, Enums, Triggers, RLS Policies
-- ============================================================

-- ─── Extensions ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for fuzzy text search on tickets

-- ─── Custom Enums ────────────────────────────────────────────
CREATE TYPE public.user_role AS ENUM (
  'student',
  'teacher',
  'agent',
  'admin'
);

CREATE TYPE public.ticket_priority AS ENUM (
  'low',
  'medium',
  'high'
);

CREATE TYPE public.ticket_status AS ENUM (
  'open',
  'in_progress',
  'waiting_on_user',
  'resolved',
  'closed'
);

-- ─── Table: departments ──────────────────────────────────────
CREATE TABLE public.departments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  code        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Table: filieres ─────────────────────────────────────────
CREATE TABLE public.filieres (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name           TEXT NOT NULL,
  program_type   TEXT NOT NULL,         -- e.g. 'licence', 'master', 'doctorat'
  department_id  UUID NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Table: profiles ─────────────────────────────────────────
-- Mirrors auth.users; populated via trigger on signup
CREATE TABLE public.profiles (
  id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name      TEXT,
  role           public.user_role NOT NULL DEFAULT 'student',
  department_id  UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  filiere_id     UUID REFERENCES public.filieres(id) ON DELETE SET NULL,
  avatar_url     TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Table: tickets ──────────────────────────────────────────
CREATE TABLE public.tickets (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title          TEXT NOT NULL,
  description    TEXT NOT NULL,
  ticket_type    TEXT NOT NULL,         -- e.g. 'it_issue', 'hr_request', 'facility', 'academic'
  priority       public.ticket_priority NOT NULL DEFAULT 'medium',
  status         public.ticket_status NOT NULL DEFAULT 'open',
  created_by     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_to    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  department_id  UUID NOT NULL REFERENCES public.departments(id) ON DELETE RESTRICT,
  filiere_id     UUID REFERENCES public.filieres(id) ON DELETE SET NULL,
  resolved_at    TIMESTAMPTZ,
  ai_draft       JSONB,                 -- stores the raw AI-generated draft payload
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Table: ticket_comments ──────────────────────────────────
CREATE TABLE public.ticket_comments (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id    UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  author_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content      TEXT NOT NULL,
  is_internal  BOOLEAN NOT NULL DEFAULT FALSE, -- TRUE = agent/admin only
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Table: ticket_attachments ───────────────────────────────
CREATE TABLE public.ticket_attachments (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id    UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  uploaded_by  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  file_name    TEXT NOT NULL,
  file_path    TEXT NOT NULL,           -- Supabase Storage path
  mime_type    TEXT,
  file_size    BIGINT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Indexes ─────────────────────────────────────────────────
CREATE INDEX idx_tickets_created_by     ON public.tickets(created_by);
CREATE INDEX idx_tickets_department_id  ON public.tickets(department_id);
CREATE INDEX idx_tickets_status         ON public.tickets(status);
CREATE INDEX idx_tickets_priority       ON public.tickets(priority);
CREATE INDEX idx_comments_ticket_id     ON public.ticket_comments(ticket_id);
CREATE INDEX idx_profiles_role          ON public.profiles(role);
CREATE INDEX idx_profiles_department    ON public.profiles(department_id);

-- Full-text search index on ticket title/description
CREATE INDEX idx_tickets_fts ON public.tickets
  USING GIN (to_tsvector('simple', title || ' ' || description));

-- ─── Trigger: updated_at auto-update ─────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_tickets_updated_at
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Trigger: auto-resolve timestamp ─────────────────────────
CREATE OR REPLACE FUNCTION public.handle_ticket_resolved()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IN ('resolved', 'closed') AND OLD.status NOT IN ('resolved', 'closed') THEN
    NEW.resolved_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ticket_resolved_at
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION public.handle_ticket_resolved();

-- ─── Trigger: create profile on auth.users signup ────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    COALESCE((NEW.raw_user_meta_data ->> 'role')::public.user_role, 'student')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── Helper function: get current user role ──────────────────
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_my_department()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT department_id FROM public.profiles WHERE id = auth.uid();
$$;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.departments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.filieres            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_comments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_attachments  ENABLE ROW LEVEL SECURITY;

-- ─── departments: read-only for all authenticated users ──────
CREATE POLICY "Departments: read by all authenticated"
  ON public.departments FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Departments: full control by admin"
  ON public.departments FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- ─── filieres: read-only for all authenticated users ─────────
CREATE POLICY "Filieres: read by all authenticated"
  ON public.filieres FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Filieres: full control by admin"
  ON public.filieres FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- ─── profiles ─────────────────────────────────────────────────
CREATE POLICY "Profiles: users can read own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Profiles: users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Profiles: agents can read profiles in their department"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    public.get_my_role() IN ('agent', 'admin')
    OR id = auth.uid()
  );

CREATE POLICY "Profiles: admin full control"
  ON public.profiles FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- ─── tickets ──────────────────────────────────────────────────
-- Students/Teachers: see only their own tickets
CREATE POLICY "Tickets: creator can read own"
  ON public.tickets FOR SELECT
  TO authenticated
  USING (
    created_by = auth.uid()
    OR public.get_my_role() IN ('agent', 'admin')
  );

CREATE POLICY "Tickets: students & teachers can insert"
  ON public.tickets FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = auth.uid()
    AND public.get_my_role() IN ('student', 'teacher', 'agent', 'admin')
  );

CREATE POLICY "Tickets: creator can update own (limited fields)"
  ON public.tickets FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid() AND status NOT IN ('resolved', 'closed'))
  WITH CHECK (created_by = auth.uid());

-- Agents: see & update tickets in their department
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

-- Admin: unrestricted
CREATE POLICY "Tickets: admin full control"
  ON public.tickets FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- ─── ticket_comments ──────────────────────────────────────────
-- Students/Teachers: read only non-internal comments on own tickets
CREATE POLICY "Comments: creator reads public comments on own tickets"
  ON public.ticket_comments FOR SELECT
  TO authenticated
  USING (
    is_internal = FALSE
    AND ticket_id IN (
      SELECT id FROM public.tickets WHERE created_by = auth.uid()
    )
  );

-- Students/Teachers: insert public comments on own tickets
CREATE POLICY "Comments: creator inserts public comment"
  ON public.ticket_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND is_internal = FALSE
    AND ticket_id IN (
      SELECT id FROM public.tickets WHERE created_by = auth.uid()
    )
  );

-- Agents: read all comments (public + internal) for their department tickets
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

-- Agents: insert any comment (including internal) for their department tickets
CREATE POLICY "Comments: agents insert comments"
  ON public.ticket_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND public.get_my_role() IN ('agent', 'admin')
  );

-- Admin: unrestricted
CREATE POLICY "Comments: admin full control"
  ON public.ticket_comments FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- ─── ticket_attachments ───────────────────────────────────────
CREATE POLICY "Attachments: ticket owner and agents can read"
  ON public.ticket_attachments FOR SELECT
  TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR public.get_my_role() IN ('agent', 'admin')
  );

CREATE POLICY "Attachments: authenticated users can upload"
  ON public.ticket_attachments FOR INSERT
  TO authenticated
  WITH CHECK (uploaded_by = auth.uid());

CREATE POLICY "Attachments: admin full control"
  ON public.ticket_attachments FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

-- ============================================================
-- SEED DATA: Sample Departments & Filieres
-- ============================================================

INSERT INTO public.departments (name, code) VALUES
  ('Computer Science & IT',         'CS'),
  ('Mathematics & Physics',         'MP'),
  ('Business Administration',       'BA'),
  ('Language & Humanities',         'LH'),
  ('Student Affairs & HR',          'HR'),
  ('Facilities & Infrastructure',   'FAC');

INSERT INTO public.filieres (name, program_type, department_id) VALUES
  ('Software Engineering',       'licence',   (SELECT id FROM public.departments WHERE code = 'CS')),
  ('Artificial Intelligence',    'master',    (SELECT id FROM public.departments WHERE code = 'CS')),
  ('Cybersecurity',              'master',    (SELECT id FROM public.departments WHERE code = 'CS')),
  ('Applied Mathematics',        'licence',   (SELECT id FROM public.departments WHERE code = 'MP')),
  ('Data Science',               'master',    (SELECT id FROM public.departments WHERE code = 'MP')),
  ('Marketing',                  'licence',   (SELECT id FROM public.departments WHERE code = 'BA')),
  ('Finance & Accounting',       'master',    (SELECT id FROM public.departments WHERE code = 'BA')),
  ('English Studies',            'licence',   (SELECT id FROM public.departments WHERE code = 'LH')),
  ('French Studies',             'licence',   (SELECT id FROM public.departments WHERE code = 'LH'));

-- ============================================================
-- SEASAME Assist-Pro — SLA Policies
-- Migration 010: sla_policies table + SLA columns on tickets
-- Business hours: Mon-Fri 08:00-18:00 (UTC+1 / local)
-- SLA clock pauses when ticket is in 'waiting_on_user'
-- One policy per priority level (low / medium / high)
-- ============================================================

-- ─── Table: sla_policies ─────────────────────────────────────
CREATE TABLE public.sla_policies (
  id                UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
  priority          public.ticket_priority NOT NULL UNIQUE,
  response_time_h   INTEGER NOT NULL DEFAULT 4,    -- business hours to first response
  resolution_time_h INTEGER NOT NULL DEFAULT 24,   -- business hours to resolution
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE TRIGGER trg_sla_policies_updated_at
  BEFORE UPDATE ON public.sla_policies
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── Seed defaults ────────────────────────────────────────────
INSERT INTO public.sla_policies (priority, response_time_h, resolution_time_h) VALUES
  ('low',    8,  72),
  ('medium', 4,  24),
  ('high',   1,   8);

-- ─── Add SLA columns to tickets ──────────────────────────────
-- Deadlines are stored as absolute UTC timestamps computed by
-- the Flutter client (business-hours aware) at ticket creation.
ALTER TABLE public.tickets
  ADD COLUMN IF NOT EXISTS sla_response_due_at    TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS sla_resolution_due_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS sla_breached           BOOLEAN NOT NULL DEFAULT FALSE,
  -- Tracks when the ticket entered 'waiting_on_user'; NULL = not paused
  ADD COLUMN IF NOT EXISTS sla_paused_at          TIMESTAMPTZ;

-- ─── Indexes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tickets_sla_resolution_due
  ON public.tickets(sla_resolution_due_at)
  WHERE sla_breached = FALSE AND status NOT IN ('resolved', 'closed');

-- ─── Trigger: auto-extend deadlines when pause ends ──────────
-- When a ticket leaves 'waiting_on_user', extend both SLA
-- deadlines by the wall-clock pause duration (seconds).
-- The Flutter client does the business-hours aware calculation
-- for the initial deadline; extensions use wall-clock so the
-- raw pause time is always compensated.
CREATE OR REPLACE FUNCTION public.handle_sla_pause()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  pause_seconds FLOAT;
  pause_interval INTERVAL;
BEGIN
  -- Ticket is entering 'waiting_on_user' → record pause start
  IF NEW.status = 'waiting_on_user' AND OLD.status <> 'waiting_on_user' THEN
    NEW.sla_paused_at = NOW();
  END IF;

  -- Ticket is leaving 'waiting_on_user' → extend deadlines & clear pause
  IF OLD.status = 'waiting_on_user' AND NEW.status <> 'waiting_on_user' THEN
    IF OLD.sla_paused_at IS NOT NULL THEN
      pause_seconds  := EXTRACT(EPOCH FROM (NOW() - OLD.sla_paused_at));
      pause_interval := make_interval(secs => pause_seconds);

      IF NEW.sla_response_due_at IS NOT NULL THEN
        NEW.sla_response_due_at := NEW.sla_response_due_at + pause_interval;
      END IF;
      IF NEW.sla_resolution_due_at IS NOT NULL THEN
        NEW.sla_resolution_due_at := NEW.sla_resolution_due_at + pause_interval;
      END IF;
    END IF;
    NEW.sla_paused_at = NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sla_pause
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION public.handle_sla_pause();

-- ─── Trigger: mark sla_breached when resolved late ───────────
CREATE OR REPLACE FUNCTION public.handle_sla_breach_on_resolve()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IN ('resolved', 'closed')
     AND OLD.status NOT IN ('resolved', 'closed')
     AND NEW.sla_resolution_due_at IS NOT NULL
     AND NOW() > NEW.sla_resolution_due_at THEN
    NEW.sla_breached := TRUE;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sla_breach_on_resolve
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE FUNCTION public.handle_sla_breach_on_resolve();

-- ─── RLS: sla_policies ───────────────────────────────────────
ALTER TABLE public.sla_policies ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read SLA policies (needed for client-side deadline calc)
CREATE POLICY "SLA Policies: read by all authenticated"
  ON public.sla_policies FOR SELECT
  TO authenticated
  USING (TRUE);

-- Only admins can create/update/delete policies
CREATE POLICY "SLA Policies: admin full control"
  ON public.sla_policies FOR ALL
  TO authenticated
  USING (public.get_my_role() = 'admin')
  WITH CHECK (public.get_my_role() = 'admin');

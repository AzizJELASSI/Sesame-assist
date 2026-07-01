-- 002_ticket_attachments.sql
-- Migration to add ticket attachments table and storage bucket configuration

create extension if not exists "uuid-ossp";

create table if not exists ticket_attachments (
  id uuid primary key default uuid_generate_v4(),
  ticket_id uuid not null references tickets(id) on delete cascade,
  file_path text not null,
  uploaded_at timestamptz not null default now()
);

-- RLS: allow owners, agents, admins to select/download
alter table ticket_attachments enable row level security;

create policy "allow_all_read" on ticket_attachments
  for select
  using (
    auth.role() = 'admin'
    or (select department_id from tickets where tickets.id = ticket_attachments.ticket_id) = (select department_id from profiles where profiles.id = auth.uid())
    or auth.uid() = (select created_by from tickets where tickets.id = ticket_attachments.ticket_id)
  );

create policy "allow_owner_insert" on ticket_attachments
  for insert
  with check (
    auth.uid() = (select created_by from tickets where tickets.id = ticket_id)
  );

-- Note: Storage bucket `ticket-attachments` should be created in Supabase dashboard.

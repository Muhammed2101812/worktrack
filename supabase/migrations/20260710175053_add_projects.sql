-- Add projects table and project fields on work_entries
create table if not exists projects (
  id text primary key,
  client_id text,
  name text not null,
  description text default '',
  status text default 'active',
  created_at text not null
);

-- Add project fields to work_entries (idempotent)
alter table work_entries add column if not exists project_id text;
alter table work_entries add column if not exists project_name text;

-- Enable RLS and allow authenticated users full access
alter table projects enable row level security;

create policy "Authenticated full access to projects"
  on projects for all
  to authenticated
  using (true)
  with check (true);

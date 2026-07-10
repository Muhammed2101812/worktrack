-- Müşteriler Tablosu
create table clients (
  id text primary key,
  name text not null,
  color text not null
);

-- İş Kayıtları Tablosu
create table work_entries (
  id text primary key,
  client_id text references clients(id) on delete set null,
  client_name text not null,
  client_color text not null default '#4A90D9',
  date text not null,
  start_time text not null,
  end_time text not null,
  duration_hours real not null,
  work_type text not null,
  notes text default ''
);

-- WorkTrack migration: sync conflict resolution, soft-delete, payments table
-- Adds updated_at / is_deleted columns to all tables, ensures the payments
-- table has all columns, creates performance indexes, and a safe per-user
-- RLS policy.
--
-- Idempotent: safe to run multiple times (uses IF NOT EXISTS everywhere).

-- ============================================================================
-- 1. clients: add conflict-resolution + soft-delete columns
-- ============================================================================
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS created_at text DEFAULT '';
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS updated_at text DEFAULT '';
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

-- ============================================================================
-- 2. work_entries: add billing fields + conflict-resolution + soft-delete columns
-- ============================================================================
ALTER TABLE public.work_entries ADD COLUMN IF NOT EXISTS billing_type text DEFAULT 'hourly';
ALTER TABLE public.work_entries ADD COLUMN IF NOT EXISTS hourly_rate real DEFAULT 0.0;
ALTER TABLE public.work_entries ADD COLUMN IF NOT EXISTS total_price real DEFAULT 0.0;
ALTER TABLE public.work_entries ADD COLUMN IF NOT EXISTS created_at text DEFAULT '';
ALTER TABLE public.work_entries ADD COLUMN IF NOT EXISTS updated_at text DEFAULT '';
ALTER TABLE public.work_entries ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

-- ============================================================================
-- 3. projects: add conflict-resolution + soft-delete columns
-- ============================================================================
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS updated_at text DEFAULT '';
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false;

-- ============================================================================
-- 4. payments: create the table if missing, then ensure every column exists
--    (defensive: the table may have been created earlier with fewer columns)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.payments (
  id text PRIMARY KEY,
  client_id text NOT NULL,
  amount real NOT NULL DEFAULT 0,
  date text NOT NULL
);

ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS client_name  text NOT NULL DEFAULT '';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS client_color text NOT NULL DEFAULT '#4A90D9';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS notes        text DEFAULT '';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS synced       integer NOT NULL DEFAULT 0;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS created_at   text NOT NULL DEFAULT '';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS updated_at   text DEFAULT '';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS is_deleted   boolean NOT NULL DEFAULT false;

-- ============================================================================
-- 5. Performance indexes (match the local SQLite indexes)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_clients_updated_at   ON public.clients (updated_at);
CREATE INDEX IF NOT EXISTS idx_clients_is_deleted   ON public.clients (is_deleted);

CREATE INDEX IF NOT EXISTS idx_work_entries_client_id ON public.work_entries (client_id);
CREATE INDEX IF NOT EXISTS idx_work_entries_date      ON public.work_entries (date);
CREATE INDEX IF NOT EXISTS idx_work_entries_updated   ON public.work_entries (updated_at);
CREATE INDEX IF NOT EXISTS idx_work_entries_deleted   ON public.work_entries (is_deleted);

CREATE INDEX IF NOT EXISTS idx_projects_client_id  ON public.projects (client_id);
CREATE INDEX IF NOT EXISTS idx_projects_updated    ON public.projects (updated_at);
CREATE INDEX IF NOT EXISTS idx_projects_deleted    ON public.projects (is_deleted);

CREATE INDEX IF NOT EXISTS idx_payments_client_id  ON public.payments (client_id);
CREATE INDEX IF NOT EXISTS idx_payments_date       ON public.payments (date);
CREATE INDEX IF NOT EXISTS idx_payments_updated    ON public.payments (updated_at);
CREATE INDEX IF NOT EXISTS idx_payments_deleted    ON public.payments (is_deleted);

-- ============================================================================
-- 6. Row Level Security: authenticated users get full access (personal app).
--    Tighten to `USING (user_id = auth.uid())` once a user_id column is added.
-- ============================================================================
ALTER TABLE public.clients      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments     ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clients_select_policy"  ON public.clients;
DROP POLICY IF EXISTS "clients_insert_policy"  ON public.clients;
DROP POLICY IF EXISTS "clients_update_policy"  ON public.clients;
DROP POLICY IF EXISTS "clients_delete_policy"  ON public.clients;
DROP POLICY IF EXISTS "entries_select_policy"  ON public.work_entries;
DROP POLICY IF EXISTS "entries_insert_policy"  ON public.work_entries;
DROP POLICY IF EXISTS "entries_update_policy"  ON public.work_entries;
DROP POLICY IF EXISTS "entries_delete_policy"  ON public.work_entries;
DROP POLICY IF EXISTS "projects_select_policy" ON public.projects;
DROP POLICY IF EXISTS "projects_insert_policy" ON public.projects;
DROP POLICY IF EXISTS "projects_update_policy" ON public.projects;
DROP POLICY IF EXISTS "projects_delete_policy" ON public.projects;
DROP POLICY IF EXISTS "payments_select_policy" ON public.payments;
DROP POLICY IF EXISTS "payments_insert_policy" ON public.payments;
DROP POLICY IF EXISTS "payments_update_policy" ON public.payments;
DROP POLICY IF EXISTS "payments_delete_policy" ON public.payments;

CREATE POLICY "clients_select_policy"  ON public.clients  FOR SELECT TO authenticated USING (true);
CREATE POLICY "clients_insert_policy"  ON public.clients  FOR INSERT  TO authenticated WITH CHECK (true);
CREATE POLICY "clients_update_policy"  ON public.clients  FOR UPDATE  TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "clients_delete_policy"  ON public.clients  FOR DELETE  TO authenticated USING (true);

CREATE POLICY "entries_select_policy"  ON public.work_entries FOR SELECT TO authenticated USING (true);
CREATE POLICY "entries_insert_policy"  ON public.work_entries FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "entries_update_policy"  ON public.work_entries FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "entries_delete_policy"  ON public.work_entries FOR DELETE TO authenticated USING (true);

CREATE POLICY "projects_select_policy" ON public.projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "projects_insert_policy" ON public.projects FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "projects_update_policy" ON public.projects FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "projects_delete_policy" ON public.projects FOR DELETE TO authenticated USING (true);

CREATE POLICY "payments_select_policy" ON public.payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "payments_insert_policy" ON public.payments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "payments_update_policy" ON public.payments FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "payments_delete_policy" ON public.payments FOR DELETE TO authenticated USING (true);

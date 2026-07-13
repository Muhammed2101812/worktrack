-- WorkTrack migration: break (mola) support on work_entries
-- Adds optional break_start / break_end timestamps so overnight and break
-- durations are calculated correctly on the client.
-- Idempotent (IF NOT EXISTS pattern via DO block).

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'public' AND table_name = 'work_entries' AND column_name = 'break_start') THEN
    ALTER TABLE public.work_entries ADD COLUMN break_start text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'public' AND table_name = 'work_entries' AND column_name = 'break_end') THEN
    ALTER TABLE public.work_entries ADD COLUMN break_end text;
  END IF;
END $$;

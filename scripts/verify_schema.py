#!/usr/bin/env python3
"""Verify the work_entries table schema on remote Supabase."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import psycopg2  # type: ignore
from apply_migration import load_env

root = Path(__file__).resolve().parent.parent
env = load_env(root / ".env")
supabase_url = env["SUPABASE_URL"].rstrip("/")
project_ref = supabase_url.replace("https://", "").split(".")[0]

conn = psycopg2.connect(
    host="aws-0-eu-central-1.pooler.supabase.com",
    port=5432,
    dbname="postgres",
    user=f"postgres.{project_ref}",
    password=env["SUPABASE_DB_PASSWORD"],
    sslmode="require",
)
with conn.cursor() as cur:
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'work_entries'
        ORDER BY ordinal_position;
    """)
    rows = cur.fetchall()
print("work_entries columns:")
for name, dtype in rows:
    print(f"  - {name}: {dtype}")
conn.close()

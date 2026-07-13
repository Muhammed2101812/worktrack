#!/usr/bin/env python3
"""Apply a Supabase/Postgres migration SQL file to the remote database.

Reads credentials from .env and connects via the pooler host. Usage:

    python scripts/apply_migration.py <path-to-sql>

The connection uses the session pooler on port 5432. The script prints the
number of executed statements and any NOTICE messages, then exits 0 on
success or non-zero on error.
"""
import os
import sys
from pathlib import Path

try:
    import psycopg2  # type: ignore
except ImportError:
    print("ERROR: psycopg2-binary is not installed. Run: pip install psycopg2-binary", file=sys.stderr)
    sys.exit(2)


def load_env(env_path: Path) -> dict:
    env = {}
    if not env_path.exists():
        raise FileNotFoundError(f".env not found at {env_path}")
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        env[key.strip()] = val.strip()
    return env


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python scripts/apply_migration.py <migration.sql>", file=sys.stderr)
        return 2

    sql_path = Path(sys.argv[1])
    if not sql_path.exists():
        print(f"ERROR: migration file not found: {sql_path}", file=sys.stderr)
        return 2

    root = Path(__file__).resolve().parent.parent
    env = load_env(root / ".env")

    supabase_url = env.get("SUPABASE_URL", "").rstrip("/")
    db_password = env.get("SUPABASE_DB_PASSWORD", "")
    if not supabase_url or not db_password:
        print("ERROR: SUPABASE_URL or SUPABASE_DB_PASSWORD missing in .env", file=sys.stderr)
        return 2

    # Derive project ref from https://<ref>.supabase.co
    project_ref = supabase_url.replace("https://", "").split(".")[0]

    # Supabase pooler host (session pooler, port 5432). The db user is
    # "postgres.<project_ref>" and the database is "postgres".
    host = "aws-0-eu-central-1.pooler.supabase.com"
    user = f"postgres.{project_ref}"
    dbname = "postgres"

    sql = sql_path.read_text(encoding="utf-8")

    print(f"Connecting to {host} as {user}, db={dbname}")
    print(f"Applying: {sql_path.name}")

    try:
        conn = psycopg2.connect(
            host=host,
            port=5432,
            dbname=dbname,
            user=user,
            password=db_password,
            connect_timeout=20,
            sslmode="require",
        )
    except Exception as e:
        print(f"ERROR: connection failed: {e}", file=sys.stderr)
        return 1

    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(sql)
        conn.commit()
        print("SUCCESS: migration applied.")
        return 0
    except Exception as e:
        print(f"ERROR: migration failed: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())

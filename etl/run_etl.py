import io
import os
import logging

import pandas as pd
import psycopg2
from dotenv import load_dotenv

from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent   # корінь проєкту
SQL_DIR = BASE_DIR / "sql"
CSV_PATH = BASE_DIR / "data" / "2019-Nov.csv" / "2019-Nov.csv"
CHECKS_DIR = BASE_DIR / "sql" / "checks"

CHUNK_SIZE = 25_000
ROW_LIMIT = 100_000

load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")

def get_connection() :
    return psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

def load_raw(conn, limit = None) :
    with conn.cursor() as cur:
        # start from an empty table so reruns don't duplicate data
        cur.execute("TRUNCATE TABLE raw.events;")

        total_loaded = 0

        for chunk in pd.read_csv(CSV_PATH, dtype=str, chunksize=CHUNK_SIZE):
            # 1. cut the chunk if it goes over the limit
            remaining = limit - total_loaded
            if len(chunk) > remaining:
                chunk = chunk.iloc[:remaining]

            # 2. pack the chunk into an in-memory CSV
            buffer = io.StringIO()
            chunk.to_csv(buffer, index=False, header=False)
            buffer.seek(0)

            # 3. send it to PostgreSQL
            cur.copy_expert("COPY raw.events FROM STDIN WITH (FORMAT csv)", buffer)

            # 4. count only what was actually loaded
            total_loaded += len(chunk)
            print(f"Loaded: {total_loaded}")

            # 5. stop when the limit is reached
            if total_loaded >= limit:
                break

    conn.commit()
    print(f"Done. Total rows loaded: {total_loaded}")


def run_sql_file(conn, path) :
    with open(path, encoding="utf-8") as file:
        sql = file.read()

    with conn.cursor() as cur:
        cur.execute(sql)

    conn.commit()

def run_check(conn, path):
    with open(path, encoding="utf-8") as file:
        sql = file.read()

    with conn.cursor() as cur:
        cur.execute(sql)
        result = cur.fetchone()[0]

    if result != 0:
        raise ValueError(
            f"Quality check failed: {path.name}. Result: {result}"
        )

    logging.info("Quality check passed: %s", path.name)

def check_quality(conn):
    for path in sorted(CHECKS_DIR.glob("*.sql")):
        run_check(conn, path)

def main() :
    conn = get_connection()
    try:
        load_raw(conn, ROW_LIMIT)
        run_sql_file(conn, SQL_DIR / "04_staging.sql")
        run_sql_file(conn, SQL_DIR / "05_load_core.sql")
        check_quality(conn)
    finally:
        conn.close()



if __name__ == "__main__":
    main()
import io
import os

import pandas as pd
import psycopg2
from dotenv import load_dotenv

CSV_PATH = "data/2019-Nov.csv/2019-Nov.csv"
CHUNK_SIZE = 25_000
ROW_LIMIT = 100_000

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
)

try:
    with conn.cursor() as cur:
        # start from an empty table so reruns don't duplicate data
        cur.execute("TRUNCATE TABLE raw.events;")

        total_loaded = 0

        for chunk in pd.read_csv(CSV_PATH, dtype=str, chunksize=CHUNK_SIZE):
            # 1. cut the chunk if it goes over the limit
            remaining = ROW_LIMIT - total_loaded
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
            if total_loaded >= ROW_LIMIT:
                break

    conn.commit()
    print(f"Done. Total rows loaded: {total_loaded}")

finally:
    conn.close()
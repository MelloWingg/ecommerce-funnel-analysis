
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.events (
    event_time   TEXT,
    event_type   TEXT,
    product_id   TEXT,
    category_id  TEXT,
    category_code TEXT,
    brand        TEXT,
    price        TEXT,
    user_id      TEXT,
    user_session TEXT
);

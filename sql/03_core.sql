
CREATE SCHEMA IF NOT EXISTS core;

DROP TABLE IF EXISTS core.events;

DROP TABLE IF EXISTS core.products CASCADE;

CREATE TABLE IF NOT EXISTS core.products (
    product_id BIGINT PRIMARY KEY NOT NULL,
    category_id BIGINT,
    category_code TEXT,
    brand TEXT
);

CREATE TABLE IF NOT EXISTS core.events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_time TIMESTAMPTZ NOT NULL,
    event_type TEXT NOT NULL,
    product_id BIGINT REFERENCES core.products(product_id) NOT NULL,
    price NUMERIC(12, 2),
    user_id BIGINT NOT NULL,
    user_session UUID NOT NULL
);

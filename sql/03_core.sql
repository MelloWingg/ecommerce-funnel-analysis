
CREATE SCHEMA IF NOT EXISTS core;

CREATE TABLE IF NOT EXISTS core.products (
    product_id BIGINT PRIMARY KEY,
    category_id BIGINT,
    category_code TEXT,
    brand TEXT
);

CREATE TABLE IF NOT EXISTS core.events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_time TIMESTAMP,
    event_type TEXT,
    product_id BIGINT REFERENCES core.products(product_id),
    price NUMERIC(12, 2),
    user_id BIGINT,
    user_session TEXT
);

TRUNCATE TABLE core.events, core.products RESTART IDENTITY;

INSERT INTO core.products (
    product_id,
    category_id,
    category_code,
    brand
)
SELECT DISTINCT
    product_id,
    category_id,
    category_code,
    brand
FROM staging.events;

INSERT INTO core.events (
    event_time,
    event_type,
    product_id,
    price,
    user_id,
    user_session
)
SELECT
    event_time,
    event_type,
    product_id,
    price,
    user_id,
    user_session
FROM staging.events;

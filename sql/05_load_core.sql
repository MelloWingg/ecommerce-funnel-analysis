TRUNCATE TABLE core.events, core.products RESTART IDENTITY;

INSERT INTO core.products (
    product_id,
    category_id,
    category_code,
    brand
)
SELECT
    product_id,
    (array_agg(category_id ORDER BY event_time DESC) FILTER (WHERE category_id IS NOT NULL))[1],
    (array_agg(category_code ORDER BY event_time DESC) FILTER (WHERE category_code IS NOT NULL))[1],
    (array_agg(brand ORDER BY event_time DESC) FILTER (WHERE brand IS NOT NULL))[1]
FROM staging.events
GROUP BY product_id;

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

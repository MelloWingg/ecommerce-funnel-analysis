CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.events;

CREATE TABLE staging.events AS
SELECT DISTINCT 
    event_time::timestamptz,
    product_id::bigint,
    event_type::TEXT,
    CASE WHEN price::NUMERIC(12, 2) > 0 THEN price::NUMERIC(12, 2) END AS price,
    category_id::BIGINT,
    NULLIF(category_code::TEXT, '') AS category_code,
    NULLIF(brand::TEXT, '') AS brand,
    user_id::BIGINT,
    user_session::UUID
FROM raw.events
WHERE user_session IS NOT NULL;




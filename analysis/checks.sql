SELECT 
	*
FROM staging.events
WHERE price <= 0;

SELECT *
FROM staging.events
WHERE product_id = 1307554;


SELECT 
	count(DISTINCT event_type )
FROM staging.events;

SELECT 
	count(*)
FROM staging.events
WHERE user_session IS NULL;

WITH product_attributes AS (
    SELECT DISTINCT
        product_id,
        category_id,
        category_code,
        brand
    FROM staging.events
)
SELECT
    product_id,
    COUNT(*) AS combinations_count
FROM product_attributes
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY combinations_count DESC;

SELECT COUNT(*) FROM raw.events;

SELECT * FROM raw.events LIMIT 5;

SELECT
    COUNT(*) FILTER (WHERE category_code IS NULL) AS null_cnt,
    COUNT(*) FILTER (WHERE category_code = '')    AS empty_cnt
FROM raw.events;

SELECT COUNT(*) FROM raw.events;

SELECT COUNT(*) FROM staging.events;

SELECT COUNT(*)
FROM staging.events
WHERE price IS NULL
  AND event_type IN ('purchase', 'cart');

SHOW data_directory;

SELECT 
	category_id,
	category_code,
	brand,
	price,
	count(*),
	max(event_time),
	min(event_time)
FROM staging.events
WHERE product_id = 7003278
GROUP BY category_id, category_code, brand, price;

WITH product_attributes AS (
    SELECT DISTINCT
        product_id,
        category_id,
        category_code,
        brand
    FROM staging.events
)
SELECT
    product_id,
    COUNT(*) AS combinations_count
FROM product_attributes
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY combinations_count DESC;

SELECT product_id
FROM (
    SELECT product_id
    FROM staging.events
    GROUP BY product_id
    HAVING
        COUNT(DISTINCT brand) > 1
        OR COUNT(DISTINCT category_code) > 1
        OR COUNT(DISTINCT category_id) > 1
) AS conflicting_products;

WITH product_stats AS (
    SELECT
        COUNT(*) AS product_events,
        SUM(price) FILTER (WHERE event_type = 'purchase') AS product_revenue
    FROM staging.events
    WHERE product_id = 7003278
),
total_stats AS (
    SELECT
        COUNT(*) AS total_events,
        SUM(price) FILTER (WHERE event_type = 'purchase') AS total_revenue
    FROM staging.events
)
SELECT
    p.product_events,
    t.total_events,
    ROUND(
        100.0 * p.product_events / NULLIF(t.total_events, 0),
        2
    ) AS events_share_pct,
    COALESCE(p.product_revenue, 0) AS product_revenue,
    t.total_revenue,
    ROUND(
        100.0 * COALESCE(p.product_revenue, 0)
        / NULLIF(t.total_revenue, 0),
        2
    ) AS revenue_share_pct
FROM product_stats p
CROSS JOIN total_stats t;

SELECT
       pg_size_pretty(pg_total_relation_size('raw.events'))     AS raw_size,
       pg_size_pretty(pg_total_relation_size('staging.events')) AS staging_size,
       pg_size_pretty(pg_total_relation_size('core.events'))    AS core_events_size,
       pg_size_pretty(pg_total_relation_size('core.products'))  AS core_products_size;

SELECT count(
	SELECT 
		product_id,
		category_id, 
		category_code, 
		brand
	FROM staging.events
	GROUP BY 1,2,3,4)
FROM staging.events;

WITH metrics AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM (
                SELECT DISTINCT
                    product_id,
                    category_id,
                    category_code,
                    brand
                FROM staging.events
            ) AS combinations
        ) AS unique_combinations,
        (
            SELECT COUNT(DISTINCT product_id)
            FROM staging.events
        ) AS unique_products,
        (
            SELECT COUNT(*)
            FROM (
                SELECT product_id
                FROM staging.events
                GROUP BY product_id
                HAVING
                    COUNT(DISTINCT (category_id, category_code, brand)) > 1
            ) AS multi_version_products
        ) AS metric_02
)
SELECT
    unique_combinations,
    unique_products,
    unique_combinations - unique_products AS calculated_metric,
    metric_02,
    (unique_combinations - unique_products) = metric_02 AS metrics_match
FROM metrics;
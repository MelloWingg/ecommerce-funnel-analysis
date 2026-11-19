DROP TABLE IF EXISTS marts.daily_overview;

CREATE TABLE marts.daily_overview AS
SELECT 
	date_trunc('day', event_time AT TIME ZONE 'UTC') AS day,
	count(DISTINCT user_id) AS unique_users,
	count(DISTINCT user_session) AS unique_session,
	count(*) FILTER (WHERE event_type = 'view') AS view_events,
	count(*) FILTER (WHERE event_type = 'cart') AS cart,
	count(*) FILTER (WHERE event_type = 'purchase') AS purchase,
	sum(price) FILTER (WHERE event_type = 'purchase') AS sum_purchase,
	sum(price) FILTER (WHERE event_type = 'cart') AS sum_cart,
	avg(price) FILTER (WHERE event_type = 'purchase') AS avg_purchase,
	avg(price) FILTER (WHERE event_type = 'cart') AS avg_cart,
	percentile_cont(0.5) WITHIN GROUP (ORDER BY price) FILTER (WHERE event_type = 'purchase') AS  median_purchase,
	percentile_cont(0.5) WITHIN GROUP (ORDER BY price) FILTER (WHERE event_type = 'cart') AS median_cart,
	count(*) FILTER (WHERE event_type = 'purchase')::numeric / NULLIF(count(*) FILTER (WHERE event_type = 'cart'),0)::NUMERIC AS purchase_cart_ratio
FROM core.events
GROUP BY 1;

ALTER TABLE marts.daily_overview
    ADD COLUMN is_excluded boolean,
    ADD COLUMN cart_regime text;

UPDATE marts.daily_overview
SET is_excluded = day BETWEEN '2019-11-14' AND '2019-11-17',
    cart_regime = CASE WHEN day < '2019-11-08' THEN 'before' ELSE 'after' END;

SELECT 
	date_trunc('day', event_time AT TIME ZONE 'UTC') AS day,
	count(*) FILTER (WHERE event_type = 'purchase')::numeric / NULLIF(count(*) FILTER (WHERE event_type = 'cart'),0)::numeric
FROM core.events
GROUP BY 1;

SELECT
    EXTRACT(ISODOW FROM day) AS weekday,
    TO_CHAR(day, 'Day') AS weekday_name,
    COUNT(*) AS days_count,
    ROUND(AVG(purchase), 0) AS avg_purchase,
    ROUND(AVG(cart), 0) AS avg_cart,
    ROUND(AVG(view_events), 0) AS avg_views
FROM marts.daily_overview
WHERE day < '2019-11-08'
   OR day > '2019-11-17'
GROUP BY 1, 2
ORDER BY 1;

SELECT *
FROM marts.daily_overview
LIMIT 20;
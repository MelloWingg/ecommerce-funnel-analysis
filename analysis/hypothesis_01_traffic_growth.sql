/*
HYPOTHESIS 01: Is traffic growing?

Goal: Determine whether traffic is actually growing
and whether the increase is associated with abnormal
activity from a small group of users.
*/

-- 1. Compare Cart and Purchase event counts between Raw and Core
-- to check data consistency across processing layers.
WITH events AS (
    SELECT
        LEFT(event_time, 10) AS event_date,
        COUNT(*) FILTER (WHERE event_type = 'cart') AS raw_cart,
        COUNT(*) FILTER (WHERE event_type = 'purchase') AS raw_purchase,
        0 AS core_cart,
        0 AS core_purchase
    FROM raw.events
    WHERE LEFT(event_time, 10) IN (
        '2019-11-07', '2019-11-08',
        '2019-11-14', '2019-11-15',
        '2019-11-16', '2019-11-17',
        '2019-11-18'
    )
    GROUP BY 1
    UNION ALL
    SELECT
        DATE(event_time)::text AS event_date,
        0 AS raw_cart,
        0 AS raw_purchase,
        COUNT(*) FILTER (WHERE event_type = 'cart') AS core_cart,
        COUNT(*) FILTER (WHERE event_type = 'purchase') AS core_purchase
    FROM core.events
    WHERE DATE(event_time) IN (
        '2019-11-07', '2019-11-08',
        '2019-11-14', '2019-11-15',
        '2019-11-16', '2019-11-17',
        '2019-11-18'
    )
    GROUP BY 1
)
SELECT
    event_date,
    SUM(raw_cart) AS raw_cart,
    SUM(core_cart) AS core_cart,
    SUM(raw_purchase) AS raw_purchase,
    SUM(core_purchase) AS core_purchase
FROM events
GROUP BY event_date
ORDER BY event_date;

-- 2. Analyze hourly View, Cart, and Purchase activity
-- during the suspicious period (November 14–17).
SELECT 
	date_trunc('hour',event_time),
	COUNT(*) FILTER (WHERE event_type = 'cart') AS cart,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS purchase,
    COUNT(*) FILTER (WHERE event_type = 'view') AS view
FROM core.events
WHERE date(event_time) IN ('2019-11-14', '2019-11-15',
        						'2019-11-16', '2019-11-17')
GROUP BY 1;

-- 3. Analyze hourly Cart activity during the normal period
-- (November 7–8) to establish a baseline for comparison.
SELECT 
	date_trunc('hour',event_time),
	COUNT(*) FILTER (WHERE event_type = 'cart') AS cart
FROM core.events
WHERE date(event_time) IN ('2019-11-07', '2019-11-08')
GROUP BY 1;

-- 4. Compare user activity between suspicious and normal periods.
-- Analyze events per user, events per session,
-- and activity concentration among the top 100 users.
WITH base AS (
    SELECT
        CASE
            WHEN event_time BETWEEN '2019-11-15' AND '2019-11-17'
                THEN 'suspicious'
            WHEN event_time BETWEEN '2019-11-20' AND '2019-11-22'
                THEN 'normal'
        END AS period,
        user_id,
        user_session 
    FROM core.events
    WHERE event_time BETWEEN '2019-11-15' AND '2019-11-17'
       OR event_time BETWEEN '2019-11-20' AND '2019-11-22'
),
user_activity AS (
    SELECT
        period,
        user_id,
        COUNT(*) AS events_count
    FROM base
    GROUP BY period, user_id
),
top_users AS (
    SELECT
        period,
        user_id,
        events_count,
        ROW_NUMBER() OVER (
            PARTITION BY period
            ORDER BY events_count DESC
        ) AS rn
    FROM user_activity
),
period_stats AS (
    SELECT
        period,
        COUNT(*) AS total_events,
        COUNT(DISTINCT user_id) AS users,
        COUNT(DISTINCT user_session) AS sessions
    FROM base
    GROUP BY period
),
top100_stats AS (
    SELECT
        period,
        SUM(events_count) AS top100_events
    FROM top_users
    WHERE rn <= 100
    GROUP BY period
)
SELECT
    p.period,
    p.total_events,
    p.users,
    ROUND(p.total_events::numeric / NULLIF(p.users, 0), 2)
        AS events_per_user,
    p.sessions,
    ROUND(p.total_events::numeric / NULLIF(p.sessions, 0), 2)
        AS events_per_session,
    ROUND(
        t.top100_events::numeric / NULLIF(p.total_events, 0) * 100,
        2
    ) AS top100_events_share
FROM period_stats p
LEFT JOIN top100_stats t USING (period)
ORDER BY p.period;

-- 5. Compare weekly traffic and business metrics.
-- Analyze users, sessions, purchases, revenue,
-- average purchase value, and median purchase value.
WITH weeks as(
	SELECT *,
		CASE 
			WHEN day BETWEEN '2019-11-04' AND '2019-11-10' THEN 'week_1' 
			WHEN day BETWEEN '2019-11-18' AND '2019-11-24' THEN 'week_2' 
		END AS weeks
	FROM marts.daily_overview
	WHERE day >= '2019-11-04' AND day < '2019-11-11'
		OR day >= '2019-11-18' AND day < '2019-11-25'
	),
weekly_stats AS (
	SELECT 
		weeks,
		avg(unique_users ) AS avg_users,
		avg(unique_session  ) AS avg_sessions,
		avg(purchase  ) AS avg_purchase,
		avg(sum_purchase  ) AS revenue,
		sum(sum_purchase )::NUMERIC / sum(purchase )::NUMERIC AS avg_purchase_price
	FROM weeks
	GROUP BY 1
	),
weekly_median AS (
	SELECT 
		CASE 
			WHEN (event_time AT TIME ZONE 'UTC')::date BETWEEN '2019-11-04' AND '2019-11-10' THEN 'week_1' 
			WHEN (event_time AT TIME ZONE 'UTC')::date BETWEEN '2019-11-18' AND '2019-11-24' THEN 'week_2' 
		END AS weeks,
		percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS median_price
	FROM core.events 
	WHERE event_type = 'purchase'
	        AND (
	            (event_time AT TIME ZONE 'UTC')::date BETWEEN '2019-11-04' AND '2019-11-10'
	            OR (event_time AT TIME ZONE 'UTC')::date BETWEEN '2019-11-18' AND '2019-11-24'
	        )
	GROUP BY 1
	),
combined as(
	SELECT 
		ws.weeks,
		ws.avg_users, 
		ws.avg_sessions, 
		ws.avg_purchase,
		ws.revenue,
		ws.avg_purchase_price,
		wm.median_price
	FROM weekly_stats ws
	LEFT JOIN weekly_median wm ON ws.weeks = wm.weeks 
	),
comparison AS (
	SELECT 
		'change_percent' AS weeks,
		round(((week_2.avg_users - week_1.avg_users )
			* 100 / nullif(week_1.avg_users, 0))::numeric,2) AS avg_users,
		round(((week_2.avg_sessions - week_1.avg_sessions )
			* 100 / nullif(week_1.avg_sessions, 0))::numeric,2) AS avg_sessions,
		round(((week_2.avg_purchase - week_1.avg_purchase )
			* 100 / nullif(week_1.avg_purchase, 0))::numeric,2) AS avg_purchase,
		round(((week_2.revenue - week_1.revenue )
			* 100 / nullif(week_1.revenue, 0))::NUMERIC, 2) AS revenue,
		round(((week_2.avg_purchase_price - week_1.avg_purchase_price )
			* 100 / nullif(week_1.avg_purchase_price, 0))::numeric,2) AS avg_purchase_price,
		round(((week_2.median_price - week_1.median_price )
			* 100 / nullif(week_1.median_price, 0))::numeric,2) AS median_price
	FROM combined week_1
	CROSS JOIN combined week_2
	WHERE week_1.weeks = 'week_1'
	        AND week_2.weeks = 'week_2'
	)
SELECT weeks,
	round(avg_users::numeric,0) AS avg_users,
	round(avg_sessions::numeric,0) AS avg_sessions,
	round(avg_purchase::numeric,0) AS avg_purchase,
	round(revenue::numeric,0) AS revenue,
	round(avg_purchase_price::numeric,2) AS avg_purchase_price,
	round(median_price::numeric,2) AS median_price
FROM combined
UNION ALL
SELECT * FROM comparison;
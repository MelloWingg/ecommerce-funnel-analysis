WITH days_in_scope AS (
	SELECT
		e.event_time,
		e.product_id,
		e.price
	FROM core.events e
	WHERE ((e.event_time >= TIMESTAMPTZ '2019-11-04 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-11 00:00:00+00')
		OR
		(e.event_time >= TIMESTAMPTZ '2019-11-22 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-29 00:00:00+00'))
		AND e.event_type = 'purchase'
	),
purchases as(
	SELECT
		CASE
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-04'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-11'
	            THEN 'week_1'
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-22'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-29'
	            THEN 'week_2'
	    END AS weeks,
	    p.category_id,
	    dis.price
	FROM days_in_scope dis
	LEFT JOIN core.products p ON dis.product_id = p.product_id 
	),
weekly_category AS (
	SELECT 
		weeks,
		category_id,
		count(*) AS count_purchases,
		sum(price) AS revenue
	FROM purchases
	GROUP BY weeks, category_id
	),
weekly_shares AS (
	SELECT *,
		count_purchases::NUMERIC / SUM(count_purchases) OVER (PARTITION BY weeks) AS share
	    FROM weekly_category
	    ),
week_1 AS (
    -- First week metrics
    SELECT *
    FROM weekly_shares
    WHERE weeks = 'week_1'
),
week_2 AS (
    -- Second week metrics
    SELECT *
    FROM weekly_shares
    WHERE weeks = 'week_2'
),
comparison AS (
    -- Combine both weeks by category
    SELECT
        COALESCE(w1.category_id, w2.category_id) AS category_id,
        COALESCE(w1.count_purchases, 0) AS purchases_1,
        COALESCE(w1.revenue, 0) AS revenue_1,
        COALESCE(w1.share, 0) AS share_1,
        COALESCE(w2.count_purchases, 0) AS purchases_2,
        COALESCE(w2.revenue, 0) AS revenue_2,
        COALESCE(w2.share, 0) AS share_2
    FROM week_1 w1
    FULL OUTER JOIN week_2 w2
        ON w1.category_id = w2.category_id
),
mean_categori_price AS (
	SELECT *,
		revenue_1::NUMERIC / nullif(purchases_1,0) AS price_1,
		revenue_2::NUMERIC / nullif(purchases_2,0) AS price_2
	FROM comparison
	ORDER BY category_id
	),
effects AS (
	SELECT *,
		(COALESCE(share_2, 0) - COALESCE(share_1, 0)) * (COALESCE(price_1, price_2) - SUM(revenue_1) OVER () / NULLIF(SUM(purchases_1) OVER (), 0)) AS mix_effect,
		COALESCE(share_2, 0) * (COALESCE(price_2, price_1) - COALESCE(price_1, price_2)) AS price_effect
	FROM mean_categori_price
	),
ranked AS (
	SELECT *,
		row_number() OVER (ORDER BY abs(mix_effect) + abs(price_effect) DESC ) AS rn
	FROM effects
	)
SELECT 1 AS ord,
	rn,
	r.category_id:: text AS category,
	purchases_1,
	purchases_2,
	round(share_1, 3) AS share_1,
	round(share_2, 3) AS share_2,
	round(price_1, 0) AS price_1,
	round(price_2, 0) AS price_2,
	round(mix_effect, 2) AS mix_effect,
	round(price_effect, 2) AS price_effect
FROM ranked r
WHERE rn <= 10
UNION ALL 
SELECT 2,
	NULL,
	'other',
	sum(purchases_1),
	sum(purchases_2),
	sum(share_1),
	sum(share_2),
	sum(revenue_1) / NULLIF(sum(purchases_1),0),
	sum(revenue_2) / NULLIF(sum(purchases_2),0),
	sum(mix_effect),
	sum(price_effect)
FROM ranked
WHERE rn > 10
UNION ALL 
SELECT 3,
	NULL,
	'total',
	sum(purchases_1),
	sum(purchases_2),
	sum(share_1),
	sum(share_2),
	sum(revenue_1) / NULLIF(sum(purchases_1),0),
	sum(revenue_2) / NULLIF(sum(purchases_2),0),
	sum(mix_effect),
	sum(price_effect)
FROM ranked
ORDER BY ord, rn;


WITH days_in_scope AS (
	SELECT
		e.event_time,
		e.product_id,
		e.price
	FROM core.events e
	WHERE ((e.event_time >= TIMESTAMPTZ '2019-11-04 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-11 00:00:00+00')
		OR
		(e.event_time >= TIMESTAMPTZ '2019-11-22 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-29 00:00:00+00'))
		AND e.event_type = 'purchase'
	),
purchases as(
	SELECT
		CASE
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-04'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-11'
	            THEN 'week_1'
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-22'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-29'
	            THEN 'week_2'
	    END AS weeks,
	    dis.product_id,
	    p.category_id,
	    p.brand ,
	    dis.price
	FROM days_in_scope dis
	JOIN core.products p ON dis.product_id = p.product_id 
	WHERE p.category_id  = '2053013555631882655'
	)
SELECT weeks,
	brand,
	count(*) AS purchases,
	count(*)::NUMERIC / sum(count(*)) OVER (PARTITION BY weeks) AS purchase_share,
	sum(price)::NUMERIC / count(*) AS avg_price
FROM purchases
GROUP BY 1,2
ORDER BY 2;

WITH days_in_scope AS (
	SELECT
		e.event_time,
		e.product_id,
		e.price
	FROM core.events e
	WHERE ((e.event_time >= TIMESTAMPTZ '2019-11-04 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-11 00:00:00+00')
		OR
		(e.event_time >= TIMESTAMPTZ '2019-11-22 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-29 00:00:00+00'))
		AND e.event_type = 'purchase'
	),
purchases as(
	SELECT
		CASE
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-04'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-11'
	            THEN 'week_1'
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-22'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-29'
	            THEN 'week_2'
	    END AS weeks,
	    dis.product_id,
	    p.category_id,
	    p.brand ,
	    dis.price
	FROM days_in_scope dis
	JOIN core.products p ON dis.product_id = p.product_id 
	WHERE p.category_id  = '2053013555631882655'
	),
weekly_product AS (
	SELECT 
		weeks,
		product_id ,
		count(*) AS purchases,
		sum(price) AS revenue,
		sum(price)::NUMERIC / count(*) AS avg_price
	FROM purchases
	GROUP BY weeks, product_id 
	),
week_1 AS (
	SELECT *
	FROM weekly_product 
	WHERE weeks = 'week_1'
	),
week_2 AS (
	SELECT *
	FROM weekly_product 
	WHERE weeks = 'week_2'
	),
product_comparison AS (
	SELECT
		coalesce(w1.product_id ,w2.product_id ) AS product_id,
		coalesce(w1.purchases, 0) AS purchases_1,
		coalesce(w1.revenue , 0) AS revenue_1,
		w1.avg_price AS avg_price_1,
		coalesce(w2.purchases, 0) AS purchases_2,
		coalesce(w2.revenue , 0) AS revenue_2,
		w2.avg_price AS avg_price_2
	FROM week_1 w1
	FULL OUTER JOIN week_2 w2 ON w1.product_id = w2.product_id 
	),
product_groups AS (
	SELECT
		product_id,
		CASE 
			WHEN purchases_1 > 0 AND purchases_2 > 0 
				THEN 'Both weeks'
			WHEN purchases_1 > 0 AND purchases_2 = 0
				THEN 'Week 1 only'
			WHEN purchases_1 = 0 AND purchases_2 > 0
				THEN 'Week 2 only'
		END AS product_group,
		purchases_1,
		revenue_1 ,
		avg_price_1,
		purchases_2,
		revenue_2 ,
		avg_price_2
	FROM product_comparison
	)
SELECT 
	product_group ,
	count(*) AS unique_products,
	sum(purchases_1) AS purchases_1,
	sum(purchases_2) AS purchases_2,
	round(sum(revenue_1)::NUMERIC / nullif(sum(purchases_1),0),2) AS avg_price_1,
	round(sum(revenue_2)::NUMERIC / nullif(sum(purchases_2),0),2) AS avg_price_2
FROM product_groups
GROUP BY product_group
ORDER BY product_group;

WITH days_in_scope AS (
	SELECT
		e.event_time,
		e.product_id,
		e.price
	FROM core.events e
	WHERE ((e.event_time >= TIMESTAMPTZ '2019-11-04 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-11 00:00:00+00')
		OR
		(e.event_time >= TIMESTAMPTZ '2019-11-22 00:00:00+00'
			AND e.event_time < TIMESTAMPTZ '2019-11-29 00:00:00+00'))
		AND e.event_type = 'purchase'
	),
purchases as(
	SELECT
		CASE
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-04'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-11'
	            THEN 'week_1'
	        WHEN dis.event_time AT TIME ZONE 'UTC' >= '2019-11-22'
	         AND dis.event_time AT TIME ZONE 'UTC' < '2019-11-29'
	            THEN 'week_2'
	    END AS weeks,
	    dis.product_id,
	    p.category_id,
	    p.brand ,
	    dis.price
	FROM days_in_scope dis
	JOIN core.products p ON dis.product_id = p.product_id 
	WHERE p.category_id  = '2053013555631882655'
	),
weekly_product AS (
	SELECT 
		weeks,
		product_id ,
		count(*) AS purchases,
		sum(price) AS revenue,
		sum(price)::NUMERIC / count(*) AS avg_price
	FROM purchases
	GROUP BY weeks, product_id 
	),
week_1 AS (
	SELECT *
	FROM weekly_product 
	WHERE weeks = 'week_1'
	),
week_2 AS (
	SELECT *
	FROM weekly_product 
	WHERE weeks = 'week_2'
	),
product_comparison AS (
	SELECT
		coalesce(w1.product_id ,w2.product_id ) AS product_id,
		coalesce(w1.purchases, 0) AS purchases_1,
		coalesce(w1.revenue , 0) AS revenue_1,
		w1.avg_price AS avg_price_1,
		coalesce(w2.purchases, 0) AS purchases_2,
		coalesce(w2.revenue , 0) AS revenue_2,
		w2.avg_price AS avg_price_2
	FROM week_1 w1
	FULL OUTER JOIN week_2 w2 ON w1.product_id = w2.product_id 
	),
product_groups AS (
	SELECT
		product_id,
		CASE 
			WHEN purchases_1 > 0 AND purchases_2 > 0 
				THEN 'Both weeks'
			WHEN purchases_1 > 0 AND purchases_2 = 0
				THEN 'Week 1 only'
			WHEN purchases_1 = 0 AND purchases_2 > 0
				THEN 'Week 2 only'
		END AS product_group,
		purchases_1,
		revenue_1 ,
		avg_price_1,
		purchases_2,
		revenue_2 ,
		avg_price_2
	FROM product_comparison
	)
SELECT
    COUNT(*) AS common_products,
    SUM(purchases_1) AS purchases_1,
    SUM(purchases_2) AS purchases_2,
    ROUND(
        SUM(purchases_2 * (avg_price_2 - avg_price_1))
        / SUM(purchases_2),
        2
    ) AS weighted_price_change
FROM product_comparison
WHERE purchases_1 > 0
  AND purchases_2 > 0;

SELECT 
	date_trunc('day', e.event_time AT TIME ZONE 'UTC') AS day,
	count(*) FILTER (WHERE p.brand = 'apple') AS apple_purchases,
	(count(*) FILTER (WHERE p.brand = 'apple')::NUMERIC / count(*)) * 100 AS percente
FROM core.events e 
JOIN core.products p ON e.product_id = p.product_id 
WHERE p.category_id = '2053013555631882655' AND e.event_type = 'purchase'AND date_trunc('day', e.event_time AT TIME ZONE 'UTC') NOT IN ('2019-11-14','2019-11-15','2019-11-16','2019-11-17')
GROUP BY day
ORDER BY day

SELECT *
FROM core.events e 
JOIN core.products p ON e.product_id = p.product_id
LIMIT 90;
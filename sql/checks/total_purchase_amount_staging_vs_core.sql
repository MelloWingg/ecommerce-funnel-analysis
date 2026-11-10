SELECT
    'staging' AS source,
    SUM(price) AS total_purchase_amount
FROM staging.events
WHERE event_type = 'purchase'
UNION ALL
SELECT
    'core' AS source,
    SUM(price) AS total_purchase_amount
FROM core.events
WHERE event_type = 'purchase';
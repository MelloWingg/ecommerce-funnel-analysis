SELECT COUNT(*)
FROM staging.events
WHERE event_type NOT IN ('view', 'cart', 'purchase');
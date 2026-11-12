SELECT COUNT(*)
FROM staging.events
WHERE event_type = 'cart'
  AND price IS NULL;
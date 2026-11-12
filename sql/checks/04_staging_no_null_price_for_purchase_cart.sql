SELECT COUNT(*)
FROM staging.events
WHERE price IS NULL
  AND event_type IN ('purchase');

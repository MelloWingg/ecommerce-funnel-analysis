SELECT ABS(
    (SELECT COALESCE(SUM(price), 0) FROM staging.events WHERE event_type = 'purchase')
    - (SELECT COALESCE(SUM(price), 0) FROM core.events WHERE event_type = 'purchase')
);
SELECT 
    (SELECT COUNT(*) FROM raw.events)
    - 
    (SELECT COUNT(*) FROM staging.events)
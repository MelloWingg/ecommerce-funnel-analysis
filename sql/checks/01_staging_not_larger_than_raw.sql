SELECT GREATEST(
    0,
    (SELECT COUNT(*) FROM staging.events)
    - (SELECT COUNT(*) FROM raw.events)
);
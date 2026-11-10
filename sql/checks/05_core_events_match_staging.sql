SELECT ABS(
    (SELECT COUNT(*) FROM core.events)
    - (SELECT COUNT(*) FROM staging.events)
);
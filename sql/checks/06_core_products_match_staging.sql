SELECT ABS(
    (SELECT COUNT(*) FROM core.products)
    - (SELECT COUNT(DISTINCT product_id) FROM staging.events)
);
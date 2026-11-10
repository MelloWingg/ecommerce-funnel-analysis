SELECT COUNT(*) AS events_without_product
FROM core.events e
LEFT JOIN core.products p
    ON e.product_id = p.product_id
WHERE p.product_id IS NULL;
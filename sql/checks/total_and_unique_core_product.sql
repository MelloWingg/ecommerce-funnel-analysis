SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products
FROM core.products;
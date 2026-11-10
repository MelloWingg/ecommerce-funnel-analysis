SELECT 
	*
FROM staging.events
WHERE price <= 0;

SELECT *
FROM staging.events
WHERE product_id = 1307554;


SELECT 
	count(DISTINCT event_type )
FROM staging.events;

SELECT 
	count(*)
FROM staging.events
WHERE user_session IS NULL;

WITH product_attributes AS (
    SELECT DISTINCT
        product_id,
        category_id,
        category_code,
        brand
    FROM staging.events
)
SELECT
    product_id,
    COUNT(*) AS combinations_count
FROM product_attributes
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY combinations_count DESC;
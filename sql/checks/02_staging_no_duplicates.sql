SELECT COUNT(*)
FROM (
    SELECT *
    FROM staging.events
    GROUP BY
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session
    HAVING COUNT(*) > 1
) AS duplicates;
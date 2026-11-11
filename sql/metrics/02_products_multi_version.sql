SELECT COUNT(*)
        FROM (
            SELECT product_id
            FROM (
                SELECT DISTINCT product_id, category_id, category_code, brand
                FROM staging.events
            ) AS versions
            GROUP BY product_id
            HAVING COUNT(*) > 1
        ) AS t
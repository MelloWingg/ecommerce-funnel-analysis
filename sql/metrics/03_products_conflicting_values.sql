SELECT COUNT(*)
        FROM (
            SELECT product_id
            FROM staging.events
            GROUP BY product_id
            HAVING COUNT(DISTINCT brand) > 1
                OR COUNT(DISTINCT category_code) > 1
                OR COUNT(DISTINCT category_id) > 1
        ) AS t
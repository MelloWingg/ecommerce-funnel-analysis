SELECT
    (SELECT COUNT(*) FROM raw.events) AS raw_count,
    (SELECT COUNT(*) FROM staging.events) AS staging_count,
    (SELECT COUNT(*) FROM raw.events) -
    (SELECT COUNT(*) FROM staging.events) AS duplicates_removed;
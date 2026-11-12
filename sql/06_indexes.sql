-- Indexes for analysis queries on core.events (created after the bulk load).
-- Run once, manually. On 67M rows on an HDD each index can take several minutes.

SET maintenance_work_mem = '1GB';  -- speeds up index builds (this session only)

CREATE INDEX IF NOT EXISTS idx_events_product_id   ON core.events (product_id);
CREATE INDEX IF NOT EXISTS idx_events_user_session ON core.events (user_session);
CREATE INDEX IF NOT EXISTS idx_events_user_id      ON core.events (user_id);
CREATE INDEX IF NOT EXISTS idx_events_event_time   ON core.events (event_time);

ANALYZE core.events;
ANALYZE core.products;
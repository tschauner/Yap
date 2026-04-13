-- Migration: Event Tracking + Simulator Detection
-- Adds: yap_events table for funnel analytics, is_simulator flag on yap_devices

-- ============================================================
-- 1. yap_events — lightweight event tracking
-- ============================================================
-- Stores onboarding steps, key actions, etc.
-- Designed for fire-and-forget INSERTs from the client.

CREATE TABLE IF NOT EXISTS yap_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id   TEXT NOT NULL,
    event       TEXT NOT NULL,          -- e.g. 'onboarding_welcome', 'first_mission_created'
    metadata    JSONB DEFAULT '{}',     -- optional context (agent, screen, etc.)
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for querying events by device
CREATE INDEX IF NOT EXISTS idx_yap_events_device ON yap_events(device_id);
-- Index for querying by event name
CREATE INDEX IF NOT EXISTS idx_yap_events_event ON yap_events(event);

-- RLS: devices can only INSERT their own events (via x-device-id header)
ALTER TABLE yap_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "devices_insert_own_events" ON yap_events
    FOR INSERT
    WITH CHECK (
        device_id = current_setting('request.headers')::json->>'x-device-id'
    );

CREATE POLICY "devices_read_own_events" ON yap_events
    FOR SELECT
    USING (
        device_id = current_setting('request.headers')::json->>'x-device-id'
    );

-- Service role can read all (for analytics queries)
-- (service_role bypasses RLS by default)

-- ============================================================
-- 2. Add is_simulator flag to yap_devices
-- ============================================================
-- Client sets this on registration so we can filter out simulators.

ALTER TABLE yap_devices ADD COLUMN IF NOT EXISTS is_simulator BOOLEAN DEFAULT false;
ALTER TABLE yap_devices ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT now();

-- ============================================================
-- 3. RPC: get_funnel_stats (for quick analytics)
-- ============================================================
-- Returns how many devices reached each onboarding step.

CREATE OR REPLACE FUNCTION get_funnel_stats()
RETURNS TABLE(event TEXT, unique_devices BIGINT, total_events BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.event,
        COUNT(DISTINCT e.device_id) AS unique_devices,
        COUNT(*) AS total_events
    FROM yap_events e
    JOIN yap_devices d ON d.device_id = e.device_id
    WHERE d.is_simulator = false
    GROUP BY e.event
    ORDER BY unique_devices DESC;
END;
$$;

-- Migration: Engagement Push Notifications (Cron)
-- Table: yap_engagement_pushes — tracks which engagement pushes were sent per device
-- Cron: send-yap-engagement (daily at 10:00 UTC)

-- ============================================================
-- 1. yap_engagement_pushes — dedup tracking
-- ============================================================

CREATE TABLE IF NOT EXISTS yap_engagement_pushes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id   TEXT NOT NULL,
    push_type   TEXT NOT NULL,  -- 'no_mission_nudge', 'inactive_winback'
    sent_at     TIMESTAMPTZ DEFAULT now(),
    success     BOOLEAN DEFAULT true,
    error       TEXT
);

CREATE INDEX idx_engagement_device_type
    ON yap_engagement_pushes(device_id, push_type);

-- No RLS needed — only accessed by service_role from edge function

-- ============================================================
-- 2. RPC: get_no_mission_nudge_candidates
--    Users who registered >24h ago, never created a mission,
--    have a push token, are not simulators, not already nudged.
-- ============================================================

CREATE OR REPLACE FUNCTION get_no_mission_nudge_candidates()
RETURNS TABLE (device_id TEXT, apns_token TEXT, language TEXT, timezone TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.device_id, d.apns_token, d.language, d.timezone
    FROM yap_devices d
    WHERE d.created_at > '2026-04-13T00:00:00Z'::timestamptz  -- only new users after deployment
      AND d.created_at < now() - interval '24 hours'
      AND d.push_enabled = true
      AND COALESCE(d.is_simulator, false) = false
      AND d.apns_token IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM yap_goals g WHERE g.device_id = d.device_id
      )
      AND NOT EXISTS (
          SELECT 1 FROM yap_engagement_pushes ep
          WHERE ep.device_id = d.device_id AND ep.push_type = 'no_mission_nudge'
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 3. RPC: get_inactive_winback_candidates
--    Users not seen in 5+ days, have push token, not simulators,
--    haven't received this push before.
-- ============================================================

CREATE OR REPLACE FUNCTION get_inactive_winback_candidates()
RETURNS TABLE (device_id TEXT, apns_token TEXT, language TEXT, timezone TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.device_id, d.apns_token, d.language, d.timezone
    FROM yap_devices d
    WHERE d.created_at > '2026-04-13T00:00:00Z'::timestamptz  -- only new users after deployment
      AND d.last_seen_at < now() - interval '5 days'
      AND d.last_seen_at IS NOT NULL
      AND d.push_enabled = true
      AND COALESCE(d.is_simulator, false) = false
      AND d.apns_token IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM yap_engagement_pushes ep
          WHERE ep.device_id = d.device_id AND ep.push_type = 'inactive_winback'
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. pg_cron — fire engagement pushes every 2 hours
--    Runs frequently so timezone-skipped users get retried.
--    Dedup ensures no one gets the same push twice.
-- ============================================================

SELECT cron.schedule(
    'send-yap-engagement',
    '0 */2 * * *',
    $$
    SELECT net.http_post(
        url := 'https://dbxpzxtxhcxbsbkcpuak.supabase.co/functions/v1/send-engagement-pushes',
        headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRieHB6eHR4aGN4YnNia2NwdWFrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTg5MTE2MCwiZXhwIjoyMDgxNDY3MTYwfQ.TjHi2YcCINufut-GMEZDLWyuz50K9_1uoOrIeSx0g1s", "Content-Type": "application/json"}'::jsonb,
        body := '{}'::jsonb
    );
    $$
);

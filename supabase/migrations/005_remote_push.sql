-- Migration: Remote Push Notifications
-- Tables: yap_devices, yap_notifications
-- Extensions: pg_cron, pg_net
-- Cron: send-yap-notifications (every minute)

-- ============================================================
-- 1. yap_devices — APNs tokens + device preferences
-- ============================================================

CREATE TABLE IF NOT EXISTS yap_devices (
    device_id           TEXT PRIMARY KEY,
    apns_token          TEXT,
    apns_environment    TEXT DEFAULT 'production',
    timezone            TEXT DEFAULT 'UTC',
    quiet_hours_start   INT DEFAULT 22,
    quiet_hours_end     INT DEFAULT 8,
    language            TEXT DEFAULT 'en',
    push_enabled        BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ DEFAULT now(),
    updated_at          TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE yap_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_select_own" ON yap_devices FOR SELECT
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');
CREATE POLICY "device_insert_own" ON yap_devices FOR INSERT
    WITH CHECK (device_id = current_setting('request.headers')::json->>'x-device-id');
CREATE POLICY "device_update_own" ON yap_devices FOR UPDATE
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

-- ============================================================
-- 2. yap_notifications — scheduled push messages
-- ============================================================

CREATE TABLE IF NOT EXISTS yap_notifications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id             UUID NOT NULL REFERENCES yap_goals(id) ON DELETE CASCADE,
    device_id           TEXT NOT NULL,
    agent               TEXT NOT NULL,
    title               TEXT NOT NULL,
    body                TEXT NOT NULL,
    escalation_level    INT NOT NULL DEFAULT 0,
    sequence_index      INT NOT NULL DEFAULT 0,
    scheduled_at        TIMESTAMPTZ NOT NULL,
    sent_at             TIMESTAMPTZ,
    status              TEXT NOT NULL DEFAULT 'pending',
    apns_id             TEXT,
    error               TEXT,
    created_at          TIMESTAMPTZ DEFAULT now()
);

-- Index for the cron query: pending notifications due now
CREATE INDEX idx_notif_pending
    ON yap_notifications(scheduled_at)
    WHERE status = 'pending';

-- Index for cancellation by goal
CREATE INDEX idx_notif_goal ON yap_notifications(goal_id);

-- Index for device lookups
CREATE INDEX idx_notif_device ON yap_notifications(device_id);

ALTER TABLE yap_notifications ENABLE ROW LEVEL SECURITY;

-- Clients can only read their own notifications
CREATE POLICY "notif_select_own" ON yap_notifications FOR SELECT
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

-- Clients can update their own notifications (for cancel)
CREATE POLICY "notif_update_own" ON yap_notifications FOR UPDATE
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

-- Service role (edge functions) bypasses RLS via service_role key

-- ============================================================
-- 3. RPC: cancel_pending_notifications
--    Called when mission is completed or given up
-- ============================================================

CREATE OR REPLACE FUNCTION cancel_pending_notifications(p_goal_id UUID)
RETURNS INT AS $$
DECLARE cancelled_count INT;
BEGIN
    UPDATE yap_notifications
    SET status = 'cancelled'
    WHERE goal_id = p_goal_id
      AND status = 'pending';
    GET DIAGNOSTICS cancelled_count = ROW_COUNT;
    RETURN cancelled_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. RPC: increment_notifications_sent
--    Called by send-notifications edge function after sending
-- ============================================================

CREATE OR REPLACE FUNCTION increment_notifications_sent(p_goal_id UUID, p_count INT)
RETURNS VOID AS $$
BEGIN
    UPDATE yap_goals
    SET notifications_sent = COALESCE(notifications_sent, 0) + p_count
    WHERE id = p_goal_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. RPC: get_notification_stats
--    Stats for a specific goal
-- ============================================================

CREATE OR REPLACE FUNCTION get_notification_stats(p_goal_id UUID)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'total', COUNT(*),
            'sent', COUNT(*) FILTER (WHERE status = 'sent'),
            'pending', COUNT(*) FILTER (WHERE status = 'pending'),
            'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
            'failed', COUNT(*) FILTER (WHERE status = 'failed')
        )
        FROM yap_notifications
        WHERE goal_id = p_goal_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. pg_cron — fire send-notifications every minute
-- ============================================================

-- Enable extensions (already available on Supabase Pro)
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Schedule: every minute, call the edge function
-- Note: service_role_key is safe here — cron.job table is only accessible by postgres role
SELECT cron.schedule(
    'send-yap-notifications',
    '* * * * *',
    $$
    SELECT net.http_post(
        url := 'https://dbxpzxtxhcxbsbkcpuak.supabase.co/functions/v1/send-notifications',
        headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRieHB6eHR4aGN4YnNia2NwdWFrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTg5MTE2MCwiZXhwIjoyMDgxNDY3MTYwfQ.TjHi2YcCINufut-GMEZDLWyuz50K9_1uoOrIeSx0g1s", "Content-Type": "application/json"}'::jsonb,
        body := '{}'::jsonb
    );
    $$
);

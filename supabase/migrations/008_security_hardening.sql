-- Migration: Security Hardening
-- Adds: is_pro flag on yap_devices, server-side rate limiting RPC
-- Purpose: Prevent abuse of generate-copy/generate-reaction endpoints

-- ============================================================
-- 1. Add is_pro to yap_devices
-- ============================================================
-- Devices call sync_pro_status after purchase or on app launch.
-- Edge functions check this instead of trusting client-sent isPro.

ALTER TABLE yap_devices ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT false;
ALTER TABLE yap_devices ADD COLUMN IF NOT EXISTS pro_synced_at TIMESTAMPTZ;

-- ============================================================
-- 2. RPC: sync_pro_status
-- ============================================================
-- Called from iOS after purchase or on app launch.
-- Uses x-device-id header (same as all other RPCs).

CREATE OR REPLACE FUNCTION sync_pro_status(p_is_pro BOOLEAN)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    did TEXT;
BEGIN
    did := current_setting('request.headers')::json->>'x-device-id';
    -- UPSERT: works even if device has no row yet (push denied, first launch, etc.)
    INSERT INTO yap_devices (device_id, is_pro, pro_synced_at, updated_at)
    VALUES (did, p_is_pro, now(), now())
    ON CONFLICT (device_id) DO UPDATE SET
        is_pro = EXCLUDED.is_pro,
        pro_synced_at = EXCLUDED.pro_synced_at,
        updated_at = EXCLUDED.updated_at;
END;
$$;

-- ============================================================
-- 3. RPC: check_rate_limit
-- ============================================================
-- Returns the number of missions created today for a device.
-- Edge functions can call this to enforce free-tier limits server-side.

CREATE OR REPLACE FUNCTION check_rate_limit(p_device_id TEXT)
RETURNS TABLE(missions_today INT, is_pro BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE((
            SELECT COUNT(*)::INT
            FROM yap_goals g
            WHERE g.device_id = p_device_id
              AND g.created_at >= (now() AT TIME ZONE 'UTC')::date
              AND g.status IN ('active', 'completed', 'given_up')
        ), 0) AS missions_today,
        COALESCE(d.is_pro, false) AS is_pro
    FROM (SELECT 1) AS dummy
    LEFT JOIN yap_devices d ON d.device_id = p_device_id;
END;
$$;

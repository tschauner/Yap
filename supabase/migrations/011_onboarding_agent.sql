-- Migration: Save onboarding agent on yap_devices
ALTER TABLE yap_devices ADD COLUMN IF NOT EXISTS onboarding_agent TEXT;

-- Must drop first since return type changes (adds onboarding_agent)
DROP FUNCTION IF EXISTS get_no_mission_nudge_candidates();
DROP FUNCTION IF EXISTS get_inactive_winback_candidates();

-- Update engagement RPCs to return onboarding_agent
CREATE OR REPLACE FUNCTION get_no_mission_nudge_candidates()
RETURNS TABLE (device_id TEXT, apns_token TEXT, language TEXT, timezone TEXT, onboarding_agent TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.device_id, d.apns_token, d.language, d.timezone, d.onboarding_agent
    FROM yap_devices d
    WHERE d.created_at > '2026-04-13T00:00:00Z'::timestamptz
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

CREATE OR REPLACE FUNCTION get_inactive_winback_candidates()
RETURNS TABLE (device_id TEXT, apns_token TEXT, language TEXT, timezone TEXT, onboarding_agent TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT d.device_id, d.apns_token, d.language, d.timezone, d.onboarding_agent
    FROM yap_devices d
    WHERE d.created_at > '2026-04-13T00:00:00Z'::timestamptz
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

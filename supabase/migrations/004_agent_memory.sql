-- ============================================
-- Agent Memory: Last missions per agent for a device
-- Returns the last 5 completed/given_up missions for a specific agent.
-- Used by Special Agents to reference past missions in their messages.
-- ============================================

CREATE OR REPLACE FUNCTION get_agent_memory(p_device_id TEXT, p_agent TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(row_to_json(t) ORDER BY t.created_at DESC)
    INTO result
    FROM (
        SELECT
            title,
            status,
            time_to_complete_minutes,
            created_at::TEXT
        FROM yap_goals
        WHERE device_id = p_device_id
          AND agent = p_agent
          AND status IN ('completed', 'given_up')
        ORDER BY created_at DESC
        LIMIT 5
    ) t;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

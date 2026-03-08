-- ============================================
-- Global Agent Leaderboard
-- Aggregates mission stats across ALL users per agent.
-- Returns: agent, completed, given_up, total, success_rate, total_users
-- SECURITY DEFINER: bypasses RLS to read all rows.
-- ============================================

CREATE OR REPLACE FUNCTION get_global_agent_leaderboard()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(row_to_json(t) ORDER BY t.success_rate DESC NULLS LAST, t.total DESC)
    INTO result
    FROM (
        SELECT
            agent,
            COUNT(*) FILTER (WHERE status = 'completed') AS completed,
            COUNT(*) FILTER (WHERE status = 'given_up')  AS given_up,
            COUNT(*) FILTER (WHERE status IN ('completed', 'given_up')) AS total,
            COUNT(DISTINCT device_id) AS total_users,
            CASE
                WHEN COUNT(*) FILTER (WHERE status IN ('completed', 'given_up')) > 0
                THEN ROUND(
                    100.0 * COUNT(*) FILTER (WHERE status = 'completed')
                    / COUNT(*) FILTER (WHERE status IN ('completed', 'given_up')), 1
                )
                ELSE 0
            END AS success_rate,
            ROUND(AVG(time_to_complete_minutes) FILTER (WHERE status = 'completed'))::INT AS avg_minutes
        FROM yap_goals
        WHERE agent IS NOT NULL
          AND status IN ('completed', 'given_up')
        GROUP BY agent
    ) t;

    RETURN COALESCE(result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

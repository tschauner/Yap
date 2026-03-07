-- ============================================
-- Yap: Komplettes DB-Schema (Clean Setup)
-- ============================================
-- Tabelle: yap_goals (Missions + Queue)
-- RPCs: activate_next_goal, reorder_queue, get_device_stats
-- RLS: Device-ID basiert (x-device-id Header)
-- ============================================

-- Alte Objekte droppen
DROP FUNCTION IF EXISTS get_device_stats(TEXT);
DROP FUNCTION IF EXISTS activate_next_goal(TEXT);
DROP FUNCTION IF EXISTS activate_next_goal(TEXT, TEXT);
DROP FUNCTION IF EXISTS reorder_queue(TEXT, UUID[]);
DROP VIEW IF EXISTS yap_device_stats;
DROP TABLE IF EXISTS yap_goals;

-- ============================================
-- Tabelle
-- ============================================
CREATE TABLE yap_goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id       TEXT NOT NULL,
    title           TEXT NOT NULL,
    agent           TEXT,                       -- NULL bei Queue-Items, gesetzt bei aktiven Missions
    language        TEXT DEFAULT 'en',
    status          TEXT NOT NULL DEFAULT 'queued',  -- queued | active | completed | given_up

    -- Timestamps
    created_at      TIMESTAMPTZ DEFAULT now(),
    deadline        TIMESTAMPTZ,                -- Bis wann (Default: Mitternacht)
    completed_at    TIMESTAMPTZ,
    given_up_at     TIMESTAMPTZ,

    -- Mission-Details
    extended        BOOLEAN DEFAULT false,
    notifications_scheduled INT DEFAULT 0,
    notifications_sent      INT DEFAULT 0,
    escalation_level_at_completion INT,
    time_to_complete_minutes       INT,

    -- Pro
    is_pro          BOOLEAN DEFAULT false,
    used_ai_copy    BOOLEAN DEFAULT false
);

-- Indizes
CREATE INDEX idx_yap_device        ON yap_goals(device_id);
CREATE INDEX idx_yap_device_status ON yap_goals(device_id, status, created_at);

-- ============================================
-- RLS (Row Level Security)
-- ============================================
ALTER TABLE yap_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_select" ON yap_goals FOR SELECT
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

CREATE POLICY "device_insert" ON yap_goals FOR INSERT
    WITH CHECK (device_id = current_setting('request.headers')::json->>'x-device-id');

CREATE POLICY "device_update" ON yap_goals FOR UPDATE
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

CREATE POLICY "device_delete" ON yap_goals FOR DELETE
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

-- ============================================
-- RPC: Queue-Item aktivieren → wird zur Mission
-- ============================================
CREATE OR REPLACE FUNCTION activate_next_goal(
    p_device_id TEXT,
    p_agent TEXT DEFAULT NULL,
    p_deadline TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    next_id UUID;
BEGIN
    -- Ältestes Queue-Item holen
    SELECT id INTO next_id
    FROM yap_goals
    WHERE device_id = p_device_id AND status = 'queued'
    ORDER BY created_at ASC
    LIMIT 1;

    IF next_id IS NOT NULL THEN
        UPDATE yap_goals
        SET status = 'active',
            agent = COALESCE(p_agent, agent),
            deadline = COALESCE(p_deadline, (CURRENT_DATE + INTERVAL '1 day' - INTERVAL '1 second'))
        WHERE id = next_id;
    END IF;

    RETURN next_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC: Device Stats
-- ============================================
CREATE OR REPLACE FUNCTION get_device_stats(p_device_id TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
    streak INT;
    check_date DATE := CURRENT_DATE;
    has_day BOOLEAN;
BEGIN
    -- Streak: aufeinanderfolgende Tage mit mind. 1 completed Mission
    streak := 0;
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM yap_goals
            WHERE device_id = p_device_id
              AND status = 'completed'
              AND completed_at::date = check_date
        ) INTO has_day;

        EXIT WHEN NOT has_day;
        streak := streak + 1;
        check_date := check_date - 1;
    END LOOP;

    SELECT json_build_object(
        'total_completed', COUNT(*) FILTER (WHERE status = 'completed'),
        'total_given_up',  COUNT(*) FILTER (WHERE status = 'given_up'),
        'total_pending',   COUNT(*) FILTER (WHERE status IN ('active', 'queued')),
        'total_missions',  COUNT(*),
        'avg_minutes',     ROUND(AVG(time_to_complete_minutes) FILTER (WHERE status = 'completed'))::INT,
        'fastest_minutes', MIN(time_to_complete_minutes) FILTER (WHERE status = 'completed'),
        'slowest_minutes', MAX(time_to_complete_minutes) FILTER (WHERE status = 'completed'),
        'completion_rate', CASE
            WHEN COUNT(*) FILTER (WHERE status IN ('completed', 'given_up')) > 0
            THEN ROUND(
                100.0 * COUNT(*) FILTER (WHERE status = 'completed')
                / COUNT(*) FILTER (WHERE status IN ('completed', 'given_up')), 1
            ) ELSE 0 END,
        'current_streak',  streak,
        'favorite_agent',  (
            SELECT agent FROM yap_goals
            WHERE device_id = p_device_id AND agent IS NOT NULL AND status = 'completed'
            GROUP BY agent ORDER BY COUNT(*) DESC LIMIT 1
        )
    ) INTO result
    FROM yap_goals
    WHERE device_id = p_device_id;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

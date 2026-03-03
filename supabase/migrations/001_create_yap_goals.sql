-- Yap: Goal Tracking Table
-- Für Statistiken: wie viele Pushes braucht der User, was wird erledigt, etc.

CREATE TABLE IF NOT EXISTS yap_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    title TEXT NOT NULL,
    tone TEXT NOT NULL,          -- friendly, coach, drill, passive, chaos
    language TEXT DEFAULT 'en',
    
    -- Lifecycle
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    given_up_at TIMESTAMPTZ,
    
    -- Statistiken
    notifications_scheduled INT DEFAULT 0,   -- Wie viele geplant
    notifications_sent INT DEFAULT 0,        -- Wie viele tatsächlich geliefert (approx)
    escalation_level_at_completion INT,      -- Auf welchem Level erledigt (0-4)
    time_to_complete_minutes INT,            -- Minuten von created → completed
    
    -- Pro
    is_pro BOOLEAN DEFAULT false,
    used_ai_copy BOOLEAN DEFAULT false
);

-- Index für Device-Abfragen
CREATE INDEX idx_yap_goals_device ON yap_goals(device_id);
CREATE INDEX idx_yap_goals_created ON yap_goals(created_at DESC);

-- RLS aktivieren
ALTER TABLE yap_goals ENABLE ROW LEVEL SECURITY;

-- Policy: Jedes Device sieht nur seine eigenen Goals
CREATE POLICY "Device can read own goals"
    ON yap_goals FOR SELECT
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

CREATE POLICY "Device can insert own goals"
    ON yap_goals FOR INSERT
    WITH CHECK (device_id = current_setting('request.headers')::json->>'x-device-id');

CREATE POLICY "Device can update own goals"
    ON yap_goals FOR UPDATE
    USING (device_id = current_setting('request.headers')::json->>'x-device-id');

-- ============================================
-- Nützliche Queries für später:
-- ============================================

-- Durchschnittliche Notifications bis Completion, pro Tone:
-- SELECT tone, AVG(notifications_sent) as avg_pushes, AVG(time_to_complete_minutes) as avg_minutes
-- FROM yap_goals WHERE completed_at IS NOT NULL
-- GROUP BY tone ORDER BY avg_pushes;

-- Completion Rate pro Tone:
-- SELECT tone,
--   COUNT(*) FILTER (WHERE completed_at IS NOT NULL) as completed,
--   COUNT(*) FILTER (WHERE given_up_at IS NOT NULL) as given_up,
--   COUNT(*) as total,
--   ROUND(100.0 * COUNT(*) FILTER (WHERE completed_at IS NOT NULL) / COUNT(*), 1) as completion_rate
-- FROM yap_goals GROUP BY tone;

-- Beliebteste Goals (Wordcloud-Data):
-- SELECT title, COUNT(*) as count FROM yap_goals GROUP BY title ORDER BY count DESC LIMIT 50;

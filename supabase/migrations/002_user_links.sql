-- ============================================
-- User Links: Apple ID ↔ Device ID Mapping
-- ============================================
-- Ermöglicht optionales Apple Sign-In
-- Bei Login auf neuem Gerät wird alte Device-ID wiederhergestellt
-- ============================================

-- Tabelle für User-Links
CREATE TABLE IF NOT EXISTS yap_user_links (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_user_id   TEXT UNIQUE NOT NULL,       -- Apple's stable userIdentifier
    device_id       TEXT NOT NULL,              -- Die verknüpfte Device-ID
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Index für schnelle Lookups
CREATE INDEX IF NOT EXISTS idx_user_links_apple ON yap_user_links(apple_user_id);
CREATE INDEX IF NOT EXISTS idx_user_links_device ON yap_user_links(device_id);

-- ============================================
-- RPC: Link Device to Apple User
-- Verknüpft eine Device-ID mit einem Apple User
-- Falls bereits verknüpft, gibt die existierende Device-ID zurück
-- ============================================
CREATE OR REPLACE FUNCTION link_apple_user(
    p_apple_user_id TEXT,
    p_current_device_id TEXT
)
RETURNS JSON AS $$
DECLARE
    existing_link yap_user_links%ROWTYPE;
    result JSON;
BEGIN
    -- Prüfe ob Apple User bereits verknüpft ist
    SELECT * INTO existing_link
    FROM yap_user_links
    WHERE apple_user_id = p_apple_user_id;
    
    IF existing_link.id IS NOT NULL THEN
        -- User ist bereits verknüpft
        IF existing_link.device_id = p_current_device_id THEN
            -- Gleiche Device-ID, nichts zu tun
            result := json_build_object(
                'status', 'already_linked',
                'device_id', existing_link.device_id,
                'migrated', false
            );
        ELSE
            -- Andere Device-ID → User hat neues Gerät
            -- Gib die alte Device-ID zurück für Migration
            result := json_build_object(
                'status', 'restored',
                'device_id', existing_link.device_id,
                'migrated', true
            );
        END IF;
    ELSE
        -- Neuer Link erstellen
        INSERT INTO yap_user_links (apple_user_id, device_id)
        VALUES (p_apple_user_id, p_current_device_id);
        
        result := json_build_object(
            'status', 'linked',
            'device_id', p_current_device_id,
            'migrated', false
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC: Get linked Device ID for Apple User
-- ============================================
CREATE OR REPLACE FUNCTION get_linked_device(p_apple_user_id TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT device_id FROM yap_user_links WHERE apple_user_id = p_apple_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC: Unlink Apple User
-- ============================================
CREATE OR REPLACE FUNCTION unlink_apple_user(p_apple_user_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM yap_user_links WHERE apple_user_id = p_apple_user_id;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

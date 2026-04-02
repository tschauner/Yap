-- ============================================
-- Delete Account: Remove ALL user data by device_id
-- ============================================
-- Required by App Store Review (Guideline 5.1.1v)
-- Deletes: notifications, goals, device registration, apple link
-- ============================================

CREATE OR REPLACE FUNCTION delete_account(p_device_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- 1. Delete scheduled notifications
    DELETE FROM yap_notifications WHERE device_id = p_device_id;
    
    -- 2. Delete all goals/missions
    DELETE FROM yap_goals WHERE device_id = p_device_id;
    
    -- 3. Delete device registration (push token etc.)
    DELETE FROM yap_devices WHERE device_id = p_device_id;
    
    -- 4. Delete Apple ID link (if any)
    DELETE FROM yap_user_links WHERE device_id = p_device_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Fix: Enable RLS on public tables
-- ============================================

-- ── waitlist ────────────────────────────────
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- Anyone can insert (website signup form uses anon key)
CREATE POLICY "waitlist_insert" ON public.waitlist
    FOR INSERT
    WITH CHECK (true);

-- No select/update/delete via anon — only service_role can read
-- (Supabase Dashboard / Edge Functions use service_role automatically)

-- ── yap_user_links ─────────────────────────
ALTER TABLE public.yap_user_links ENABLE ROW LEVEL SECURITY;

-- The link_apple_user() RPC runs as SECURITY DEFINER, so it bypasses RLS.
-- No direct table access needed from the client.
-- If direct access is ever needed, add device_id-based policies here.

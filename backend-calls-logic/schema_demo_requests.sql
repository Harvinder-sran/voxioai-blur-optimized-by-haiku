-- ════════════════════════════════════════════════════════════════════════════
-- demo_requests table
-- Already deployed to Supabase (project ref: knuilvlrimxmwpuvqtdj)
-- Shown here for reference only. Do NOT re-run unless rebuilding from scratch.
--
-- Purpose: rate-limit ledger for the public "call me now" demo form.
-- The backend writes to this table using the service-role key.
-- The frontend NEVER reads or writes this table directly.
-- ════════════════════════════════════════════════════════════════════════════

-- ── demo_requests (public website "call me now" demo) ──────────────────────
-- Powers POST /api/demo-call: lead capture + anti-abuse quota
-- (1 call / number / DEMO_COOLDOWN_MIN + DEMO_DAILY_CAP / 24h).
-- Backend-only — written via the service-role db_admin (bypasses RLS). No client
-- policy on purpose: nothing client-facing should read or write this table.
CREATE TABLE IF NOT EXISTS demo_requests (
    id          UUID PRIMARY KEY,
    name        TEXT,
    email       TEXT,
    phone       TEXT NOT NULL,
    ip          TEXT,
    source      TEXT,
    status      TEXT DEFAULT 'queued',   -- queued | calling | failed
    room        TEXT,
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_demo_requests_phone_created ON demo_requests (phone, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_demo_requests_created       ON demo_requests (created_at DESC);
ALTER TABLE demo_requests ENABLE ROW LEVEL SECURITY;
-- No RLS policy — service role only. Browser cannot read/write this table.


-- ── Supabase connection details (for reference) ─────────────────────────────
-- Project URL:      https://knuilvlrimxmwpuvqtdj.supabase.co
-- Project ref:      knuilvlrimxmwpuvqtdj
-- Region:           AWS ap-south-1 (Mumbai)
-- Anon key:         eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudWlsdmxyaW14bXdwdXZxdGRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MzQ4NTAsImV4cCI6MjA5NTIxMDg1MH0.pqeNxWoqYUpf3ygxrH9lZMIIIMPEYNnuHD9DfYHfT1s
-- Service role key: (server-only, see Claude memory reference_voxioai_credentials.md)

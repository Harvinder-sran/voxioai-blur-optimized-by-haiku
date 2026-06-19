-- ════════════════════════════════════════════════════════════════════════════
-- VoxioAI — Complete Database Schema (v1)
-- Run once in Supabase Dashboard → SQL Editor (or `supabase db push`)
-- All statements use IF NOT EXISTS / IF NOT EXISTS-equivalent — safe to re-run.
--
-- Structure:
--   1. Extensions
--   2. Ported tables from VoxEngine (14)
--   3. New tables for VoxioAI (11)
--   4. RLS enable + helper function
--   5. RLS policies
-- ════════════════════════════════════════════════════════════════════════════


-- ── 0. Extensions ─────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ════════════════════════════════════════════════════════════════════════════
-- PART A — TABLES PORTED FROM VOXENGINE (with VoxioAI-specific column adds)
-- ════════════════════════════════════════════════════════════════════════════


-- ── 1. clients (multi-tenancy + trial tracking) ───────────────────────────

CREATE TABLE IF NOT EXISTS clients (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                     TEXT NOT NULL,
    email                    TEXT UNIQUE NOT NULL,
    region                   TEXT NOT NULL DEFAULT 'mumbai' CHECK (region IN ('mumbai','eu','us')),
    features                 JSONB DEFAULT '{"ai_summary": true, "recordings": true}'::jsonb,
    auth_user_id             UUID,                                     -- maps to auth.users.id
    notes                    TEXT,
    -- Public-signup + trial fields (NEW vs VoxEngine)
    plan_type                TEXT NOT NULL DEFAULT 'trial' CHECK (plan_type IN ('trial','paid','suspended')),
    trial_minutes_remaining  REAL DEFAULT 15.0,
    trial_started_at         TIMESTAMPTZ,
    trial_expired_at         TIMESTAMPTZ,
    signup_source            TEXT NOT NULL DEFAULT 'admin_created' CHECK (signup_source IN ('admin_created','public_signup')),
    signup_company           TEXT,
    signup_intent            TEXT,
    created_at               TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_clients_auth_user ON clients (auth_user_id);
CREATE INDEX IF NOT EXISTS idx_clients_plan_type ON clients (plan_type);

-- Defensive ALTERs in case a stale `clients` table exists from earlier runs
ALTER TABLE clients ADD COLUMN IF NOT EXISTS plan_type TEXT DEFAULT 'trial';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS trial_minutes_remaining REAL DEFAULT 15.0;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMPTZ;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS trial_expired_at TIMESTAMPTZ;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS signup_source TEXT DEFAULT 'admin_created';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS signup_company TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS signup_intent TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS notes TEXT;


-- ── 2. agents (with VoxioAI-specific columns) ─────────────────────────────

CREATE TABLE IF NOT EXISTS agents (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id                   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    name                        TEXT NOT NULL,
    voice                       TEXT DEFAULT 'Aoede',
    model                       TEXT DEFAULT 'gemini-3.1-flash-live-preview',
    system_prompt               TEXT,
    enabled_tools               JSONB DEFAULT '[]'::jsonb,
    n8n_webhook_url             TEXT,
    status                      TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published')),
    region                      TEXT NOT NULL DEFAULT 'mumbai' CHECK (region IN ('mumbai','eu','us')),
    -- VoxioAI-new columns (call behaviour)
    voicemail_action            TEXT DEFAULT 'hang_up' CHECK (voicemail_action IN ('hang_up','leave_recording','leave_custom')),
    voicemail_message_template  TEXT,
    voicemail_audio_url         TEXT,
    recording_consent_enabled   BOOLEAN DEFAULT false,
    recording_consent_message   TEXT DEFAULT 'This call may be recorded for quality purposes.',
    kb_enabled                  BOOLEAN DEFAULT false,
    transfer_enabled            BOOLEAN DEFAULT false,
    cal_com_event_type_id       TEXT,
    caller_memory_enabled       BOOLEAN DEFAULT false,
    caller_id_enabled           BOOLEAN DEFAULT false,   -- auto-detect + inject the caller's number ({{caller_number}})
    current_version_number      INT DEFAULT 1,
    -- VoxioAI-new columns (demo flagging for public funnel)
    is_demo                     BOOLEAN DEFAULT false,
    demo_category               TEXT CHECK (demo_category IN ('restaurant','clinic','pitch','outbound_sales')),
    created_at                  TIMESTAMPTZ DEFAULT now(),
    updated_at                  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_agents_client ON agents (client_id);
CREATE INDEX IF NOT EXISTS idx_agents_region_status ON agents (region, status);
CREATE INDEX IF NOT EXISTS idx_agents_is_demo ON agents (is_demo) WHERE is_demo = true;

-- Defensive ALTERs
ALTER TABLE agents ADD COLUMN IF NOT EXISTS voicemail_action TEXT DEFAULT 'hang_up';
ALTER TABLE agents ADD COLUMN IF NOT EXISTS voicemail_message_template TEXT;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS voicemail_audio_url TEXT;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS recording_consent_enabled BOOLEAN DEFAULT false;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS recording_consent_message TEXT DEFAULT 'This call may be recorded for quality purposes.';
ALTER TABLE agents ADD COLUMN IF NOT EXISTS kb_enabled BOOLEAN DEFAULT false;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS transfer_enabled BOOLEAN DEFAULT false;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS cal_com_event_type_id TEXT;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS caller_memory_enabled BOOLEAN DEFAULT false;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS caller_id_enabled BOOLEAN DEFAULT false;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS current_version_number INT DEFAULT 1;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;
ALTER TABLE agents ADD COLUMN IF NOT EXISTS demo_category TEXT;


-- ── 3. agent_drafts (playground edits before Publish) ─────────────────────

CREATE TABLE IF NOT EXISTS agent_drafts (
    agent_id        UUID PRIMARY KEY REFERENCES agents(id) ON DELETE CASCADE,
    voice           TEXT,
    model           TEXT,
    system_prompt   TEXT,
    enabled_tools   JSONB,
    updated_at      TIMESTAMPTZ DEFAULT now()
);


-- ── 4. phone_numbers ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS phone_numbers (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number            TEXT UNIQUE NOT NULL,                            -- E.164 (+919876543210)
    provider          TEXT NOT NULL CHECK (provider IN ('vobiz','twilio','telnyx')),
    region            TEXT NOT NULL DEFAULT 'mumbai' CHECK (region IN ('mumbai','eu','us')),
    sip_trunk_id      TEXT,                                            -- LiveKit outbound trunk ID
    inbound_trunk_id  TEXT,                                            -- LiveKit inbound trunk ID
    agent_id          UUID REFERENCES agents(id) ON DELETE SET NULL,
    inbound_enabled   BOOLEAN DEFAULT true,
    outbound_enabled  BOOLEAN DEFAULT true,
    ivr_menu_id       UUID,                                            -- FK added in PART B (forward reference)
    created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_phone_numbers_agent ON phone_numbers (agent_id);

ALTER TABLE phone_numbers ADD COLUMN IF NOT EXISTS ivr_menu_id UUID;


-- ── 5. routing_rules (legacy time/day windows) ────────────────────────────
-- Kept for forward compatibility. New schedule logic uses agent_working_hours.

CREATE TABLE IF NOT EXISTS routing_rules (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    direction     TEXT NOT NULL CHECK (direction IN ('inbound','outbound','both')),
    days_of_week  INT[] DEFAULT ARRAY[1,2,3,4,5,6,7],                  -- 1=Mon ... 7=Sun
    start_time    TIME NOT NULL DEFAULT '00:00',
    end_time      TIME NOT NULL DEFAULT '23:59',
    timezone      TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    action        TEXT NOT NULL DEFAULT 'allow' CHECK (action IN ('allow','reject')),
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_routing_rules_agent ON routing_rules (agent_id);


-- ── 6. agent_webhooks ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS agent_webhooks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id    UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    event       TEXT NOT NULL CHECK (event IN ('call_started','call_completed','tool_called')),
    url         TEXT NOT NULL,
    enabled     BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_agent_webhooks_agent_event ON agent_webhooks (agent_id, event);


-- ── 7. api_keys ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS api_keys (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    key_hash    TEXT UNIQUE NOT NULL,                                  -- bcrypt of actual key
    label       TEXT,
    last_used   TIMESTAMPTZ,
    enabled     BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_api_keys_client ON api_keys (client_id);


-- ── 8. call_logs (with VoxioAI-new columns) ───────────────────────────────

CREATE TABLE IF NOT EXISTS call_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id           UUID REFERENCES clients(id) ON DELETE SET NULL,
    agent_id            UUID REFERENCES agents(id) ON DELETE SET NULL,
    direction           TEXT CHECK (direction IN ('inbound','outbound')),
    phone_number        TEXT NOT NULL,
    lead_name           TEXT,
    outcome             TEXT,
    reason              TEXT,
    duration_seconds    INTEGER,
    transcript          TEXT,
    ai_summary          TEXT,
    recording_url       TEXT,
    notes               TEXT,
    room_name           TEXT,
    sip_uuid            TEXT,
    -- VoxioAI-new columns
    voicemail_detected  BOOLEAN DEFAULT false,
    transferred_to      TEXT,
    consent_played      BOOLEAN DEFAULT false,
    sentiment_score     REAL,
    is_test             BOOLEAN DEFAULT false,
    timestamp           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_call_logs_client_ts ON call_logs (client_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_call_logs_agent_ts ON call_logs (agent_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_call_logs_phone ON call_logs (phone_number);
CREATE INDEX IF NOT EXISTS idx_call_logs_outcome ON call_logs (outcome);
CREATE INDEX IF NOT EXISTS idx_call_logs_is_test ON call_logs (is_test) WHERE is_test = true;

ALTER TABLE call_logs ADD COLUMN IF NOT EXISTS voicemail_detected BOOLEAN DEFAULT false;
ALTER TABLE call_logs ADD COLUMN IF NOT EXISTS transferred_to TEXT;
ALTER TABLE call_logs ADD COLUMN IF NOT EXISTS consent_played BOOLEAN DEFAULT false;
ALTER TABLE call_logs ADD COLUMN IF NOT EXISTS sentiment_score REAL;
ALTER TABLE call_logs ADD COLUMN IF NOT EXISTS is_test BOOLEAN DEFAULT false;


-- ── 9. appointments ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS appointments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID REFERENCES clients(id) ON DELETE SET NULL,
    agent_id    UUID REFERENCES agents(id) ON DELETE SET NULL,
    name        TEXT NOT NULL,
    phone       TEXT NOT NULL,
    date        TEXT NOT NULL,
    time        TEXT NOT NULL,
    service     TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'booked',
    cal_com_booking_id TEXT,                                           -- track Cal.com side
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_appointments_client ON appointments (client_id);
CREATE INDEX IF NOT EXISTS idx_appointments_phone ON appointments (phone);

ALTER TABLE appointments ADD COLUMN IF NOT EXISTS cal_com_booking_id TEXT;


-- ── 10. contact_memory ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS contact_memory (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id     UUID REFERENCES clients(id) ON DELETE CASCADE,
    phone_number  TEXT NOT NULL,
    insight       TEXT NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_contact_memory_client_phone ON contact_memory (client_id, phone_number);


-- ── 11. campaigns (with VoxioAI-new scheduling columns) ───────────────────

CREATE TABLE IF NOT EXISTS campaigns (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id             UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    agent_id              UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    name                  TEXT NOT NULL,
    status                TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','paused','completed','scheduled','stopped')),
    contacts_json         JSONB NOT NULL DEFAULT '[]'::jsonb,
    schedule_type         TEXT NOT NULL DEFAULT 'once' CHECK (schedule_type IN ('once','daily','weekdays','recurring')),
    schedule_time         TEXT DEFAULT '09:00',
    timezone              TEXT DEFAULT 'Asia/Kolkata',
    call_delay_seconds    INTEGER DEFAULT 3,
    total_dispatched      INTEGER DEFAULT 0,
    total_failed          INTEGER DEFAULT 0,
    last_run_at           TIMESTAMPTZ,
    -- VoxioAI-new scheduling + retry fields
    retry_config          JSONB DEFAULT '{"max_attempts": 1, "retry_delay_hours": 4, "retry_on": ["no_answer"]}'::jsonb,
    concurrent_limit      INT DEFAULT 1,
    business_hours_start  TIME DEFAULT '10:00',
    business_hours_end    TIME DEFAULT '19:00',
    business_days         INT[] DEFAULT ARRAY[1,2,3,4,5,6],            -- 1=Mon..7=Sun
    scheduled_start_at    TIMESTAMPTZ,
    -- Safety controls for the dialer. dry_run simulates attempts (no calls
    -- placed) so the state machine can be validated; max_calls caps how many
    -- attempts a campaign may ever dial (NULL = unlimited).
    dry_run               BOOLEAN DEFAULT false,
    max_calls             INT,
    created_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_campaigns_client ON campaigns (client_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns (status);

ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS retry_config JSONB DEFAULT '{"max_attempts": 1, "retry_delay_hours": 4, "retry_on": ["no_answer"]}'::jsonb;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS concurrent_limit INT DEFAULT 1;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS business_hours_start TIME DEFAULT '10:00';
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS business_hours_end TIME DEFAULT '19:00';
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS business_days INT[] DEFAULT ARRAY[1,2,3,4,5,6];
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS scheduled_start_at TIMESTAMPTZ;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS dry_run BOOLEAN DEFAULT false;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS max_calls INT;


-- ── 12. regional_servers (kept for future EU/US expansion) ────────────────

CREATE TABLE IF NOT EXISTS regional_servers (
    region          TEXT PRIMARY KEY CHECK (region IN ('mumbai','eu','us')),
    api_url         TEXT NOT NULL,
    livekit_url     TEXT NOT NULL,
    sip_domain      TEXT,
    shared_secret   TEXT NOT NULL,
    enabled         BOOLEAN DEFAULT true,
    last_seen       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT now()
);


-- ── 13. error_logs ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS error_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   UUID REFERENCES clients(id) ON DELETE SET NULL,
    source      TEXT NOT NULL,
    level       TEXT NOT NULL DEFAULT 'error' CHECK (level IN ('info','warning','error')),
    message     TEXT NOT NULL,
    detail      TEXT,
    timestamp   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_error_logs_client_ts ON error_logs (client_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_error_logs_level ON error_logs (level);


-- ── 14. settings (admin global key/value) ─────────────────────────────────

CREATE TABLE IF NOT EXISTS settings (
    key         TEXT PRIMARY KEY,
    value       TEXT NOT NULL,
    updated_at  TIMESTAMPTZ DEFAULT now()
);


-- ── 14b. request_logs (per-request access log, client attribution) ────────
-- Every API request is buffered in-process and bulk-flushed here for
-- traceability ("who called what, and did it fail?"). 14-day retention via
-- request_logs_cleanup_tick. user_id is the Supabase auth sub (stored as TEXT,
-- not FK, since requests can be unauthenticated).

CREATE TABLE IF NOT EXISTS request_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id   TEXT,
    method       TEXT,
    path         TEXT,
    status_code  INT,
    duration_ms  INT,
    user_id      TEXT,
    user_email   TEXT,
    ip           TEXT,
    timestamp    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_request_logs_ts ON request_logs (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_request_logs_user ON request_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_request_logs_status ON request_logs (status_code);


-- ════════════════════════════════════════════════════════════════════════════
-- PART B — NEW VOXIOAI TABLES (11)
-- ════════════════════════════════════════════════════════════════════════════


-- ── 15. dnc_list (per-client do-not-call list) ────────────────────────────

CREATE TABLE IF NOT EXISTS dnc_list (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id     UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    phone_number  TEXT NOT NULL,
    reason        TEXT,
    source        TEXT CHECK (source IN ('manual_upload','customer_request','admin')),
    added_at      TIMESTAMPTZ DEFAULT now(),
    added_by      UUID,
    UNIQUE (client_id, phone_number)
);
CREATE INDEX IF NOT EXISTS idx_dnc_list_client ON dnc_list (client_id);
CREATE INDEX IF NOT EXISTS idx_dnc_list_phone ON dnc_list (phone_number);


-- ── 16. kb_documents (knowledge base documents per agent) ─────────────────

CREATE TABLE IF NOT EXISTS kb_documents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    source_type   TEXT NOT NULL CHECK (source_type IN ('pdf','text','url')),
    original_url  TEXT,
    uploaded_at   TIMESTAMPTZ DEFAULT now(),
    size_bytes    BIGINT,
    chunk_count   INT DEFAULT 0,
    status        TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing','ready','failed'))
);
CREATE INDEX IF NOT EXISTS idx_kb_documents_agent ON kb_documents (agent_id);


-- ── 17. kb_chunks (vector embeddings for RAG) ─────────────────────────────

CREATE TABLE IF NOT EXISTS kb_chunks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id   UUID NOT NULL REFERENCES kb_documents(id) ON DELETE CASCADE,
    chunk_text    TEXT NOT NULL,
    embedding     vector(1536),                                        -- OpenAI text-embedding-3-small dims; switch to 768/3072 if using Gemini
    metadata      JSONB DEFAULT '{}'::jsonb,
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_kb_chunks_document ON kb_chunks (document_id);
CREATE INDEX IF NOT EXISTS idx_kb_chunks_embedding ON kb_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);


-- ── 18. campaign_attempts (one row per contact × attempt) ─────────────────

CREATE TABLE IF NOT EXISTS campaign_attempts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id     UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    contact_index   INT NOT NULL,
    contact_data    JSONB NOT NULL,
    attempt_number  INT DEFAULT 1,
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','dialing','completed','failed','voicemail','no_answer','busy','dnc_blocked','outside_hours')),
    call_log_id     UUID REFERENCES call_logs(id) ON DELETE SET NULL,
    attempted_at    TIMESTAMPTZ,
    next_retry_at   TIMESTAMPTZ,
    error_message   TEXT,
    created_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_campaign_attempts_campaign ON campaign_attempts (campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_campaign_attempts_retry ON campaign_attempts (next_retry_at) WHERE next_retry_at IS NOT NULL;


-- ── 19. team_members (per-client team accounts with roles) ────────────────

CREATE TABLE IF NOT EXISTS team_members (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id     UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    auth_user_id  UUID NOT NULL,                                       -- maps to auth.users.id
    role          TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('owner','editor','viewer')),
    invited_by    UUID,
    invited_at    TIMESTAMPTZ DEFAULT now(),
    accepted_at   TIMESTAMPTZ,
    UNIQUE (client_id, auth_user_id)
);
CREATE INDEX IF NOT EXISTS idx_team_members_client ON team_members (client_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON team_members (auth_user_id);


-- ── 20. notification_preferences ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notification_preferences (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL,                                         -- auth.users.id
    channel     TEXT NOT NULL CHECK (channel IN ('email','whatsapp')),
    event_type  TEXT NOT NULL CHECK (event_type IN ('daily_summary','campaign_completed','agent_error','high_intent_call')),
    target      TEXT NOT NULL,                                         -- email or phone E.164
    enabled     BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE (user_id, channel, event_type)
);
CREATE INDEX IF NOT EXISTS idx_notif_prefs_user ON notification_preferences (user_id);


-- ── 21. ivr_menus (simple 1-2 level IVR per phone number) ─────────────────

CREATE TABLE IF NOT EXISTS ivr_menus (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number_id   UUID NOT NULL REFERENCES phone_numbers(id) ON DELETE CASCADE,
    greeting_text     TEXT NOT NULL,
    options           JSONB NOT NULL,                                  -- [{key:"1", label:"English", agent_id:"..."}]
    timeout_seconds   INT DEFAULT 5,
    fallback_agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
    created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ivr_menus_phone ON ivr_menus (phone_number_id);

-- Now backfill the FK on phone_numbers.ivr_menu_id (forward reference)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'phone_numbers_ivr_menu_id_fkey'
    ) THEN
        ALTER TABLE phone_numbers
            ADD CONSTRAINT phone_numbers_ivr_menu_id_fkey
            FOREIGN KEY (ivr_menu_id) REFERENCES ivr_menus(id) ON DELETE SET NULL;
    END IF;
END $$;


-- ── 22. agent_working_hours (per-day schedule per agent) ──────────────────

CREATE TABLE IF NOT EXISTS agent_working_hours (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id      UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    day_of_week   INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),    -- 1=Mon..7=Sun
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    timezone      TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    UNIQUE (agent_id, day_of_week)
);
CREATE INDEX IF NOT EXISTS idx_agent_working_hours_agent ON agent_working_hours (agent_id);


-- ── 23. transfer_destinations (cold/warm transfer targets per agent) ──────

CREATE TABLE IF NOT EXISTS transfer_destinations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id          UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    transfer_type     TEXT NOT NULL DEFAULT 'cold' CHECK (transfer_type IN ('cold','warm')),
    target_number     TEXT NOT NULL,                                   -- E.164
    label             TEXT,
    trigger_keywords  TEXT[],
    created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_transfer_destinations_agent ON transfer_destinations (agent_id);


-- ── 24. agent_prompt_versions (immutable history on every Publish) ────────

CREATE TABLE IF NOT EXISTS agent_prompt_versions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id        UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    version_number  INT NOT NULL,
    system_prompt   TEXT NOT NULL,
    voice           TEXT,
    model           TEXT,
    enabled_tools   JSONB,
    published_at    TIMESTAMPTZ DEFAULT now(),
    published_by    UUID,
    notes           TEXT,
    UNIQUE (agent_id, version_number)
);
CREATE INDEX IF NOT EXISTS idx_agent_prompt_versions_agent ON agent_prompt_versions (agent_id, published_at DESC);


-- ── 25. agent_test_sessions (admin/trial playground session log) ──────────

CREATE TABLE IF NOT EXISTS agent_test_sessions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id           UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    tester_user_id     UUID NOT NULL,
    test_variables     JSONB,
    transcript         JSONB,
    tool_invocations   JSONB,
    duration_seconds   INT,
    started_at         TIMESTAMPTZ DEFAULT now(),
    ended_at           TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_test_sessions_agent ON agent_test_sessions (agent_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_test_sessions_tester ON agent_test_sessions (tester_user_id);


-- ════════════════════════════════════════════════════════════════════════════
-- PART C — ROW-LEVEL SECURITY
-- Service role bypasses RLS (backend, agent worker, regional servers).
-- Authenticated browser users only see rows scoped to their client_id.
-- ════════════════════════════════════════════════════════════════════════════

-- Enable RLS on tenant-scoped tables
ALTER TABLE clients                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_drafts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE phone_numbers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE routing_rules            ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_webhooks           ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_logs                ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments             ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_memory           ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns                ENABLE ROW LEVEL SECURITY;
ALTER TABLE dnc_list                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE kb_documents             ENABLE ROW LEVEL SECURITY;
ALTER TABLE kb_chunks                ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_attempts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members             ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE ivr_menus                ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_working_hours      ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfer_destinations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_prompt_versions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_test_sessions      ENABLE ROW LEVEL SECURITY;

-- Internal admin-only tables: RLS off (service role only)
ALTER TABLE regional_servers DISABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs       DISABLE ROW LEVEL SECURITY;
ALTER TABLE settings         DISABLE ROW LEVEL SECURITY;


-- ── Helper function ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION current_client_id() RETURNS UUID AS $$
    SELECT id FROM clients
    WHERE auth_user_id = auth.uid()
       OR id IN (SELECT client_id FROM team_members WHERE auth_user_id = auth.uid())
    LIMIT 1;
$$ LANGUAGE sql STABLE;


-- ── RLS policies ──────────────────────────────────────────────────────────
-- Default: client (and their team members) can SELECT rows scoped to their client_id.
-- Writes go through backend (service role) — keeps trial vs paid gating + DNC checks central.

-- clients: self only
DROP POLICY IF EXISTS clients_self ON clients;
CREATE POLICY clients_self ON clients
    FOR SELECT USING (auth_user_id = auth.uid() OR id = current_client_id());

-- agents: own client OR demo agents (public read)
DROP POLICY IF EXISTS agents_own ON agents;
CREATE POLICY agents_own ON agents
    FOR SELECT USING (client_id = current_client_id() OR is_demo = true);

-- agent_drafts: own agent
DROP POLICY IF EXISTS drafts_own_select ON agent_drafts;
CREATE POLICY drafts_own_select ON agent_drafts
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );
DROP POLICY IF EXISTS drafts_own_all ON agent_drafts;
CREATE POLICY drafts_own_all ON agent_drafts
    FOR ALL USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- phone_numbers
DROP POLICY IF EXISTS phone_numbers_own ON phone_numbers;
CREATE POLICY phone_numbers_own ON phone_numbers
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- routing_rules
DROP POLICY IF EXISTS routing_rules_own ON routing_rules;
CREATE POLICY routing_rules_own ON routing_rules
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- agent_webhooks
DROP POLICY IF EXISTS agent_webhooks_own ON agent_webhooks;
CREATE POLICY agent_webhooks_own ON agent_webhooks
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- api_keys
DROP POLICY IF EXISTS api_keys_own ON api_keys;
CREATE POLICY api_keys_own ON api_keys
    FOR SELECT USING (client_id = current_client_id());

-- call_logs
DROP POLICY IF EXISTS call_logs_own ON call_logs;
CREATE POLICY call_logs_own ON call_logs
    FOR SELECT USING (client_id = current_client_id());

-- appointments
DROP POLICY IF EXISTS appointments_own ON appointments;
CREATE POLICY appointments_own ON appointments
    FOR SELECT USING (client_id = current_client_id());

-- contact_memory
DROP POLICY IF EXISTS contact_memory_own ON contact_memory;
CREATE POLICY contact_memory_own ON contact_memory
    FOR SELECT USING (client_id = current_client_id());

-- campaigns
DROP POLICY IF EXISTS campaigns_own ON campaigns;
CREATE POLICY campaigns_own ON campaigns
    FOR SELECT USING (client_id = current_client_id());

-- dnc_list
DROP POLICY IF EXISTS dnc_list_own ON dnc_list;
CREATE POLICY dnc_list_own ON dnc_list
    FOR SELECT USING (client_id = current_client_id());

-- kb_documents (scoped via agent → client)
DROP POLICY IF EXISTS kb_documents_own ON kb_documents;
CREATE POLICY kb_documents_own ON kb_documents
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- kb_chunks (scoped via document → agent → client)
DROP POLICY IF EXISTS kb_chunks_own ON kb_chunks;
CREATE POLICY kb_chunks_own ON kb_chunks
    FOR SELECT USING (
        document_id IN (
            SELECT id FROM kb_documents WHERE agent_id IN (
                SELECT id FROM agents WHERE client_id = current_client_id()
            )
        )
    );

-- campaign_attempts (scoped via campaign → client)
DROP POLICY IF EXISTS campaign_attempts_own ON campaign_attempts;
CREATE POLICY campaign_attempts_own ON campaign_attempts
    FOR SELECT USING (
        campaign_id IN (SELECT id FROM campaigns WHERE client_id = current_client_id())
    );

-- team_members (member can see own row + owner sees all rows for their client)
DROP POLICY IF EXISTS team_members_own ON team_members;
CREATE POLICY team_members_own ON team_members
    FOR SELECT USING (
        auth_user_id = auth.uid() OR client_id = current_client_id()
    );

-- notification_preferences (own user only)
DROP POLICY IF EXISTS notif_prefs_own ON notification_preferences;
CREATE POLICY notif_prefs_own ON notification_preferences
    FOR ALL USING (user_id = auth.uid());

-- ivr_menus (scoped via phone_number → agent → client)
DROP POLICY IF EXISTS ivr_menus_own ON ivr_menus;
CREATE POLICY ivr_menus_own ON ivr_menus
    FOR SELECT USING (
        phone_number_id IN (
            SELECT id FROM phone_numbers WHERE agent_id IN (
                SELECT id FROM agents WHERE client_id = current_client_id()
            )
        )
    );

-- agent_working_hours (scoped via agent → client)
DROP POLICY IF EXISTS agent_working_hours_own ON agent_working_hours;
CREATE POLICY agent_working_hours_own ON agent_working_hours
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- transfer_destinations (scoped via agent → client)
DROP POLICY IF EXISTS transfer_destinations_own ON transfer_destinations;
CREATE POLICY transfer_destinations_own ON transfer_destinations
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- agent_prompt_versions (scoped via agent → client)
DROP POLICY IF EXISTS agent_prompt_versions_own ON agent_prompt_versions;
CREATE POLICY agent_prompt_versions_own ON agent_prompt_versions
    FOR SELECT USING (
        agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );

-- agent_test_sessions (own tester OR agent's client)
DROP POLICY IF EXISTS agent_test_sessions_own ON agent_test_sessions;
CREATE POLICY agent_test_sessions_own ON agent_test_sessions
    FOR SELECT USING (
        tester_user_id = auth.uid()
        OR agent_id IN (SELECT id FROM agents WHERE client_id = current_client_id())
    );


-- ════════════════════════════════════════════════════════════════════════════
-- Post-schema runbook (manual / scripted after this file applies):
--
--   1. Storage:
--        Create bucket `recordings` (private). RLS policy: read where
--        path starts with `{client_id}/`.
--
--   2. Auth providers:
--        Authentication → Providers
--          - Email: ON (confirm email required)
--          - Google: ON, Client ID + Secret from Google Cloud Console
--
--   3. Seed:
--        Insert system "voxioai-demos" client (UUID fixed in seed.sql),
--        then insert 4 demo agents (is_demo=true).
--
--   4. updated_at triggers (optional, can be application-level instead):
--        agents, agent_drafts both have updated_at — backend updates on write.
-- ════════════════════════════════════════════════════════════════════════════


-- ── 23. demo_requests (public website "call me now" demo) ──────────────────
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

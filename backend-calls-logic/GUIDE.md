# VoxioAI Website — Backend Calls Logic Guide

> Everything the new website frontend needs to wire up the "Call me now" demo form.
> Drop this folder into the new website's repo and read this file first.

---

## What this folder contains

| File | What it is |
|------|-----------|
| `GUIDE.md` | This file — the complete integration guide |
| `demos.py` | FastAPI route that handles `POST /api/demo-call` (backend, already live on the server) |
| `livekit_svc.py` | Service that creates a LiveKit room + dispatches the Gemini voice agent |
| `settings.py` | All backend env settings (including demo quota config) |
| `schema_demo_requests.sql` | The `demo_requests` Supabase table (already deployed, shown for reference) |
| `full_schema.sql` | The complete 25-table Supabase schema (already deployed, shown for reference) |
| `frontend_demo_form.js` | The working frontend JS — copy/adapt this into the new website |

---

## The flow, end to end

```
Visitor fills form (name + email + phone)
          │
          ▼
POST https://api.voxioai.com/api/demo-call
          │
          ▼
demos.py validates input:
  - name ≥ 2 chars
  - valid email, not a disposable domain
  - phone → E.164 (+91XXXXXXXXXX for India)
  - not in DNC list
  - per-number cooldown: 1 call per 15 min
  - global daily cap: 50 calls / 24h
          │
          ▼
Inserts row into demo_requests (status=queued)
          │
          ▼
dispatch_call() in livekit_svc.py:
  - creates a LiveKit room
  - dispatches agent "voxioai-agent" to that room
  - agent metadata includes phone number, lead name, etc.
          │
          ▼
voxio-agent picks up the dispatch:
  - dials the lead via Vobiz SIP (+918065480088 → lead's number)
  - Gemini 3.1 Flash Live handles the conversation
          │
          ▼
Lead's phone rings within ~10 seconds
```

---

## The API contract

### Endpoint
```
POST https://api.voxioai.com/api/demo-call
Content-Type: application/json
```

### Request body
```json
{
  "name":   "Harvinder Singh",
  "email":  "harvindersran75@gmail.com",
  "phone":  "+919306973714",
  "source": "website-hero-demo"
}
```

- `phone` — accepts `+91XXXXXXXXXX` (E.164) or bare `9306973714` (backend normalises it)
- `source` — free string, used for analytics. Use `"website-hero-demo"` for the hero form

### Responses

| Status | Meaning | Body |
|--------|---------|------|
| `200 OK` | Call dispatched | `{ "status": "calling", "room": "vox-33333333-..." }` |
| `400 Bad Request` | Validation failed | `{ "detail": "Please enter a valid email address." }` |
| `409 Conflict` | Number on DNC list | `{ "detail": "This number has opted out of calls." }` |
| `429 Too Many Requests` | Quota hit | `{ "detail": "We just called this number — please wait 15 minutes..." }` |
| `429 Too Many Requests` | Daily cap hit | `{ "detail": "Our demo line is at capacity today — please book a call instead." }` |
| `502 Bad Gateway` | LiveKit dispatch failed | `{ "detail": "Couldn't place the call right now — please try again." }` |
| `503 Service Unavailable` | Demo agent not found | `{ "detail": "Demo is temporarily unavailable." }` |

---

## Frontend form requirements

The form collects **three fields**:

| Field | Validation (frontend) | Notes |
|-------|-----------------------|-------|
| Name | ≥ 2 characters | |
| Email | basic regex `\S+@\S+\.\S+` | backend also blocks disposable domains |
| Phone | 10 digits (Indian mobile) | frontend strips non-digits, prepends `+91` |

The phone input UI shows `🇮🇳 +91` prefix — the field accepts bare 10-digit number.

See `frontend_demo_form.js` for the complete ready-to-use implementation.

---

## Demo quota settings (backend env)

These live in `voxio-backend/settings.py` and can be overridden via env vars on the server:

| Env var | Default | Effect |
|---------|---------|--------|
| `DEMO_COOLDOWN_MIN` | `15` | Minutes before the same number can request another call |
| `DEMO_DAILY_CAP` | `50` | Max demo calls across all users per 24-hour window |
| `DEMO_CALL_AGENT_ID` | `33333333-3333-3333-3333-333333333333` | UUID of the seeded "VoxioAI Pitch Agent" |

---

## The demo agent

- **Name:** VoxioAI Pitch Agent
- **UUID:** `33333333-3333-3333-3333-333333333333` (fixed, seeded in Supabase)
- **Purpose:** Pitches VoxioAI itself — showcases the voice quality
- **Caller ID shown to lead:** `+918065480088` (VoxioAI Vobiz DID)
- **Works 24/7:** no `agent_working_hours` rows, so routing always allows it

---

## CORS — allowed origins

The backend already allows these origins. If the new frontend is hosted on a different domain, the domain must be added to `allow_origins` in `voxio-backend/main.py`:

```python
# Currently allowed:
"https://voxioai.com"
"https://www.voxioai.com"
"http://localhost:3000"
"http://localhost:5173"
# Also: https://*.voxio-frontend.pages.dev (Cloudflare Pages previews)
```

---

## Supabase — `demo_requests` table

This table is the rate-limit ledger. The backend writes to it using the service-role key — the frontend never touches Supabase directly for this flow. Shown here for context only.

```sql
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
```

Indexes: `(phone, created_at DESC)` and `(created_at DESC)` — supports the cooldown and daily-cap queries.

---

## Credentials (already on the server — do not commit to frontend repo)

These are configured as env vars on `157.173.219.150` (Hostinger KVM 2 Mumbai). The frontend only ever talks to `https://api.voxioai.com` — it never needs these directly.

| Service | What it's for |
|---------|---------------|
| Supabase URL: `https://knuilvlrimxmwpuvqtdj.supabase.co` | DB + Auth |
| Supabase Anon Key | Public frontend auth (not needed for this flow) |
| Supabase Service Role Key | Backend-only — bypasses RLS |
| LiveKit URL: `wss://in.voxioai.com` | SFU for voice rooms |
| LiveKit API Key/Secret | Room creation + agent dispatch |
| Vobiz SIP DID: `+918065480088` | Outbound caller ID |
| Gemini API Key | Voice agent (Gemini 3.1 Flash Live) |

Credentials are in the Claude memory file `reference_voxioai_credentials.md` in the AI Dev project.

---

## Calendly booking link

All "Book a call" buttons on the website should link to:
```
https://calendly.com/harvindersran101/intro-call
```

This is the 20-minute intro call. After the call, Harvinder manually flips the client's `plan_type` from `trial` to `paid` in Supabase.

---

## Quick wiring checklist for the new frontend

- [ ] Copy `frontend_demo_form.js` logic into the new site's form component
- [ ] Set `DEMO_CALL_ENDPOINT = "https://api.voxioai.com/api/demo-call"`
- [ ] Wire all "Book a call" / "Get started" links to `https://calendly.com/harvindersran101/intro-call`
- [ ] Confirm the new domain is added to CORS `allow_origins` in `main.py` on the server (if not `voxioai.com`)
- [ ] Test with phone `+919306973714` (Harvinder's number) — call should ring within ~10s

---

## Files in `VoxioAI Tool/` (the backend repo, on server)

For reference — these are the source files on disk. The backend is already deployed:

| Path | Purpose |
|------|---------|
| `voxio-backend/routes/demos.py` | The `/api/demo-call` route |
| `voxio-backend/services/livekit_svc.py` | Room creation + agent dispatch |
| `voxio-backend/settings.py` | All env-driven config |
| `voxio-backend/main.py` | FastAPI app, CORS config, scheduler |
| `supabase/schema.sql` | Full 25-table database schema |
| `.env.example` | Env var template |

Backend repo: `https://github.com/Harvinder-sran/voxioai` (private)
Server: `ssh -i ~/.ssh/voxioai_ed25519 root@157.173.219.150`

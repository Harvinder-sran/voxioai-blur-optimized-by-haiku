"""Public demo endpoints (anonymous — no auth).

  GET  /api/demos      — list the public demo agents.
  POST /api/demo-call  — website "call me now": validates a lead, enforces an
                         anti-abuse quota, then dispatches an OUTBOUND call from
                         the dedicated demo agent (settings.DEMO_CALL_AGENT_ID).

The demo agent lives under the system "VoxioAI Demos" client and has no
agent_working_hours rows, so routing treats it as 24/7 (see routing.py
is_within_working_hours: "empty rows -> always allowed"). Lead capture +
rate-limit state live in the demo_requests table.

Source: VoxioAI Tool/voxio-backend/routes/demos.py
"""
import logging
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

import db as dbmod
from services.disposable import is_disposable
from services.livekit_svc import dispatch_call
from services.phone import normalize as normalize_phone
from settings import settings

logger = logging.getLogger("voxio-backend.demos")
router = APIRouter()


@router.get("/api/demos")
async def list_demos() -> dict:
    demos = await dbmod.get_demo_agents()
    return {
        "demos": [
            {
                "id": d["id"], "name": d["name"], "voice": d["voice"],
                "demo_category": d["demo_category"],
                "blurb": (d.get("description") or "")[:200],
            }
            for d in demos
        ]
    }


class DemoCall(BaseModel):
    name: str
    email: str
    phone: str
    source: Optional[str] = "website"


def _client_ip(request: Request) -> Optional[str]:
    # Behind Caddy the real client is the first X-Forwarded-For entry.
    fwd = request.headers.get("x-forwarded-for", "")
    if fwd:
        return fwd.split(",")[0].strip()
    return request.client.host if request.client else None


@router.post("/api/demo-call")
async def demo_call(body: DemoCall, request: Request) -> dict:
    """Trigger an immediate outbound demo call to the lead's phone."""
    # 1. Basic field validation
    name = (body.name or "").strip()
    email = (body.email or "").strip().lower()
    if len(name) < 2:
        raise HTTPException(400, "Please enter your name.")
    if "@" not in email or "." not in email.rsplit("@", 1)[-1]:
        raise HTTPException(400, "Please enter a valid email address.")
    if await is_disposable(email):
        raise HTTPException(400, "Please use a non-temporary email address.")

    # 2. Phone -> E.164 (reuses the dialer's single source of truth)
    pr = normalize_phone(body.phone)
    if not pr["ok"]:
        raise HTTPException(400, f"Invalid phone number — {pr['reason']}.")
    phone = pr["e164"]

    # 3. Resolve the demo agent + its owning (system) client
    agent = await dbmod.get_agent(settings.DEMO_CALL_AGENT_ID)
    if not agent:
        logger.error("DEMO_CALL_AGENT_ID %s not found", settings.DEMO_CALL_AGENT_ID)
        raise HTTPException(503, "Demo is temporarily unavailable.")
    client_id = agent["client_id"]

    db = await dbmod.db_admin()

    # 4. DNC check (respect opt-outs recorded against the demo client)
    dnc = await (
        db.table("dnc_list").select("id")
        .eq("client_id", client_id).eq("phone_number", phone)
        .maybe_single().execute()
    )
    if dnc and dnc.data:
        raise HTTPException(409, "This number has opted out of calls.")

    now = datetime.utcnow()

    # 5a. Per-number cooldown
    cutoff = (now - timedelta(minutes=settings.DEMO_COOLDOWN_MIN)).isoformat()
    recent = await (
        db.table("demo_requests").select("id").eq("phone", phone)
        .gte("created_at", cutoff).limit(1).execute()
    )
    if recent.data:
        raise HTTPException(
            429,
            f"We just called this number — please wait {settings.DEMO_COOLDOWN_MIN} minutes before trying again.",
        )

    # 5b. Global daily cap (cost guard)
    day_cutoff = (now - timedelta(hours=24)).isoformat()
    cap_rows = await (
        db.table("demo_requests").select("id")
        .gte("created_at", day_cutoff).limit(settings.DEMO_DAILY_CAP + 1).execute()
    )
    if len(cap_rows.data or []) >= settings.DEMO_DAILY_CAP:
        raise HTTPException(429, "Our demo line is at capacity today — please book a call instead.")

    # 6. Reserve the rate-limit slot, then dispatch the outbound call
    row_id = str(uuid.uuid4())
    source = (body.source or "website")[:60]
    await db.table("demo_requests").insert({
        "id": row_id, "name": name[:120], "email": email[:200],
        "phone": phone, "ip": _client_ip(request), "source": source,
        "status": "queued",
    }).execute()

    try:
        res = await dispatch_call(
            agent_id=agent["id"], client_id=client_id, direction="outbound",
            phone_number=phone, lead_name=name,
            lead_variables={"name": name, "email": email, "source": source},
        )
    except Exception as exc:  # noqa: BLE001
        await db.table("demo_requests").update({"status": "failed"}).eq("id", row_id).execute()
        await dbmod.log_event(
            "demo", "demo dispatch failed", detail=str(exc)[:500],
            level="error", client_id=client_id,
        )
        raise HTTPException(502, "Couldn't place the call right now — please try again.")

    await db.table("demo_requests").update(
        {"status": "calling", "room": res["room"]}
    ).eq("id", row_id).execute()
    logger.info("demo call dispatched: %s -> room %s", phone, res["room"])
    return {"status": "calling", "room": res["room"]}

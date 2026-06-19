"""LiveKit dispatch + token issuance + SIP rule management.

Source: VoxioAI Tool/voxio-backend/services/livekit_svc.py
"""
import datetime
import json
import logging
import random
import ssl
from typing import Optional

import aiohttp
import certifi
from livekit import api as lk_api

from settings import settings

logger = logging.getLogger("voxio-backend.livekit")


def _ssl_ctx() -> ssl.SSLContext:
    return ssl.create_default_context(cafile=certifi.where())


def _lk():
    sess = aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=_ssl_ctx()))
    lk = lk_api.LiveKitAPI(
        url=settings.LIVEKIT_URL, api_key=settings.LIVEKIT_API_KEY,
        api_secret=settings.LIVEKIT_API_SECRET, session=sess,
    )
    return lk, sess


def normalize_e164(num: Optional[str]) -> Optional[str]:
    """Strip spaces/dashes/parens/dots from a phone number so it forms a valid
    SIP Request-URI. A space in the dialed number (e.g. "+91 9306973714")
    produces a malformed `sip:+91 9306973714@host` URI that carriers silently
    drop — zero SIP response, no CDR. Keeps a single leading '+'.
    """
    if not num:
        return num
    s = num.strip()
    plus = s.startswith("+")
    digits = "".join(ch for ch in s if ch.isdigit())
    if not digits:
        return num  # nothing dialable; leave as-is for upstream validation
    return ("+" + digits) if plus else digits


async def dispatch_call(
    *, agent_id: str, client_id: str, direction: str = "outbound",
    phone_number: Optional[str] = None, lead_name: Optional[str] = None,
    lead_variables: Optional[dict] = None, use_draft: bool = False,
    is_test: bool = False, record_ttft: bool = False,
    outbound_trunk_id: Optional[str] = None, tester_user_id: Optional[str] = None,
    agent_name: str = "voxioai-agent",
    campaign_id: Optional[str] = None, campaign_attempt_id: Optional[str] = None,
) -> dict:
    """Create a LiveKit room + agent dispatch. Returns room name."""
    phone_number = normalize_e164(phone_number)
    suffix = random.randint(1000, 9999)
    safe_phone = (phone_number or "web").replace("+", "")
    prefix = "test" if is_test else "vox"
    room_name = f"{prefix}-{agent_id[:8]}-{safe_phone}-{suffix}"

    metadata = {
        "agent_id": agent_id, "client_id": client_id, "direction": direction,
        "phone_number": phone_number, "lead_name": lead_name,
        "lead_variables": lead_variables or {}, "use_draft": use_draft,
        "is_test": is_test, "record_ttft": record_ttft,
        "outbound_trunk_id": outbound_trunk_id, "tester_user_id": tester_user_id,
        "campaign_id": campaign_id, "campaign_attempt_id": campaign_attempt_id,
    }
    lk, sess = _lk()
    try:
        await lk.room.create_room(lk_api.CreateRoomRequest(
            name=room_name, empty_timeout=300, max_participants=5,
        ))
        await lk.agent_dispatch.create_dispatch(lk_api.CreateAgentDispatchRequest(
            agent_name=agent_name, room=room_name,
            metadata=json.dumps(metadata),
        ))
    finally:
        try:
            await lk.aclose(); await sess.close()
        except Exception:
            pass
    return {"room": room_name, "metadata": metadata}


def issue_room_token(*, room: str, identity: str, ttl_seconds: int = 600) -> str:
    return (
        lk_api.AccessToken(settings.LIVEKIT_API_KEY, settings.LIVEKIT_API_SECRET)
        .with_identity(identity)
        .with_ttl(datetime.timedelta(seconds=ttl_seconds))
        .with_grants(lk_api.VideoGrants(
            room_join=True, room=room, can_publish=True, can_subscribe=True,
        ))
        .to_jwt()
    )

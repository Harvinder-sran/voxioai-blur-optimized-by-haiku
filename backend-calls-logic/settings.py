"""Env-driven settings for voxio-backend.

Source: VoxioAI Tool/voxio-backend/settings.py
Shown here for reference — the agent handling the new website only needs
to know the DEMO_* settings to understand quota behavior.
"""
import os
from dotenv import load_dotenv

load_dotenv(".env")
load_dotenv(".env.local")


class Settings:
    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_ANON_KEY: str = os.getenv("SUPABASE_ANON_KEY", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    SUPABASE_PROJECT_REF: str = os.getenv("SUPABASE_PROJECT_REF", "")
    SUPABASE_JWT_SECRET: str = os.getenv("SUPABASE_JWT_SECRET", "")
    SUPABASE_JWKS_URL: str = os.getenv("SUPABASE_JWKS_URL", "")

    # LiveKit (for issuing playground tokens + admin dispatch)
    # LIVEKIT_URL is the server->LK address (internal, e.g. ws://livekit:7880).
    # LIVEKIT_PUBLIC_URL is the browser-reachable signaling URL returned in
    # playground tokens (e.g. wss://in.voxioai.com). Falls back to LIVEKIT_URL.
    LIVEKIT_URL: str = os.getenv("LIVEKIT_URL", "")
    LIVEKIT_PUBLIC_URL: str = os.getenv("LIVEKIT_PUBLIC_URL", "") or os.getenv("LIVEKIT_URL", "")
    LIVEKIT_API_KEY: str = os.getenv("LIVEKIT_API_KEY", "")
    LIVEKIT_API_SECRET: str = os.getenv("LIVEKIT_API_SECRET", "")

    # AI
    GOOGLE_API_KEY: str = os.getenv("GOOGLE_API_KEY", "")
    GEMINI_EMBEDDING_MODEL: str = os.getenv("GEMINI_EMBEDDING_MODEL", "gemini-embedding-001")
    EMBEDDING_DIM: int = int(os.getenv("EMBEDDING_DIM", "1536"))

    # Cal.com
    CAL_COM_API_KEY: str = os.getenv("CAL_COM_API_KEY", "")

    # Pricing + trial
    PRICE_PER_MINUTE_INR: float = float(os.getenv("PRICE_PER_MINUTE_INR", "5"))
    TRIAL_MINUTES_DEFAULT: float = float(os.getenv("TRIAL_MINUTES_DEFAULT", "15"))

    # Public website demo ("call me now"). Defaults to the seeded VoxioAI Pitch
    # Agent (general, 24/7 — no working-hours rows). Abuse quota is enforced in
    # routes/demos.py against the demo_requests table.
    DEMO_CALL_AGENT_ID: str = os.getenv("DEMO_CALL_AGENT_ID", "33333333-3333-3333-3333-333333333333")
    DEMO_COOLDOWN_MIN: int = int(os.getenv("DEMO_COOLDOWN_MIN", "15"))
    DEMO_DAILY_CAP: int = int(os.getenv("DEMO_DAILY_CAP", "50"))

    # Disposable email blocklist
    DISPOSABLE_EMAIL_BLOCKLIST_URL: str = os.getenv(
        "DISPOSABLE_EMAIL_BLOCKLIST_URL",
        "https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/master/disposable_email_blocklist.conf",
    )

    # Admin
    ADMIN_EMAIL: str = os.getenv("ADMIN_EMAIL", "harvindersran101@gmail.com")
    CALENDLY_UPGRADE_URL: str = os.getenv(
        "CALENDLY_UPGRADE_URL",
        "https://calendly.com/harvindersran101/intro-call",
    )

    # Feature flags
    WHATSAPP_ENABLED: bool = os.getenv("WHATSAPP_ENABLED", "false").lower() == "true"
    CAMPAIGN_DIALER_ENABLED: bool = os.getenv("CAMPAIGN_DIALER_ENABLED", "false").lower() == "true"


settings = Settings()

"""
ml/api/auth.py

Authentication and authorization dependency for TruckLink AI FastAPI backend.
Validates Firebase Authentication ID tokens.
"""

import os
import logging
from typing import Optional
from fastapi import Header, HTTPException, status

logger = logging.getLogger("trucklink.auth")

try:
    from firebase_admin import auth as fb_auth
    FIREBASE_AUTH_AVAILABLE = True
except ImportError:
    FIREBASE_AUTH_AVAILABLE = False


async def verify_firebase_token(
    authorization: Optional[str] = Header(None),
) -> Optional[str]:
    """
    Verifies Firebase Authentication Bearer token from HTTP headers.
    Returns authenticated user's UID or None in permissive development mode.
    """
    env = os.getenv("ENVIRONMENT", "development").lower()

    if not authorization:
        if env == "development":
            # In local development mode without token, allow request with dev fallback
            return "dev_user"
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    parts = authorization.split(" ")
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization format. Expected 'Bearer <token>'",
        )

    token = parts[1]

    if not FIREBASE_AUTH_AVAILABLE or env == "development":
        # Allow dev testing tokens or return dummy uid in dev
        if token.startswith("test_") or env == "development":
            return token.replace("test_", "")

    try:
        decoded = fb_auth.verify_id_token(token)
        return decoded.get("uid")
    except Exception as e:
        logger.warning(f"Token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired authentication token: {str(e)}",
        )


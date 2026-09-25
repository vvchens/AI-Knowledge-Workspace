from __future__ import annotations

from datetime import datetime, timezone
import hashlib

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models.invitation import UserInvitation


def get_invitation(token: str, db: Session) -> UserInvitation:
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    invitation = db.scalar(
        select(UserInvitation).where(UserInvitation.token_hash == token_hash)
    )
    now = datetime.now(timezone.utc)
    if invitation is None or invitation.accepted_at is not None or invitation.expires_at <= now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invitation is invalid or expired",
        )
    return invitation


def consume_invitation(token: str, db: Session) -> UserInvitation:
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    now = datetime.now(timezone.utc)
    result = db.execute(
        update(UserInvitation)
        .where(
            UserInvitation.token_hash == token_hash,
            UserInvitation.accepted_at.is_(None),
            UserInvitation.expires_at > now,
        )
        .values(accepted_at=now)
        .returning(UserInvitation.id)
    )
    invitation_id = result.scalar_one_or_none()
    if invitation_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invitation is invalid or expired",
        )
    invitation = db.get(UserInvitation, invitation_id)
    if invitation is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invitation is invalid or expired",
        )
    return invitation
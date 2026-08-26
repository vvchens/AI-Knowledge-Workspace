from datetime import datetime

from fastapi import APIRouter, Cookie, Depends, HTTPException, Response, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.auth import AuthError, AuthService
from app.core.config import settings
from app.core.database import get_db_session

router = APIRouter(prefix="/auth", tags=["auth"])
auth_service = AuthService()


class FirebaseSessionRequest(BaseModel):
    id_token: str = Field(min_length=1)


class FirebaseSessionResponse(BaseModel):
    authenticated: bool
    provider: str
    user_id: str
    provider_user_id: str
    session_token: str
    expires_at: datetime


class CurrentUserResponse(BaseModel):
    user_id: str
    provider: str
    provider_user_id: str
    email: str | None = None
    display_name: str | None = None


@router.post("/firebase/session")
def firebase_session(
    payload: FirebaseSessionRequest,
    response: Response,
    db: Session = Depends(get_db_session),
) -> FirebaseSessionResponse:
    try:
        user, session_payload = auth_service.authenticate_and_create_session(db, payload.id_token)
    except AuthError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc

    response.set_cookie(
        key=settings.session_cookie_name,
        value=session_payload.session_token,
        max_age=session_payload.ttl_seconds,
        httponly=True,
        secure=settings.session_cookie_secure,
        samesite="lax",
    )

    return FirebaseSessionResponse(
        authenticated=True,
        provider=user.provider,
        user_id=user.id,
        provider_user_id=user.provider_user_id,
        session_token=session_payload.session_token,
        expires_at=session_payload.expires_at,
    )


@router.get("/me")
def current_user(
    session_token: str | None = Cookie(default=None, alias=settings.session_cookie_name),
    db: Session = Depends(get_db_session),
) -> CurrentUserResponse:
    if not session_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing session",
        )

    user = auth_service.get_user_from_session(db, session_token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid session",
        )

    return CurrentUserResponse(
        user_id=user.id,
        provider=user.provider,
        provider_user_id=user.provider_user_id,
        email=user.email,
        display_name=user.display_name,
    )


@router.post("/logout")
def logout(
    response: Response,
    session_token: str | None = Cookie(default=None, alias=settings.session_cookie_name),
    db: Session = Depends(get_db_session),
) -> dict[str, bool]:
    if session_token:
        auth_service.revoke_session(db, session_token)

    response.delete_cookie(settings.session_cookie_name)

    return {"logged_out": True}

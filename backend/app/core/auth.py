from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import json
import secrets
from typing import Literal

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials
from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.auth_session import AuthSession
from app.models.user import User

AuthProviderName = Literal["firebase", "clerk", "auth0", "local"]


def _utcnow() -> datetime:
    return datetime.now(tz=timezone.utc)


_firebase_app: firebase_admin.App | None = None


class AuthError(ValueError):
    pass


@dataclass
class AuthUser:
    user_id: str
    provider: AuthProviderName
    provider_user_id: str
    email: str | None = None
    display_name: str | None = None
    firebase_uid: str | None = None


@dataclass
class SessionPayload:
    session_token: str
    expires_at: datetime
    ttl_seconds: int


class BaseAuthProvider:
    def verify_token(self, token: str) -> AuthUser:
        raise NotImplementedError


class FirebaseAuthProvider(BaseAuthProvider):
    def __init__(self) -> None:
        self._app = self._get_or_init_app()

    def _get_or_init_app(self) -> firebase_admin.App:
        global _firebase_app

        if _firebase_app is not None:
            return _firebase_app

        if settings.firebase_service_account_json:
            service_account = json.loads(settings.firebase_service_account_json)
            credential = credentials.Certificate(service_account)
        elif settings.firebase_service_account_file:
            credential = credentials.Certificate(settings.firebase_service_account_file)
        else:
            credential = credentials.ApplicationDefault()

        options: dict[str, str] = {}
        if settings.firebase_project_id:
            options["projectId"] = settings.firebase_project_id

        _firebase_app = firebase_admin.initialize_app(credential, options or None)
        return _firebase_app

    def verify_token(self, token: str) -> AuthUser:
        if not token:
            raise AuthError("Missing Firebase token")

        try:
            decoded = firebase_auth.verify_id_token(
                token,
                app=self._app,
                check_revoked=True,
            )
        except Exception as exc:  # Firebase SDK raises multiple auth exceptions.
            raise AuthError("Invalid Firebase token") from exc

        firebase_uid = str(decoded["uid"])
        email = decoded.get("email")
        name = decoded.get("name") or decoded.get("display_name")

        return AuthUser(
            user_id=firebase_uid,
            provider="firebase",
            provider_user_id=firebase_uid,
            email=email,
            display_name=name,
            firebase_uid=firebase_uid,
        )


class AuthService:
    def __init__(self, provider: BaseAuthProvider | None = None):
        self.provider = provider or FirebaseAuthProvider()

    def authenticate(self, token: str) -> AuthUser:
        return self.provider.verify_token(token)

    def get_or_create_user(self, db: Session, auth_user: AuthUser) -> User:
        user = db.scalar(
            select(User).where(
                and_(
                    User.provider == auth_user.provider,
                    User.provider_user_id == auth_user.provider_user_id,
                )
            )
        )

        if user is None and auth_user.firebase_uid:
            user = db.scalar(select(User).where(User.firebase_uid == auth_user.firebase_uid))

        if user is None:
            user = User(
                provider=auth_user.provider,
                provider_user_id=auth_user.provider_user_id,
                email=auth_user.email,
                display_name=auth_user.display_name,
                firebase_uid=auth_user.firebase_uid,
            )
            db.add(user)
        else:
            user.email = auth_user.email
            user.display_name = auth_user.display_name
            user.firebase_uid = auth_user.firebase_uid

        db.commit()
        db.refresh(user)
        return user

    def create_session(self, db: Session, user: User) -> SessionPayload:
        now = _utcnow()
        expires_at = now + timedelta(hours=settings.session_ttl_hours)
        session_token = secrets.token_urlsafe(48)

        session = AuthSession(
            user_id=user.id,
            session_token=session_token,
            provider=user.provider,
            provider_session_id=user.provider_user_id,
            expires_at=expires_at,
            last_seen_at=now,
        )
        db.add(session)
        db.commit()

        return SessionPayload(
            session_token=session_token,
            expires_at=expires_at,
            ttl_seconds=max(int((expires_at - now).total_seconds()), 0),
        )

    def authenticate_and_create_session(self, db: Session, token: str) -> tuple[User, SessionPayload]:
        auth_user = self.authenticate(token)
        user = self.get_or_create_user(db, auth_user)
        session_payload = self.create_session(db, user)
        return user, session_payload

    def get_user_from_session(self, db: Session, session_token: str) -> User | None:
        now = _utcnow()
        session = db.scalar(
            select(AuthSession).where(
                and_(
                    AuthSession.session_token == session_token,
                    AuthSession.expires_at > now,
                    AuthSession.revoked_at.is_(None),
                )
            )
        )
        if session is None:
            return None

        session.last_seen_at = now
        db.add(session)
        db.commit()

        return db.get(User, session.user_id)

    def revoke_session(self, db: Session, session_token: str) -> None:
        session = db.scalar(select(AuthSession).where(AuthSession.session_token == session_token))
        if session is None or session.revoked_at is not None:
            return

        session.revoked_at = _utcnow()
        db.add(session)
        db.commit()

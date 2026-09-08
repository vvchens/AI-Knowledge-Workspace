from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import json
import logging
import secrets
from threading import RLock
from typing import Literal

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials
from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user import User

AuthProviderName = Literal["firebase", "clerk", "auth0", "local"]


def _utcnow() -> datetime:
    return datetime.now(tz=timezone.utc)


_firebase_app: firebase_admin.App | None = None
logger = logging.getLogger(__name__)


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


@dataclass(frozen=True)
class StoredSession:
    user_id: str
    expires_at: datetime


class InMemorySessionStore:
    """Process-local session storage; session state is never persisted in SQL."""

    def __init__(self) -> None:
        self._sessions: dict[str, StoredSession] = {}
        self._lock = RLock()

    def create(self, session_token: str, user_id: str, expires_at: datetime) -> None:
        with self._lock:
            self._remove_expired_locked(_utcnow())
            self._sessions[session_token] = StoredSession(user_id, expires_at)

    def get_user_id(self, session_token: str) -> str | None:
        now = _utcnow()
        with self._lock:
            session = self._sessions.get(session_token)
            if session is None or session.expires_at <= now:
                self._sessions.pop(session_token, None)
                return None
            return session.user_id

    def revoke(self, session_token: str) -> None:
        with self._lock:
            self._sessions.pop(session_token, None)

    def _remove_expired_locked(self, now: datetime) -> None:
        expired_tokens = [
            token
            for token, session in self._sessions.items()
            if session.expires_at <= now
        ]
        for token in expired_tokens:
            del self._sessions[token]


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
                check_revoked=settings.firebase_check_revoked,
                clock_skew_seconds=settings.firebase_clock_skew_seconds,
            )
        except Exception as exc:  # Firebase SDK raises multiple auth exceptions.
            logger.warning(
                "Firebase ID token verification failed: %s: %s",
                type(exc).__name__,
                exc,
            )
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
    def __init__(
        self,
        provider: BaseAuthProvider | None = None,
        session_store: InMemorySessionStore | None = None,
    ):
        self.provider = provider or FirebaseAuthProvider()
        self.session_store = session_store or InMemorySessionStore()

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

    def create_session(self, user: User) -> SessionPayload:
        now = _utcnow()
        expires_at = now + timedelta(hours=settings.session_ttl_hours)
        session_token = secrets.token_urlsafe(48)

        self.session_store.create(session_token, user.id, expires_at)

        return SessionPayload(
            session_token=session_token,
            expires_at=expires_at,
            ttl_seconds=max(int((expires_at - now).total_seconds()), 0),
        )

    def authenticate_and_create_session(self, db: Session, token: str) -> tuple[User, SessionPayload]:
        auth_user = self.authenticate(token)
        user = self.get_or_create_user(db, auth_user)
        session_payload = self.create_session(user)
        return user, session_payload

    def get_user_from_session(self, db: Session, session_token: str) -> User | None:
        user_id = self.session_store.get_user_id(session_token)
        return db.get(User, user_id) if user_id is not None else None

    def revoke_session(self, session_token: str) -> None:
        self.session_store.revoke(session_token)


auth_service = AuthService()

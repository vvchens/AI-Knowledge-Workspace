from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

AuthProviderName = Literal["firebase", "clerk", "auth0", "local"]


@dataclass
class AuthUser:
    user_id: str
    provider: AuthProviderName
    provider_user_id: str
    email: str | None = None
    display_name: str | None = None
    firebase_uid: str | None = None


class BaseAuthProvider:
    def verify_token(self, token: str) -> AuthUser:
        raise NotImplementedError


class FirebaseAuthProvider(BaseAuthProvider):
    def verify_token(self, token: str) -> AuthUser:
        # Placeholder implementation for Phase 1 skeleton.
        # Real Firebase Admin SDK verification should happen here.
        if not token or token == "invalid-token":
            raise ValueError("Invalid Firebase token")

        return AuthUser(
            user_id="user_001",
            provider="firebase",
            provider_user_id="firebase-user-001",
            email="demo@example.com",
            display_name="Demo User",
            firebase_uid="firebase-user-001",
        )


class AuthService:
    def __init__(self, provider: BaseAuthProvider | None = None):
        self.provider = provider or FirebaseAuthProvider()

    def authenticate(self, token: str) -> AuthUser:
        return self.provider.verify_token(token)

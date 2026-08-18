from fastapi import APIRouter, HTTPException, status

from app.core.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])
auth_service = AuthService()


@router.post("/firebase/session")
def firebase_session(token: str) -> dict[str, str | bool]:
    try:
        user = auth_service.authenticate(token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc

    return {
        "authenticated": True,
        "provider": user.provider,
        "user_id": user.user_id,
        "provider_user_id": user.provider_user_id,
    }

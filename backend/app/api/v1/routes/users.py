from datetime import datetime, timedelta, timezone
import hashlib
import secrets

from fastapi import APIRouter, Cookie, Depends, Header, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.auth import auth_service
from app.core.config import settings
from app.core.database import get_db_session
from app.models.project import Project
from app.models.invitation import UserInvitation
from app.services.invitations import get_invitation
from app.models.user import User

router = APIRouter(prefix="/users", tags=["users"])


class UserResponse(BaseModel):
    id: str
    name: str
    email: str | None
    role: str
    projects: int
    status: str
    last_active: datetime


class UserListResponse(BaseModel):
    users: list[UserResponse]


class InviteUserRequest(BaseModel):
    email: str
    role: str


class InviteUserResponse(BaseModel):
    email: str
    role: str
    registration_path: str
    expires_at: datetime


def _current_user(
    session_token: str | None = Cookie(default=None, alias=settings.session_cookie_name),
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db_session),
) -> User:
    if authorization and authorization.lower().startswith("bearer "):
        session_token = authorization[7:].strip()
    if not session_token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing session")

    user = auth_service.get_user_from_session(db, session_token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session")
    return user


@router.get("", response_model=UserListResponse)
def list_users(
    db: Session = Depends(get_db_session),
    _: User = Depends(_current_user),
) -> UserListResponse:
    project_count = (
        select(func.count(Project.id))
        .where(Project.owner_id == User.id)
        .correlate(User)
        .scalar_subquery()
    )
    users = db.execute(
        select(User, project_count.label("project_count")).order_by(User.updated_at.desc())
    ).all()
    return UserListResponse(
        users=[
            UserResponse(
                id=user.id,
                name=user.display_name or user.email or "Unnamed user",
                email=user.email,
                role=user.role.title(),
                projects=project_total or 0,
                status="Active",
                last_active=user.updated_at,
            )
            for user, project_total in users
        ]
    )


@router.post("/invitations", response_model=InviteUserResponse)
def invite_user(
    payload: InviteUserRequest,
    current_user: User = Depends(_current_user),
    db: Session = Depends(get_db_session),
) -> InviteUserResponse:
    email = payload.email.strip().lower()
    role = payload.role.strip().lower()
    if "@" not in email:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="A valid email is required")
    if role not in {"admin", "member"}:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Role must be admin or member")

    raw_token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    invitation = UserInvitation(
        email=email,
        role=role,
        token_hash=hashlib.sha256(raw_token.encode("utf-8")).hexdigest(),
        expires_at=expires_at,
        created_by_id=current_user.id,
    )
    db.add(invitation)
    db.commit()
    return InviteUserResponse(
        email=email,
        role=role,
        registration_path=f"/register?token={raw_token}",
        expires_at=expires_at,
    )


@router.get("/invitations/{token}", response_model=InviteUserResponse)
def validate_invitation(token: str, db: Session = Depends(get_db_session)) -> InviteUserResponse:
    invitation = get_invitation(token, db)
    return InviteUserResponse(
        email=invitation.email,
        role=invitation.role,
        registration_path="",
        expires_at=invitation.expires_at,
    )

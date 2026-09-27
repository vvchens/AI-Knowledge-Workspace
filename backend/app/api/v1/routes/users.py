from datetime import datetime, timedelta, timezone
import hashlib
import secrets

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db_session
from app.core.permissions import current_user, organization_admin
from app.models.invitation import UserInvitation
from app.models.organization_member import OrganizationMember
from app.models.project import Project
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


class UpdateUserRequest(BaseModel):
    role: str


class UserActionResponse(BaseModel):
    user_id: str
    organization_id: str
    role: str
    status: str


@router.get("", response_model=UserListResponse)
def list_users(
    db: Session = Depends(get_db_session),
    membership: OrganizationMember = Depends(organization_admin),
) -> UserListResponse:
    project_count = (
        select(func.count(Project.id))
        .where(Project.owner_id == User.id, Project.organization_id == membership.organization_id)
        .correlate(User)
        .scalar_subquery()
    )
    users = db.execute(
        select(User, OrganizationMember, project_count.label("project_count"))
        .join(OrganizationMember, OrganizationMember.user_id == User.id)
        .where(
            OrganizationMember.organization_id == membership.organization_id,
            OrganizationMember.status == "active",
        )
        .order_by(User.updated_at.desc())
    ).all()
    return UserListResponse(
        users=[
            UserResponse(
                id=user.id,
                name=user.display_name or user.email or "Unnamed user",
                email=user.email,
                role=member.role.title(),
                projects=project_total or 0,
                status="Active",
                last_active=user.updated_at,
            )
            for user, member, project_total in users
        ]
    )


@router.post("/invitations", response_model=InviteUserResponse)
def invite_user(
    payload: InviteUserRequest,
    membership: OrganizationMember = Depends(organization_admin),
    current_user: User = Depends(current_user),
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
        organization_id=membership.organization_id,
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


@router.patch("/{user_id}", response_model=UserActionResponse)
def update_user(
    user_id: str,
    payload: UpdateUserRequest,
    membership: OrganizationMember = Depends(organization_admin),
    current_user: User = Depends(current_user),
    db: Session = Depends(get_db_session),
) -> UserActionResponse:
    role = payload.role.strip().lower()
    if role not in {"admin", "member"}:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Role must be admin or member",
        )
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    target_membership = db.scalar(
        select(OrganizationMember).where(
            OrganizationMember.organization_id == membership.organization_id,
            OrganizationMember.user_id == user_id,
            OrganizationMember.status == "active",
        )
    )
    if target_membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User is not in this organization")
    if target.system_role == "system_admin" and current_user.system_role != "system_admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="System admin cannot be changed")
    if target_membership.role == "admin" and role != "admin":
        admin_count = db.scalar(
            select(func.count(OrganizationMember.id)).where(
                OrganizationMember.organization_id == membership.organization_id,
                OrganizationMember.role == "admin",
                OrganizationMember.status == "active",
            )
        ) or 0
        if admin_count <= 1:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Organization must retain an admin")
    target_membership.role = role
    db.commit()
    return UserActionResponse(
        user_id=user_id,
        organization_id=membership.organization_id,
        role=target_membership.role,
        status=target_membership.status,
    )


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
def remove_user(
    user_id: str,
    membership: OrganizationMember = Depends(organization_admin),
    current_user: User = Depends(current_user),
    db: Session = Depends(get_db_session),
) -> None:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    target_membership = db.scalar(
        select(OrganizationMember).where(
            OrganizationMember.organization_id == membership.organization_id,
            OrganizationMember.user_id == user_id,
            OrganizationMember.status == "active",
        )
    )
    if target_membership is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User is not in this organization")
    if target.system_role == "system_admin" and current_user.system_role != "system_admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="System admin cannot be removed")
    if target_membership.role == "admin":
        admin_count = db.scalar(
            select(func.count(OrganizationMember.id)).where(
                OrganizationMember.organization_id == membership.organization_id,
                OrganizationMember.role == "admin",
                OrganizationMember.status == "active",
            )
        ) or 0
        if admin_count <= 1:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Organization must retain an admin")
    db.delete(target_membership)
    db.commit()


@router.get("/invitations/{token}", response_model=InviteUserResponse)
def validate_invitation(token: str, db: Session = Depends(get_db_session)) -> InviteUserResponse:
    invitation = get_invitation(token, db)
    return InviteUserResponse(
        email=invitation.email,
        role=invitation.role,
        registration_path="",
        expires_at=invitation.expires_at,
    )

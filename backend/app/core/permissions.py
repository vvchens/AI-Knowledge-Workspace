from __future__ import annotations

from fastapi import Cookie, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import auth_service
from app.core.config import settings
from app.core.database import get_db_session
from app.models.organization_member import OrganizationMember
from app.models.organization import Organization
from app.models.project_membership import ProjectMembership
from app.models.project import Project
from app.models.user import User


def current_user(
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
    return auth_service.apply_configured_system_role(db, user)


def organization_member(
    user: User = Depends(current_user),
    organization_id: str | None = Header(default=None, alias="X-Organization-Id"),
    db: Session = Depends(get_db_session),
) -> OrganizationMember:
    query = select(OrganizationMember).where(
        OrganizationMember.user_id == user.id,
        OrganizationMember.status == "active",
    )
    if organization_id:
        query = query.where(OrganizationMember.organization_id == organization_id)
    membership = db.scalar(query.order_by(OrganizationMember.created_at.asc()))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User has no organization membership")
    return membership


def organization_admin(
    user: User = Depends(current_user),
    organization_id: str | None = Header(default=None, alias="X-Organization-Id"),
    db: Session = Depends(get_db_session),
) -> OrganizationMember:
    if user.system_role == "system_admin":
        organization_query = select(Organization).where(Organization.status == "active")
        if organization_id:
            organization_query = organization_query.where(Organization.id == organization_id)
        organization = db.scalar(organization_query.order_by(Organization.created_at.asc()))
        if organization is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found",
            )
        membership = db.scalar(
            select(OrganizationMember).where(
                OrganizationMember.organization_id == organization.id,
                OrganizationMember.user_id == user.id,
            )
        )
        if membership is not None:
            return membership
        return OrganizationMember(
            organization_id=organization.id,
            user_id=user.id,
            role="admin",
            status="active",
        )

    membership = organization_member(user=user, organization_id=organization_id, db=db)
    if membership.role not in {"admin", "owner"}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Organization admin permission required")
    return membership


def project_membership(
    project_id: str,
    user: User,
    db: Session,
) -> ProjectMembership:
    membership = db.scalar(
        select(ProjectMembership).where(
            ProjectMembership.project_id == project_id,
            ProjectMembership.user_id == user.id,
        )
    )
    if membership is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Project access denied")
    return membership


def project_for_organization_member(project_id: str, user: User, db: Session) -> Project:
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    if user.system_role == "system_admin":
        return project
    membership = db.scalar(
        select(OrganizationMember)
        .join(Organization, Organization.id == OrganizationMember.organization_id)
        .where(
            OrganizationMember.organization_id == project.organization_id,
            OrganizationMember.user_id == user.id,
            OrganizationMember.status == "active",
            Organization.status == "active",
        )
    )
    if membership is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Project access denied")
    return project


def require_system_admin(user: User = Depends(current_user)) -> User:
    if user.system_role != "system_admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="System admin permission required")
    return user
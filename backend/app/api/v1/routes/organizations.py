from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db_session
from app.core.permissions import current_user, require_system_admin
from app.models.organization import Organization
from app.models.organization_member import OrganizationMember
from app.models.user import User


router = APIRouter(prefix="/organizations", tags=["organizations"])


class OrganizationCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    slug: str = Field(min_length=1, max_length=255, pattern=r"^[a-z0-9-]+$")


class OrganizationUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    slug: str | None = Field(default=None, min_length=1, max_length=255, pattern=r"^[a-z0-9-]+$")
    status: str | None = Field(default=None, pattern=r"^(active|disabled)$")


class OrganizationAdminRequest(BaseModel):
    user_id: str = Field(min_length=1)


class OrganizationMemberResponse(BaseModel):
    organization_id: str
    user_id: str
    role: str
    status: str


class OrganizationResponse(BaseModel):
    id: str
    name: str
    slug: str
    status: str


class OrganizationListResponse(BaseModel):
    organizations: list[OrganizationResponse]
    can_manage: bool


def _to_response(organization: Organization) -> OrganizationResponse:
    return OrganizationResponse(
        id=organization.id,
        name=organization.name,
        slug=organization.slug,
        status=organization.status,
    )


@router.get("", response_model=OrganizationListResponse)
def list_organizations(
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
) -> OrganizationListResponse:
    if user.system_role == "system_admin":
        organizations = db.scalars(select(Organization).order_by(Organization.name.asc())).all()
        return OrganizationListResponse(
            organizations=[_to_response(item) for item in organizations],
            can_manage=True,
        )

    memberships = db.scalars(
        select(OrganizationMember)
        .where(
            OrganizationMember.user_id == user.id,
            OrganizationMember.status == "active",
        )
        .order_by(OrganizationMember.created_at.asc())
    ).all()
    organization_ids = [membership.organization_id for membership in memberships]
    organizations = db.scalars(
        select(Organization)
        .where(Organization.id.in_(organization_ids), Organization.status == "active")
        .order_by(Organization.name.asc())
    ).all()
    return OrganizationListResponse(
        organizations=[_to_response(item) for item in organizations],
        can_manage=False,
    )


@router.post("", response_model=OrganizationResponse, status_code=status.HTTP_201_CREATED)
def create_organization(
    payload: OrganizationCreateRequest,
    db: Session = Depends(get_db_session),
    _: User = Depends(require_system_admin),
) -> OrganizationResponse:
    if db.scalar(select(Organization).where(Organization.slug == payload.slug)) is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Organization slug already exists")
    organization = Organization(name=payload.name.strip(), slug=payload.slug)
    db.add(organization)
    db.commit()
    db.refresh(organization)
    return _to_response(organization)


@router.post("/{organization_id}/disable", response_model=OrganizationResponse)
def disable_organization(
    organization_id: str,
    db: Session = Depends(get_db_session),
    _: User = Depends(require_system_admin),
) -> OrganizationResponse:
    organization = db.get(Organization, organization_id)
    if organization is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organization not found")
    organization.status = "disabled"
    db.commit()
    db.refresh(organization)
    return _to_response(organization)


@router.patch("/{organization_id}", response_model=OrganizationResponse)
def update_organization(
    organization_id: str,
    payload: OrganizationUpdateRequest,
    db: Session = Depends(get_db_session),
    _: User = Depends(require_system_admin),
) -> OrganizationResponse:
    organization = db.get(Organization, organization_id)
    if organization is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organization not found")
    if payload.slug is not None:
        duplicate = db.scalar(
            select(Organization).where(
                Organization.slug == payload.slug,
                Organization.id != organization_id,
            )
        )
        if duplicate is not None:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Organization slug already exists")
        organization.slug = payload.slug
    if payload.name is not None:
        organization.name = payload.name.strip()
    if payload.status is not None:
        organization.status = payload.status
    db.commit()
    db.refresh(organization)
    return _to_response(organization)


@router.post(
    "/{organization_id}/admins",
    response_model=OrganizationMemberResponse,
)
def set_organization_admin(
    organization_id: str,
    payload: OrganizationAdminRequest,
    db: Session = Depends(get_db_session),
    _: User = Depends(require_system_admin),
) -> OrganizationMemberResponse:
    if db.get(Organization, organization_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organization not found")
    if db.get(User, payload.user_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    membership = db.scalar(
        select(OrganizationMember).where(
            OrganizationMember.organization_id == organization_id,
            OrganizationMember.user_id == payload.user_id,
        )
    )
    if membership is None:
        membership = OrganizationMember(
            organization_id=organization_id,
            user_id=payload.user_id,
            role="admin",
            status="active",
        )
        db.add(membership)
    else:
        membership.role = "admin"
        membership.status = "active"
    db.commit()
    db.refresh(membership)
    return OrganizationMemberResponse(
        organization_id=membership.organization_id,
        user_id=membership.user_id,
        role=membership.role,
        status=membership.status,
    )
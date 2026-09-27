from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db_session
from app.core.permissions import current_user, organization_member, project_membership
from app.models.project import Project
from app.models.project_membership import ProjectMembership
from app.models.user import User
from app.models.organization_member import OrganizationMember


router = APIRouter(prefix="/projects", tags=["projects"])


class ProjectCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    description: str = Field(default="", max_length=10000)


class ProjectResponse(BaseModel):
    id: str
    name: str
    description: str
    status: str
    documents: int
    members: int
    created_at: datetime
    updated_at: datetime


class ProjectListResponse(BaseModel):
    projects: list[ProjectResponse]


def _to_response(project: Project) -> ProjectResponse:
    return ProjectResponse(
        id=project.id,
        name=project.name,
        description=project.description,
        status=project.status,
        documents=0,
        members=1,
        created_at=project.created_at,
        updated_at=project.updated_at,
    )


@router.get("", response_model=ProjectListResponse)
def list_projects(
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
) -> ProjectListResponse:
    projects = db.scalars(
        select(Project)
        .join(ProjectMembership, ProjectMembership.project_id == Project.id)
        .where(ProjectMembership.user_id == user.id)
        .order_by(Project.updated_at.desc())
    ).all()
    return ProjectListResponse(projects=[_to_response(project) for project in projects])


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
def create_project(
    payload: ProjectCreateRequest,
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
    organization: OrganizationMember = Depends(organization_member),
) -> ProjectResponse:
    project = Project(
        owner_id=user.id,
        organization_id=organization.organization_id,
        name=payload.name.strip(),
        description=payload.description.strip(),
    )
    db.add(project)
    db.commit()
    db.refresh(project)
    db.add(ProjectMembership(project_id=project.id, user_id=user.id, role="owner"))
    db.commit()
    return _to_response(project)


@router.get("/{project_id}", response_model=ProjectResponse)
def get_project(
    project_id: str,
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
) -> ProjectResponse:
    project_membership(project_id, user, db)
    project = db.get(Project, project_id)
    if project is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return _to_response(project)

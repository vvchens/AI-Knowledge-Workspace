from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.project import Project, ProjectMembership
from app.schemas.project import ProjectCreate, ProjectUpdate


def list_user_projects(db: Session, user_id: str) -> list[Project]:
    return list(
        db.scalars(
            select(Project)
            .join(ProjectMembership, ProjectMembership.project_id == Project.id)
            .where(ProjectMembership.user_id == user_id)
            .order_by(Project.updated_at.desc())
        )
    )


def create_project(db: Session, user_id: str, payload: ProjectCreate) -> Project:
    project = Project(
        owner_id=user_id,
        name=payload.name,
        slug=payload.slug,
        description=payload.description,
    )
    db.add(project)
    db.flush()
    db.add(ProjectMembership(project_id=project.id, user_id=user_id, role="owner"))
    db.commit()
    db.refresh(project)
    return project


def get_user_project(db: Session, user_id: str, project_id: str) -> Project | None:
    return db.scalar(
        select(Project)
        .join(ProjectMembership, ProjectMembership.project_id == Project.id)
        .where(Project.id == project_id, ProjectMembership.user_id == user_id)
    )


def update_project(db: Session, project: Project, payload: ProjectUpdate) -> Project:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(project, field, value)
    db.commit()
    db.refresh(project)
    return project
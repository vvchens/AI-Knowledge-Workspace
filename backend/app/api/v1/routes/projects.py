from fastapi import APIRouter, Cookie, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth import AuthService
from app.core.config import settings
from app.core.database import get_db_session
from app.schemas.project import ProjectCreate, ProjectResponse, ProjectUpdate
from app.services.projects import create_project, get_user_project, list_user_projects, update_project

router = APIRouter(prefix="/projects", tags=["projects"])
auth_service = AuthService()


def current_user_id(
    session_token: str | None = Cookie(default=None, alias=settings.session_cookie_name),
    db: Session = Depends(get_db_session),
) -> str:
    if not session_token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing session")
    user = auth_service.get_user_from_session(db, session_token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session")
    return user.id


@router.get("", response_model=list[ProjectResponse])
def list_projects(user_id: str = Depends(current_user_id), db: Session = Depends(get_db_session)) -> list:
    return list_user_projects(db, user_id)


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
def create_project_route(
    payload: ProjectCreate,
    user_id: str = Depends(current_user_id),
    db: Session = Depends(get_db_session),
) -> ProjectResponse:
    return create_project(db, user_id, payload)


@router.patch("/{project_id}", response_model=ProjectResponse)
def update_project_route(
    project_id: str,
    payload: ProjectUpdate,
    user_id: str = Depends(current_user_id),
    db: Session = Depends(get_db_session),
) -> ProjectResponse:
    project = get_user_project(db, user_id, project_id)
    if project is None or project.owner_id != user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return update_project(db, project, payload)

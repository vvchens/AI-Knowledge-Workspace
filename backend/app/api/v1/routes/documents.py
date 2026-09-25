from __future__ import annotations

import logging
import shutil
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, Depends, File, Header, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import auth_service
from app.core.config import settings
from app.core.database import get_db_session
from app.models.document import Document, DocumentStatus
from app.models.project import Project
from app.models.user import User
from app.services.document_ingestion import process_document


router = APIRouter(prefix="/projects/{project_id}/documents", tags=["documents"])
logger = logging.getLogger(__name__)

SUPPORTED_DOCUMENT_EXTENSIONS = {".pdf", ".txt", ".md"}
SUPPORTED_DOCUMENT_CONTENT_TYPES = {
    "application/pdf",
    "text/plain",
    "text/markdown",
}


class DocumentResponse(BaseModel):
    id: str
    name: str
    content_type: str | None
    size_bytes: int
    status: DocumentStatus
    created_at: str
    updated_at: str


class DocumentListResponse(BaseModel):
    documents: list[DocumentResponse]


def _current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db_session),
) -> User:
    session_token = None
    if authorization and authorization.lower().startswith("bearer "):
        session_token = authorization[7:].strip()
    if not session_token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing session")

    user = auth_service.get_user_from_session(db, session_token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session")
    return user


def _project_for_user(project_id: str, user: User, db: Session) -> Project:
    project = db.scalar(select(Project).where(Project.id == project_id, Project.owner_id == user.id))
    if project is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return project


def _to_response(document: Document) -> DocumentResponse:
    return DocumentResponse(
        id=document.id,
        name=document.name,
        content_type=document.content_type,
        size_bytes=document.size_bytes,
        status=document.status,
        created_at=document.created_at.isoformat(),
        updated_at=document.updated_at.isoformat(),
    )


@router.get("", response_model=DocumentListResponse)
def list_documents(
    project_id: str,
    db: Session = Depends(get_db_session),
    user: User = Depends(_current_user),
) -> DocumentListResponse:
    _project_for_user(project_id, user, db)
    documents = db.scalars(
        select(Document)
        .where(Document.project_id == project_id, Document.owner_id == user.id)
        .order_by(Document.created_at.desc())
    ).all()
    return DocumentListResponse(documents=[_to_response(document) for document in documents])


@router.post("", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
def upload_document(
    project_id: str,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    db: Session = Depends(get_db_session),
    user: User = Depends(_current_user),
) -> DocumentResponse:
    _project_for_user(project_id, user, db)
    original_name = Path(file.filename or "document").name
    if not original_name:
        logger.warning("Document upload rejected: missing file name")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing file name")
    extension = Path(original_name).suffix.lower()
    if extension not in SUPPORTED_DOCUMENT_EXTENSIONS and file.content_type not in SUPPORTED_DOCUMENT_CONTENT_TYPES:
        logger.warning(
            "Document upload rejected: unsupported file type name=%s content_type=%s",
            original_name,
            file.content_type,
        )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Only PDF, TXT, and Markdown files are supported",
        )

    upload_root = Path(settings.upload_dir).resolve()
    project_dir = (upload_root / project_id).resolve()
    if upload_root not in project_dir.parents:
        logger.error("Document upload rejected: invalid upload path for project=%s", project_id)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid upload path")
    project_dir.mkdir(parents=True, exist_ok=True)

    stored_name = f"{uuid4()}_{original_name}"
    stored_path = project_dir / stored_name
    with stored_path.open("wb") as destination:
        shutil.copyfileobj(file.file, destination)
    size_bytes = stored_path.stat().st_size

    document = Document(
        project_id=project_id,
        owner_id=user.id,
        name=original_name,
        storage_path=str(stored_path),
        content_type=file.content_type,
        size_bytes=size_bytes,
        status=DocumentStatus.PROCESSING,
    )
    db.add(document)
    db.commit()
    db.refresh(document)
    background_tasks.add_task(process_document, document.id)
    logger.info(
        "Document uploaded and queued for indexing document_id=%s project_id=%s name=%s size_bytes=%d",
        document.id,
        project_id,
        original_name,
        size_bytes,
    )
    return _to_response(document)


@router.delete(
    "/{document_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_model=None,
)
def delete_document(
    project_id: str,
    document_id: str,
    db: Session = Depends(get_db_session),
    user: User = Depends(_current_user),
) -> None:
    _project_for_user(project_id, user, db)
    document = db.scalar(
        select(Document).where(
            Document.id == document_id,
            Document.project_id == project_id,
            Document.owner_id == user.id,
        )
    )
    if document is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")

    upload_root = Path(settings.upload_dir).resolve()
    stored_path = Path(document.storage_path).resolve()
    if upload_root not in stored_path.parents:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Invalid document storage path")

    try:
        stored_path.unlink(missing_ok=True)
    except OSError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Document file could not be deleted",
        ) from exc

    db.delete(document)
    db.commit()

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.auth import auth_service
from app.core.database import get_db_session
from app.models.document import Document, DocumentChunk
from app.models.project import Project
from app.models.user import User
from app.services.embedding import EmbeddingError, embed_texts


router = APIRouter(prefix="/projects/{project_id}/search", tags=["search"])


class SearchRequest(BaseModel):
    query: str = Field(min_length=1, max_length=1000)
    limit: int = Field(default=10, ge=1, le=50)


class SearchResultResponse(BaseModel):
    document_id: str
    document_name: str
    chunk_id: str
    content: str
    page_number: int | None
    score: float


class SearchResponse(BaseModel):
    results: list[SearchResultResponse]


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


@router.post("", response_model=SearchResponse)
def search_project(
    project_id: str,
    payload: SearchRequest,
    db: Session = Depends(get_db_session),
    user: User = Depends(_current_user),
) -> SearchResponse:
    project = db.scalar(select(Project).where(Project.id == project_id, Project.owner_id == user.id))
    if project is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

    try:
        query_embedding = embed_texts([payload.query.strip()])[0]
    except EmbeddingError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Search embedding service is unavailable",
        ) from exc

    distance = DocumentChunk.embedding.cosine_distance(query_embedding).label("distance")
    rows = db.execute(
        select(DocumentChunk, Document, distance)
        .join(Document, Document.id == DocumentChunk.document_id)
        .where(
            Document.project_id == project_id,
            Document.owner_id == user.id,
            Document.status == "indexed",
        )
        .order_by(distance)
        .limit(payload.limit)
    ).all()

    return SearchResponse(
        results=[
            SearchResultResponse(
                document_id=document.id,
                document_name=document.name,
                chunk_id=chunk.id,
                content=chunk.content,
                page_number=chunk.page_number,
                score=max(0.0, min(1.0, 1.0 - float(distance_value))),
            )
            for chunk, document, distance_value in rows
        ]
    )
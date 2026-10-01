from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.v1.routes.search import SearchRequest, SearchResponse, search_project
from app.core.database import get_db_session
from app.core.permissions import current_user, project_for_organization_member
from app.models.conversation import Conversation, ConversationMessage
from app.models.user import User


router = APIRouter(prefix="/projects/{project_id}", tags=["conversations"])


class ConversationSummaryResponse(BaseModel):
    id: str
    project_id: str
    title: str
    message_count: int
    created_at: datetime
    updated_at: datetime


class ConversationMessageResponse(BaseModel):
    id: str
    role: str
    content: str
    citations: list[dict[str, object]] | None
    created_at: datetime


class ConversationResponse(ConversationSummaryResponse):
    messages: list[ConversationMessageResponse]


class ChatRequest(BaseModel):
    query: str = Field(min_length=1, max_length=1000)
    conversation_id: str | None = None


class ChatResponse(SearchResponse):
    conversation_id: str


def _conversation_or_404(
    project_id: str,
    conversation_id: str,
    user: User,
    db: Session,
) -> Conversation:
    conversation = db.scalar(
        select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.project_id == project_id,
            Conversation.user_id == user.id,
        )
    )
    if conversation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
    return conversation


def _summary(conversation: Conversation, message_count: int) -> ConversationSummaryResponse:
    return ConversationSummaryResponse(
        id=conversation.id,
        project_id=conversation.project_id,
        title=conversation.title,
        message_count=message_count,
        created_at=conversation.created_at,
        updated_at=conversation.updated_at,
    )


@router.get("/conversations", response_model=list[ConversationSummaryResponse])
def list_conversations(
    project_id: str,
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
) -> list[ConversationSummaryResponse]:
    project_for_organization_member(project_id, user, db)
    conversations = db.scalars(
        select(Conversation)
        .where(
            Conversation.project_id == project_id,
            Conversation.user_id == user.id,
        )
        .order_by(Conversation.updated_at.desc())
    ).all()
    response = []
    for conversation in conversations:
        count = db.scalar(
            select(func.count(ConversationMessage.id)).where(
                ConversationMessage.conversation_id == conversation.id,
            )
        )
        response.append(_summary(conversation, count or 0))
    return response


@router.get("/conversations/{conversation_id}", response_model=ConversationResponse)
def get_conversation(
    project_id: str,
    conversation_id: str,
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
) -> ConversationResponse:
    project_for_organization_member(project_id, user, db)
    conversation = _conversation_or_404(project_id, conversation_id, user, db)
    messages = db.scalars(
        select(ConversationMessage)
        .where(ConversationMessage.conversation_id == conversation.id)
        .order_by(ConversationMessage.created_at.asc())
    ).all()
    return ConversationResponse(
        **_summary(conversation, len(messages)).model_dump(),
        messages=[
            ConversationMessageResponse(
                id=message.id,
                role=message.role,
                content=message.content,
                citations=message.citations,
                created_at=message.created_at,
            )
            for message in messages
        ],
    )


@router.post("/chat", response_model=ChatResponse)
async def chat(
    project_id: str,
    payload: ChatRequest,
    db: Session = Depends(get_db_session),
    user: User = Depends(current_user),
) -> ChatResponse:
    project_for_organization_member(project_id, user, db)
    conversation = None
    if payload.conversation_id is not None:
        conversation = _conversation_or_404(project_id, payload.conversation_id, user, db)

    search_response = await search_project(
        project_id=project_id,
        payload=SearchRequest(query=payload.query),
        db=db,
        user=user,
    )
    if conversation is None:
        conversation = Conversation(
            project_id=project_id,
            user_id=user.id,
            title=payload.query.strip()[:255],
        )
        db.add(conversation)
        db.flush()

    citations = [result.model_dump() for result in search_response.results]
    db.add(
        ConversationMessage(
            conversation_id=conversation.id,
            project_id=project_id,
            user_id=user.id,
            role="user",
            content=payload.query.strip(),
        )
    )
    db.add(
        ConversationMessage(
            conversation_id=conversation.id,
            project_id=project_id,
            user_id=user.id,
            role="assistant",
            content=search_response.answer,
            citations=citations,
        )
    )
    conversation.updated_at = func.now()
    db.commit()
    return ChatResponse(
        conversation_id=conversation.id,
        rewritten_query=search_response.rewritten_query,
        answer=search_response.answer,
        results=search_response.results,
    )

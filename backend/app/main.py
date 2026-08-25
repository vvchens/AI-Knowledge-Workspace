from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import database


@asynccontextmanager
async def lifespan(_: FastAPI):
    database.check_connection()
    yield
    database.close()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="Phase 1 skeleton for AI Knowledge Workspace",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check() -> dict[str, str]:
    try:
        database.check_connection()
    except SQLAlchemyError:
        return {
            "status": "degraded",
            "service": settings.app_name,
            "database": "unavailable",
        }

    return {
        "status": "ok",
        "service": settings.app_name,
        "database": "connected",
    }


app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "AI Knowledge Workspace API"}

from contextlib import asynccontextmanager
import logging
from time import perf_counter

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import database
from app.services.embedding_schema import validate_embedding_schema


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("Starting %s", settings.app_name)
    try:
        database.check_connection()
        with database.session() as db:
            validate_embedding_schema(db)
    except Exception:
        logger.exception("Application startup validation failed")
        raise
    logger.info("Application startup validation completed")
    yield
    logger.info("Shutting down %s", settings.app_name)
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


@app.middleware("http")
async def log_requests(request, call_next):
    started_at = perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        logger.exception("Unhandled request error: %s %s", request.method, request.url.path)
        raise

    duration_ms = (perf_counter() - started_at) * 1000
    message = "%s %s -> %s (%.1f ms)"
    if response.status_code >= 500:
        logger.error(message, request.method, request.url.path, response.status_code, duration_ms)
    elif response.status_code >= 400:
        logger.warning(message, request.method, request.url.path, response.status_code, duration_ms)
    else:
        logger.info(message, request.method, request.url.path, response.status_code, duration_ms)
    return response


@app.get("/health")
def health_check() -> dict[str, str]:
    try:
        database.check_connection()
    except SQLAlchemyError:
        logger.warning("Health check failed: database is unavailable", exc_info=True)
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

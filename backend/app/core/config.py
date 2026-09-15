from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


PROJECT_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    app_name: str = Field(default="AI Knowledge Workspace", validation_alias="APP_NAME")
    api_v1_prefix: str = Field(default="/api/v1", validation_alias="API_V1_PREFIX")
    environment: str = Field(default="development", validation_alias="ENVIRONMENT")
    dev: bool = Field(default=False, validation_alias="DEV")

    db_host: str = Field(default="localhost", validation_alias="DB_HOST")
    db_port: int = Field(default=5432, validation_alias="DB_PORT")
    db_name: str = Field(default="ai_knowledge_workspace", validation_alias="DB_NAME")
    db_user: str = Field(default="postgres", validation_alias="DB_USER")
    db_password: str = Field(default="postgres", validation_alias="DB_PASSWORD")

    firebase_project_id: str | None = Field(default=None, validation_alias="FIREBASE_PROJECT_ID")
    firebase_service_account_json: str | None = Field(
        default=None,
        validation_alias="FIREBASE_SERVICE_ACCOUNT_JSON",
    )
    firebase_service_account_file: str | None = Field(
        default=None,
        validation_alias="FIREBASE_SERVICE_ACCOUNT_FILE",
    )
    firebase_check_revoked: bool = Field(
        default=False,
        validation_alias="FIREBASE_CHECK_REVOKED",
    )
    firebase_clock_skew_seconds: int = Field(
        default=5,
        validation_alias="FIREBASE_CLOCK_SKEW_SECONDS",
        ge=0,
        le=60,
    )

    session_ttl_hours: int = Field(default=168, validation_alias="SESSION_TTL_HOURS")
    session_cookie_name: str = Field(default="akw_session", validation_alias="SESSION_COOKIE_NAME")
    session_cookie_secure: bool = Field(default=False, validation_alias="SESSION_COOKIE_SECURE")
    upload_dir: str = Field(
        default=str(PROJECT_ROOT / "backend" / "uploads"),
        validation_alias="UPLOAD_DIR",
    )
    embedding_api_url: str | None = Field(default=None, validation_alias="EMBEDDING_API_URL")
    embedding_api_key: str | None = Field(default=None, validation_alias="EMBEDDING_API_KEY")
    embedding_model: str = Field(default="text-embedding-3-small", validation_alias="EMBEDDING_MODEL")
    embedding_dimensions: int = Field(default=1536, validation_alias="EMBEDDING_DIMENSIONS", gt=0)
    document_chunk_size: int = Field(default=1000, validation_alias="DOCUMENT_CHUNK_SIZE", gt=0)
    document_chunk_overlap: int = Field(default=150, validation_alias="DOCUMENT_CHUNK_OVERLAP", ge=0)

    model_config = SettingsConfigDict(
        env_file=(str(PROJECT_ROOT / ".env"), ".env"),
        extra="ignore",
    )


settings = Settings()

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

    session_ttl_hours: int = Field(default=168, validation_alias="SESSION_TTL_HOURS")
    session_cookie_name: str = Field(default="akw_session", validation_alias="SESSION_COOKIE_NAME")
    session_cookie_secure: bool = Field(default=False, validation_alias="SESSION_COOKIE_SECURE")

    model_config = SettingsConfigDict(
        env_file=(str(PROJECT_ROOT / ".env"), ".env"),
        extra="ignore",
    )


settings = Settings()

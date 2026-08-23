from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "AI Knowledge Workspace"
    api_v1_prefix: str = "/api/v1"
    environment: str = "development"
    dev: bool = False

    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "ai_knowledge_workspace"
    db_user: str = "postgres"
    db_password: str = "postgres"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()

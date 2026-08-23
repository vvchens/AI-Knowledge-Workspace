from __future__ import annotations

from dataclasses import dataclass

from app.core.config import settings


@dataclass
class DatabaseConfig:
    host: str = settings.db_host
    port: int = settings.db_port
    database: str = settings.db_name
    username: str = settings.db_user
    password: str = settings.db_password


class DatabaseConnection:
    def __init__(self, config: DatabaseConfig | None = None):
        self.config = config or DatabaseConfig()

    def dsn(self) -> str:
        return (
            f"postgresql://{self.config.username}:{self.config.password}@"
            f"{self.config.host}:{self.config.port}/{self.config.database}"
        )


database = DatabaseConnection()

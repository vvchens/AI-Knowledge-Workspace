from __future__ import annotations

from dataclasses import dataclass


@dataclass
class DatabaseConfig:
    host: str = "localhost"
    port: int = 5432
    database: str = "ai_knowledge_workspace"
    username: str = "postgres"
    password: str = "postgres"


class DatabaseConnection:
    def __init__(self, config: DatabaseConfig | None = None):
        self.config = config or DatabaseConfig()

    def dsn(self) -> str:
        return (
            f"postgresql://{self.config.username}:{self.config.password}@"
            f"{self.config.host}:{self.config.port}/{self.config.database}"
        )


database = DatabaseConnection()

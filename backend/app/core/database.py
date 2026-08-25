from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.orm import Session, sessionmaker

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
        self.engine: Engine = create_engine(
            self.url,
            pool_pre_ping=True,
        )
        self.session_factory = sessionmaker(
            bind=self.engine,
            autocommit=False,
            autoflush=False,
        )

    @property
    def url(self) -> URL:
        return URL.create(
            drivername="postgresql+psycopg",
            username=self.config.username,
            password=self.config.password,
            host=self.config.host,
            port=self.config.port,
            database=self.config.database,
        )

    def dsn(self) -> str:
        return self.url.render_as_string(hide_password=False)

    def check_connection(self) -> None:
        with self.engine.connect() as connection:
            connection.execute(text("SELECT 1"))

    def session(self) -> Session:
        return self.session_factory()

    def close(self) -> None:
        self.engine.dispose()


database = DatabaseConnection()

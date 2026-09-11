from __future__ import annotations

import re

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings


class EmbeddingSchemaMismatchError(RuntimeError):
    pass


def database_embedding_dimensions(db: Session) -> int | None:
    column_type = db.scalar(
        text(
            """
            SELECT format_type(a.atttypid, a.atttypmod)
            FROM pg_attribute AS a
            JOIN pg_class AS c ON c.oid = a.attrelid
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = current_schema()
              AND c.relname = 'document_chunks'
              AND a.attname = 'embedding'
              AND NOT a.attisdropped
            """
        )
    )
    if column_type is None:
        return None
    match = re.fullmatch(r"vector\((\d+)\)", column_type)
    if match is None:
        raise EmbeddingSchemaMismatchError(
            f"document_chunks.embedding has unsupported type {column_type!r}"
        )
    return int(match.group(1))


def validate_embedding_schema(db: Session) -> None:
    actual_dimensions = database_embedding_dimensions(db)
    if actual_dimensions is None:
        return
    if actual_dimensions != settings.embedding_dimensions:
        raise EmbeddingSchemaMismatchError(
            "Embedding dimension mismatch: "
            f"database={actual_dimensions}, environment={settings.embedding_dimensions}. "
            "Run the explicit embedding rebuild before starting the API."
        )
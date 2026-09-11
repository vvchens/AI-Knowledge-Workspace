from __future__ import annotations

from sqlalchemy import text

from app.core.config import settings
from app.core.database import database
from app.models.document import DocumentChunk
from app.services.embedding import embed_texts
from app.services.embedding_schema import database_embedding_dimensions


BATCH_SIZE = 32


def _vector_literal(embedding: list[float]) -> str:
    return "[" + ",".join(format(value, ".17g") for value in embedding) + "]"


def rebuild_embeddings() -> None:
    db = database.session()
    try:
        current_dimensions = database_embedding_dimensions(db)
        if current_dimensions is None:
            raise RuntimeError("document_chunks.embedding does not exist")
        if current_dimensions == settings.embedding_dimensions:
            print(f"Embedding dimension is already {current_dimensions}; nothing to rebuild.")
            return

        chunks = db.query(DocumentChunk.id, DocumentChunk.content).order_by(DocumentChunk.id).all()
        new_dimensions = settings.embedding_dimensions
        db.execute(text(f"ALTER TABLE document_chunks ADD COLUMN embedding_rebuilt vector({new_dimensions})"))

        for start in range(0, len(chunks), BATCH_SIZE):
            batch = chunks[start : start + BATCH_SIZE]
            embeddings = embed_texts([chunk.content for chunk in batch])
            for chunk, embedding in zip(batch, embeddings):
                db.execute(
                    text(
                        "UPDATE document_chunks "
                        "SET embedding_rebuilt = CAST(:embedding AS vector) "
                        "WHERE id = :chunk_id"
                    ),
                    {"embedding": _vector_literal(embedding), "chunk_id": chunk.id},
                )

        if chunks:
            missing = db.scalar(
                text("SELECT COUNT(*) FROM document_chunks WHERE embedding_rebuilt IS NULL")
            )
            if missing:
                raise RuntimeError(f"{missing} chunks were not re-embedded")

        db.execute(
            text(
                "ALTER TABLE document_chunks "
                "ALTER COLUMN embedding_rebuilt SET NOT NULL"
            )
        )
        db.execute(text("ALTER TABLE document_chunks DROP COLUMN embedding"))
        db.execute(
            text(
                "ALTER TABLE document_chunks "
                "RENAME COLUMN embedding_rebuilt TO embedding"
            )
        )
        db.commit()
        print(f"Rebuilt embeddings from {current_dimensions} to {new_dimensions} dimensions.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    rebuild_embeddings()
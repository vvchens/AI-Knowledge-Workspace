from __future__ import annotations

import logging
from pathlib import Path

from pypdf import PdfReader

from app.core.database import database
from app.core.config import settings
from app.models.document import Document, DocumentChunk
from app.services.embedding import embed_texts


logger = logging.getLogger(__name__)


def _chunks_for_page(text: str) -> list[str]:
    normalized = " ".join(text.split())
    if not normalized:
        return []
    size = settings.document_chunk_size
    overlap = min(settings.document_chunk_overlap, size - 1)
    step = size - overlap
    return [normalized[start : start + size] for start in range(0, len(normalized), step)]


def process_document(document_id: str) -> None:
    db = database.session()
    document = db.get(Document, document_id)
    if document is None:
        db.close()
        return

    try:
        reader = PdfReader(Path(document.storage_path))
        chunks_with_pages: list[tuple[str, int]] = []
        for page_number, page in enumerate(reader.pages, start=1):
            chunks_with_pages.extend((chunk, page_number) for chunk in _chunks_for_page(page.extract_text() or ""))

        if not chunks_with_pages:
            raise ValueError("PDF contains no extractable text")

        embeddings = embed_texts([content for content, _ in chunks_with_pages])
        db.query(DocumentChunk).filter(DocumentChunk.document_id == document.id).delete()
        db.add_all(
            DocumentChunk(
                document_id=document.id,
                chunk_index=index,
                content=content,
                page_number=page_number,
                embedding=embedding,
            )
            for index, ((content, page_number), embedding) in enumerate(zip(chunks_with_pages, embeddings))
        )
        document.status = "indexed"
        db.commit()
    except Exception:
        db.rollback()
        document = db.get(Document, document_id)
        if document is not None:
            document.status = "failed"
            db.commit()
        logger.exception("Document ingestion failed for %s", document_id)
    finally:
        db.close()
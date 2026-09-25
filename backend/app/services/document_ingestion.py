from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field
from pathlib import Path
from uuid import uuid4

from pypdf import PdfReader

from app.core.database import database
from app.core.config import settings
from app.models.document import Document, DocumentChunk, DocumentStatus
from app.services.embedding import embed_texts


logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class TextChunk:
    content: str
    page_number: int | None = None
    metadata: dict[str, object] = field(default_factory=dict)


def _recursive_chunks(text: str) -> list[str]:
    """Split text on paragraph, line, word, then character boundaries."""
    text = text.strip()
    if not text:
        return []
    size = settings.document_chunk_size
    overlap = min(settings.document_chunk_overlap, size - 1)
    separators = ("\n\n", "\n", " ", "")

    def split_piece(piece: str, separator_index: int) -> list[str]:
        if len(piece) <= size:
            return [piece]
        separator = separators[separator_index]
        if not separator:
            return [piece[start : start + size] for start in range(0, len(piece), size)]
        parts = piece.split(separator)
        result: list[str] = []
        current = ""
        for part in parts:
            candidate = part if not current else current + separator + part
            if len(candidate) <= size:
                current = candidate
                continue
            if current:
                result.extend(split_piece(current, separator_index + 1))
            current = part
        if current:
            result.extend(split_piece(current, separator_index + 1))
        return result

    pieces = split_piece(text, 0)
    chunks: list[str] = []
    for piece in pieces:
        if not chunks or overlap == 0:
            chunks.append(piece.strip())
            continue
        prefix = chunks[-1][-overlap:]
        combined = (prefix + piece).strip()
        chunks.append(combined if len(combined) <= size else piece.strip())
    return [chunk for chunk in chunks if chunk]


def _markdown_chunks(text: str) -> list[TextChunk]:
    sections: list[tuple[list[str], list[str]]] = []
    heading_path: list[str] = []
    section_lines: list[str] = []
    heading_pattern = re.compile(r"^(#{1,3})\s+(.+?)\s*$")

    def flush() -> None:
        if section_lines:
            sections.append((section_lines.copy(), heading_path.copy()))
            section_lines.clear()

    for line in text.splitlines(keepends=True):
        match = heading_pattern.match(line.rstrip("\r\n"))
        if match:
            flush()
            level = len(match.group(1))
            heading_path[:] = heading_path[: level - 1]
            heading_path.append(match.group(2))
        section_lines.append(line)
    flush()

    chunks: list[TextChunk] = []
    for lines, headings in sections:
        for content in _recursive_chunks("".join(lines)):
            chunks.append(TextChunk(content=content, metadata={"headings": headings}))
    return chunks


def _extract_text(document: Document) -> list[TextChunk]:
    suffix = Path(document.name).suffix.lower()
    if suffix == ".pdf":
        reader = PdfReader(Path(document.storage_path))
        return [
            TextChunk(content=chunk, page_number=page_number)
            for page_number, page in enumerate(reader.pages, start=1)
            for chunk in _recursive_chunks(page.extract_text() or "")
        ]

    if suffix == ".md":
        text = Path(document.storage_path).read_text(encoding="utf-8-sig")
        return _markdown_chunks(text)

    if suffix == ".txt":
        text = Path(document.storage_path).read_text(encoding="utf-8-sig")
        text = re.sub(r"\n[ \t]*\n(?:[ \t]*\n)+", "\n\n", text)
        return [TextChunk(content=chunk) for chunk in _recursive_chunks(text)]

    raise ValueError(f"Unsupported document format: {suffix or 'unknown'}")


def process_document(document_id: str) -> None:
    logger.info("Document indexing started document_id=%s", document_id)
    db = database.session()
    document = db.get(Document, document_id)
    if document is None:
        logger.warning("Document indexing skipped: document not found document_id=%s", document_id)
        db.close()
        return

    try:
        chunks_with_pages = _extract_text(document)
        logger.info(
            "Document text extracted document_id=%s format=%s chunks=%d",
            document_id,
            Path(document.name).suffix.lower() or "unknown",
            len(chunks_with_pages),
        )

        if not chunks_with_pages:
            logger.warning("Document indexing found no extractable text document_id=%s", document_id)
            raise ValueError("Document contains no extractable text")

        logger.info("Generating embeddings document_id=%s chunks=%d", document_id, len(chunks_with_pages))
        embeddings = embed_texts([chunk.content for chunk in chunks_with_pages])
        logger.info("Embeddings generated document_id=%s vectors=%d", document_id, len(embeddings))
        db.query(DocumentChunk).filter(DocumentChunk.document_id == document.id).delete()
        chunk_records = []
        for index, (chunk, embedding) in enumerate(zip(chunks_with_pages, embeddings)):
            chunk_id = str(uuid4())
            chunk_records.append(
                DocumentChunk(
                    id=chunk_id,
                    document_id=document.id,
                    project_id=document.project_id,
                    document_name=document.name,
                    chunk_index=index,
                    content=chunk.content,
                    page_number=chunk.page_number,
                    chunk_metadata={
                        **chunk.metadata,
                        "chunk_id": chunk_id,
                        "document_id": document.id,
                        "project_id": document.project_id,
                        "document_name": document.name,
                    },
                    embedding=embedding,
                )
            )
        db.add_all(chunk_records)
        document.status = DocumentStatus.INDEXED
        db.commit()
        logger.info(
            "Document indexing completed document_id=%s chunks=%d",
            document_id,
            len(chunk_records),
        )
    except Exception:
        db.rollback()
        document = db.get(Document, document_id)
        if document is not None:
            document.status = DocumentStatus.FAILED
            db.commit()
        logger.exception("Document ingestion failed for %s", document_id)
    finally:
        db.close()
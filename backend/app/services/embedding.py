from __future__ import annotations

import json
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from app.core.config import settings


class EmbeddingError(RuntimeError):
    pass


def embed_texts(texts: list[str]) -> list[list[float]]:
    if not settings.embedding_api_url:
        raise EmbeddingError("EMBEDDING_API_URL is not configured")

    payload = json.dumps({"model": settings.embedding_model, "input": texts}).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if settings.embedding_api_key:
        headers["Authorization"] = f"Bearer {settings.embedding_api_key}"

    request = Request(settings.embedding_api_url, data=payload, headers=headers, method="POST")
    try:
        with urlopen(request, timeout=60) as response:
            result = json.load(response)
    except (HTTPError, URLError, TimeoutError) as exc:
        raise EmbeddingError(f"Embedding request failed: {exc}") from exc

    data = sorted(result.get("data", []), key=lambda item: item.get("index", 0))
    embeddings = [item["embedding"] for item in data]
    if len(embeddings) != len(texts):
        raise EmbeddingError("Embedding response count does not match chunk count")
    if any(len(embedding) != settings.embedding_dimensions for embedding in embeddings):
        raise EmbeddingError(f"Embedding dimensions must be {settings.embedding_dimensions}")
    return embeddings
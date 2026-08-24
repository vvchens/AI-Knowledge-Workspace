---
name: ai-knowledge-workspace-rag
description: AI Knowledge Workspace RAG、Agent、Evaluation 实现规范与架构模式。
---

# AI Knowledge Workspace — RAG & AI Runtime Skill

## When to use
- Implementing RAG pipeline components (retrieval, reranking, prompt building)
- Building Agent/Workflow runtime
- Creating evaluation framework
- Working with LLM/Embedding provider abstractions
- Implementing document ingestion (parsing, chunking, embedding)

## RAG Pipeline Architecture (from ARCHITECTURE.md & PHASE0_DESIGN_BASELINE.md)

```
Question
  ↓
Optional Query Rewrite
  ↓
Project Metadata Filter  ← CRITICAL: Project isolation
  ↓
Dense Vector Search (pgvector)  +  Full-Text Search (PostgreSQL FTS)
  ↓
Hybrid Rank Fusion
  ↓
Reranker
  ↓
Context Selection
  ↓
PromptBuilder
  ↓
LLMProvider
  ↓
Answer + Citations
```

## Core Abstractions (Must Be Independently Testable)

| Component | Responsibility |
|-----------|----------------|
| `LLMProvider` | Abstract chat/completion calls (OpenAI, Gemini, Anthropic, Local) |
| `EmbeddingProvider` | Abstract embedding generation |
| `Retriever` | Dense + sparse retrieval with project filtering |
| `Reranker` | Cross-encoder or LLM-based reranking |
| `PromptBuilder` | Construct prompts from context, conversation, system prompt |
| `Tool` | Function calling schema + execution |
| `Agent` | Intent classification, tool orchestration, loop control |
| `EvaluationRunner` | Execute evaluation cases, compute metrics |

## Provider Abstraction Pattern

```python
# Conceptual interface (not yet implemented)
class LLMProvider:
    async def complete(self, messages: list[Message], **kwargs) -> Completion: ...
    async def stream(self, messages: list[Message], **kwargs) -> AsyncIterator[Chunk]: ...

class EmbeddingProvider:
    async def embed(self, texts: list[str]) -> list[list[float]]: ...

# Implementations (to be created)
class OpenAIProvider(LLMProvider): ...
class GeminiProvider(LLMProvider): ...
class AnthropicProvider(LLMProvider): ...
class LocalProvider(LLMProvider): ...  # Future
```

**Rule:** Business code MUST NOT directly call vendor SDKs. All AI calls go through provider abstractions.

## Document Ingestion Pipeline

```
Upload (API)
  ↓
Store original in Object Storage (S3/R2/MinIO)
  ↓
Create Ingestion Job (Redis queue)
  ↓
Worker picks up job
  ↓
Parse → Extract text (PDF, MD, TXT, DOCX)
  ↓
Chunk → Split with overlap (configurable: 512 tokens, 10% overlap)
  ↓
Embed → Generate embeddings via EmbeddingProvider
  ↓
Persist → Chunks + embeddings + metadata to PostgreSQL + pgvector
  ↓
Update document status: Indexed / Failed
```

## Project Isolation in Retrieval (NON-NEGOTIABLE)

```python
# Every retrieval MUST include project filter
async def retrieve(query: str, project_id: str, top_k: int = 10) -> list[Chunk]:
    # 1. Dense search with project_id filter
    dense_results = await dense_search(query, project_id, top_k * 2)
    
    # 2. Full-text search with project_id filter
    fts_results = await full_text_search(query, project_id, top_k * 2)
    
    # 3. Hybrid fusion
    fused = rank_fusion(dense_results, fts_results)
    
    # 4. Rerank
    reranked = await reranker.rerank(query, fused, top_k)
    
    return reranked
```

## Chunking Strategy (Initial)

- **Chunk size:** 512 tokens (configurable per project)
- **Overlap:** 10% (configurable)
- **Metadata preserved:** document_id, project_id, chunk_index, page/section, source_filename, language, document_type

## Citation Format

Answers must include citations referencing source chunks:
```json
{
  "answer": "...",
  "citations": [
    {
      "document_id": "doc_123",
      "chunk_index": 5,
      "page": 3,
      "snippet": "relevant excerpt..."
    }
  ]
}
```

## Agent Runtime (Phase 3)

Initial scope: deliberately small and deterministic.

Capabilities:
- Classify intent (RAG needed? Tool needed? Direct answer?)
- Decide whether retrieval is required
- Call configured tools (max 1-2 per turn initially)
- Combine tool + RAG results
- Produce final answer with citations
- Execution traces for observability

```python
class Agent:
    async def run(self, question: str, project_id: str, conversation_history: list) -> AgentResult:
        # 1. Intent classification
        # 2. If retrieval needed → Retriever
        # 3. If tools needed → Tool execution (with trace)
        # 4. PromptBuilder with context
        # 5. LLMProvider → Answer
        # 6. Return Answer + Citations + ToolTraces
```

## Evaluation Framework (Phase 4)

### Data Model
- `EvaluationSet` — belongs to Project, contains multiple cases
- `EvaluationCase` — question, expected_answer, metadata
- `EvaluationRun` — links to prompt version, model config, retrieval config
- `EvaluationResult` — per-case scores

### Target Metrics
- **Answer correctness** — LLM-as-judge or exact match
- **Retrieval quality** — Recall@K, MRR, NDCG
- **Citation correctness** — Cited chunks actually support answer
- **Groundedness** — Hallucination detection
- **Latency** — End-to-end, retrieval, LLM
- **Token/Cost** — When provider data available

### EvaluationRunner Interface
```python
class EvaluationRunner:
    async def run(self, evaluation_set_id: str, config: EvaluationConfig) -> EvaluationRun:
        # For each case:
        #   1. Run Agent/RAG with config
        #   2. Score against expected_answer
        #   3. Collect metrics
        # 4. Aggregate and persist
```

## Database Schema for AI Runtime (PostgreSQL + pgvector)

```sql
-- Embeddings stored in pgvector
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE document_chunks (
    id UUID PRIMARY KEY,
    document_id UUID REFERENCES documents(id),
    project_id UUID REFERENCES projects(id),
    chunk_index INT,
    content TEXT,
    embedding VECTOR(1536),  -- dimension depends on embedding model
    metadata_json JSONB,
    created_at TIMESTAMPTZ
);

-- Index for vector search
CREATE INDEX ON document_chunks USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Full-text search
ALTER TABLE document_chunks ADD COLUMN fts_vector tsvector
GENERATED ALWAYS AS (to_tsvector('english', content)) STORED;
CREATE INDEX ON document_chunks USING GIN (fts_vector);
```

## Configuration per Project

Each Project can configure:
- `llm_model` — e.g., "gpt-4o-mini", "gemini-1.5-flash"
- `embedding_model` — e.g., "text-embedding-3-small"
- `retrieval_strategy` — "cosine", "cosine+rerank", "hybrid"
- `chunk_size` — tokens
- `chunk_overlap` — percentage
- `temperature` — LLM temperature
- `top_k` — retrieval count
- `reranker_enabled` — boolean
- `system_guardrails` — PII masking, toxicity filter

## Important Implementation Notes

1. **Embedding model versioning** — Store `embedding_model` on Project. Changing it requires re-indexing strategy.
2. **Async throughout** — All AI calls must be async for throughput.
3. **Streaming responses** — Chat API should support SSE/streaming.
4. **Token tracking** — Capture input/output tokens per request for cost tracking.
5. **Error handling** — Provider failures must not crash ingestion; retry with backoff.
6. **Observability** — Log request IDs, latency breakdown, token counts, retrieval stats.
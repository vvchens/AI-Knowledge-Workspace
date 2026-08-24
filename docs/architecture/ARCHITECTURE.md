# AI Knowledge Workspace — Architecture

## 1. Architecture Principles

1. Keep the application simple enough for a two-person team.
2. Prefer managed/cloud services for expensive AI inference.
3. Keep AI providers replaceable.
4. Keep RAG components independently testable.
5. Keep Project data isolated at every layer.
6. Prefer PostgreSQL + pgvector before introducing another vector database.
7. Use asynchronous workers for document ingestion.
8. Use AI coding agents for implementation, but keep architecture decisions human-owned.

---

## 2. High-Level Architecture

```text
                    Web / Mobile Users
                           |
                        Flutter
                           |
                       REST API
                           |
                        FastAPI
                           |
        +------------------+------------------+
        |                  |                  |
   Auth / RBAC        Application         AI Runtime
                         Services              |
        |                  |          +-------+-------+
        |                  |          |       |       |
        |                  |         RAG    Agent   Prompt
        |                  |          |       |       |
        +------------------+----------+-------+-------+
                           |
                    PostgreSQL + pgvector
                           |
             +-------------+-------------+
             |                           |
        Redis / Queue              Object Storage
             |                     S3 / R2 / MinIO
          Worker
             |
      Document Ingestion
             |
      Parse → Chunk → Embed
                           |
                    Cloud LLM / Embedding APIs
```

---

## 3. Client

### Flutter

Single Flutter codebase for:

- Web
- Android
- iOS

Recommended libraries:

- Riverpod — state management
- GoRouter — routing
- Dio — HTTP
- Freezed — immutable models
- json_serializable — JSON serialization

The UI should use Material 3 as its foundation and the project's custom Design System.

---

## 4. Backend

### FastAPI

Responsibilities:

- authentication
- authorization
- Project management
- document management
- chat API
- streaming responses
- prompt management
- evaluation API
- AI runtime orchestration

Backend code should not expose provider-specific implementation details to the Flutter client.

---

## 5. Database

### PostgreSQL + pgvector

PostgreSQL stores:

- users
- projects
- memberships
- documents
- chunks
- embeddings
- conversations
- messages
- prompts
- prompt versions
- evaluation datasets
- evaluation cases
- evaluation results
- audit records

pgvector stores embeddings and performs vector retrieval.

PostgreSQL full-text search may be used for keyword retrieval, enabling hybrid search without adding Elasticsearch in the initial architecture.

---

## 6. Object Storage

Original uploaded files should be stored in S3-compatible object storage.

Examples:

- AWS S3
- Cloudflare R2
- MinIO for local development

PostgreSQL stores metadata and object references, not large document binaries.

---

## 7. Redis and Workers

Redis is optional for the earliest prototype but expected for production-like ingestion.

Use it for:

- job queue
- document processing
- retry state
- caching where justified
- rate limiting where justified

Worker flow:

```text
Upload
  ↓
Create ingestion job
  ↓
Queue
  ↓
Worker
  ↓
Parse
  ↓
Chunk
  ↓
Embed
  ↓
Persist
  ↓
Indexed
```

---

## 8. AI Runtime

The AI runtime should expose application-level abstractions:

```text
LLMProvider
EmbeddingProvider
Retriever
Reranker
PromptBuilder
Tool
Agent
EvaluationRunner
```

Do not let feature code directly call a specific vendor SDK unless the provider implementation is isolated.

---

## 9. RAG Pipeline

```text
User Question
      |
      v
Conversation Context
      |
      v
Query Rewrite (optional)
      |
      v
Project / Metadata Filter
      |
      +--------------------+
      |                    |
      v                    v
Dense Search          Full Text Search
pgvector              PostgreSQL FTS
      |                    |
      +---------+----------+
                v
          Rank Fusion
                |
                v
            Reranker
                |
                v
        Context Selection
                |
                v
          Prompt Builder
                |
                v
             LLM API
                |
                v
       Answer + Citations
```

---

## 10. Multi-Project Isolation

Every Project-owned resource must have a clear Project boundary.

Examples:

```text
Document.project_id
Chunk.document_id → Document.project_id
Conversation.project_id
Prompt.project_id
EvaluationSet.project_id
```

Retrieval must always apply Project authorization/filtering before returning chunks.

The server must never rely on the Flutter client to enforce Project isolation.

---

## 11. Deployment

### Local development

Docker Compose:

```text
flutter
fastapi
postgres
redis
minio
worker
```

LLM and embedding calls go to cloud APIs.

### Initial public deployment

A small VPS is sufficient:

- 4 vCPU
- 8 GB RAM
- SSD

No production GPU is required.

As usage grows, move PostgreSQL and object storage to managed services and scale application/worker processes independently.

---

## 12. Observability

Target capabilities:

- structured application logs
- request IDs
- AI request latency
- retrieval latency
- LLM latency
- token/cost tracking when provider data is available
- ingestion job status
- Agent execution traces
- evaluation run history

Optional later:

- Prometheus
- Grafana
- OpenTelemetry

Do not over-engineer observability in the first milestone.

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

- authentication (Firebase token verification + application session issuance)
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

## 5. Authentication

Authentication follows a **two-layer model**: an external identity provider issues and verifies identity tokens, and the backend issues a separate application session for ongoing API access.

### 5.1 Two-layer model

```text
Flutter (Firebase SDK)
   │  sign in via email/password, Google, or Apple
   ▼
Firebase Authentication
   │  ID token
   ▼
Flutter
   │  POST /api/v1/auth/firebase/session  (Firebase ID token)
   ▼
FastAPI
   │  firebase_admin.verify_id_token(...)
   │  resolve or create local User
   │  issue opaque session, set HttpOnly cookie
   ▼
Subsequent API calls
   │  Cookie: akw_session
   ▼
FastAPI dependency: resolve session → User
```

### 5.2 Identity provider: Firebase

Firebase Authentication is the only identity provider required by Phase 1.

Responsibilities of Firebase:

- User account creation and password / OAuth flows
- Issuing short-lived ID tokens (JWT, signed by Google)
- Native support for Google and Apple OAuth
- Account profile (email, display name, avatar)

Responsibilities delegated to the backend:

- Verifying Firebase ID tokens on every authentication request
- Mapping Firebase identities to local `users` records
- Issuing application sessions

### 5.3 Token verification

The backend uses `firebase_admin` with the Firebase Admin SDK and `check_revoked=True`. Verification can be performed using any of:

- A Service Account JSON string (preferred for CI / secrets injection)
- A Service Account JSON file path
- Application Default Credentials in managed environments

Project ID is passed explicitly via configuration. The Service Account JSON is loaded from environment variables (`FIREBASE_SERVICE_ACCOUNT_JSON` / `FIREBASE_SERVICE_ACCOUNT_FILE`) and is **never** committed to source.

### 5.4 Application session

After Firebase verification, the backend issues an application session.

| Aspect            | Choice                                                                                       |
|-------------------|----------------------------------------------------------------------------------------------|
| Identifier        | Opaque random token (not a JWT, not the Firebase ID token)                                   |
| Lifetime          | Configurable, default 168 hours                                                              |
| Transport         | `HttpOnly` cookie named `akw_session`, `SameSite=Lax`, `Secure` in production                |
| Storage           | **In-memory on the application server**, not in the database                                |
| Revocation scope  | Process lifetime — a restart clears all sessions; OAuth linkage metadata persists separately |
| Refresh           | Re-authenticate via Firebase when the session expires                                        |

The reason the session is kept in memory and not persisted is that this project does not yet have a horizontal scale-out requirement. A future Phase 5+ migration may introduce Redis-backed sessions or short-lived access tokens; that decision is explicitly out of scope for Phase 1.

### 5.5 Provider linkage metadata

The `auth_sessions` table persists **OAuth / provider linkage metadata**, not session state. Each row records that a Firebase identity (provider + provider user id + firebase uid) has been linked to a local user, and when. This metadata survives process restarts and is used for:

- Audit (which Firebase identities have ever been linked to a local user)
- Re-binding (re-issuing an in-memory session for a returning user)

Schema details are documented in `docs/architecture/database.md`.

### 5.6 Frontend integration

Flutter uses `firebase_core` + `firebase_auth` (and `google_sign_in` / `sign_in_with_apple` as needed). Firebase Web configuration is injected at build time via `--dart-define` from the root `.env` file (development) or from GitHub Actions Secrets (production). Native (Android / iOS) Firebase configuration is generated by `flutterfire configure` and is **not** committed.

The backend exposes three authentication endpoints:

```text
POST /api/v1/auth/firebase/session    # exchange Firebase ID token for app session
GET  /api/v1/auth/me                  # return current user from session cookie
POST /api/v1/auth/logout              # clear the in-memory session and the cookie
```

---

## 6. Database

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

## 7. Object Storage

Original uploaded files should be stored in S3-compatible object storage.

Examples:

- AWS S3
- Cloudflare R2
- MinIO for local development

PostgreSQL stores metadata and object references, not large document binaries.

---

## 8. Redis and Workers

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

## 9. AI Runtime

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

## 10. RAG Pipeline

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

## 11. Multi-Project Isolation

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

## 12. Deployment

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

## 13. Observability

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

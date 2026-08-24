---
name: ai-knowledge-workspace-backend
description: AI Knowledge Workspace 后端 FastAPI 实现规范与现有代码结构。
---

# AI Knowledge Workspace — Backend Skill

## When to use
- Working on the FastAPI backend (`backend/`)
- Adding new API routes, models, or services
- Understanding the current Phase 1 skeleton implementation
- Implementing authentication, RBAC, or project management features

## Current Structure (Phase 1 Skeleton)

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app entry point
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py           # Pydantic Settings
│   │   ├── database.py         # Database connection config
│   │   ├── auth.py             # Auth provider abstraction (Firebase)
│   │   └── rbac.py             # Role-based access control
│   └── api/
│       ├── __init__.py
│       └── v1/
│           ├── __init__.py
│           ├── router.py       # API router aggregation
│           └── routes/
│               ├── __init__.py
│               ├── auth.py     # POST /auth/firebase/session
│               └── projects.py # GET/POST /projects
├── Dockerfile
└── requirements.txt
```

## Key Implementation Details

### Configuration (`app/core/config.py`)
- Uses `pydantic-settings` with `.env` file support
- Settings: `app_name`, `api_v1_prefix`, `environment`, `dev`, database connection

### Database (`app/core/database.py`)
- `DatabaseConfig` dataclass with host, port, database, username, password
- `DatabaseConnection.dsn()` returns PostgreSQL connection string
- **Note:** Currently no async SQLAlchemy/asyncpg setup — skeleton only

### Authentication (`app/core/auth.py`)
- Provider abstraction: `BaseAuthProvider` → `FirebaseAuthProvider`
- `AuthUser` dataclass: `user_id`, `provider`, `provider_user_id`, `email`, `display_name`, `firebase_uid`
- `AuthService` wraps provider with `authenticate(token)` method
- **Phase 1:** Placeholder Firebase verification (no real Admin SDK yet)

### RBAC (`app/core/rbac.py`)
- `Role` enum: `OWNER`, `ADMIN`, `MEMBER`, `VIEWER`
- `Membership` dataclass: `user_id`, `project_id`, `role`
- `ProjectPermissionService.can_access(membership, required_role)` — hierarchical check

### API Routes
- **Auth** (`/api/v1/auth`): `POST /firebase/session` — validates Firebase token, returns user info
- **Projects** (`/api/v1/projects`): `GET` (list), `POST` (create) — currently returns mock data

### Main App (`app/main.py`)
- FastAPI with CORS middleware (allow all origins for dev)
- Health check at `/health`
- Includes `api_router` at `/api/v1` prefix

## Development Commands

```bash
# Local dev (no Docker)
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# With Docker Compose (includes PostgreSQL)
docker compose up --build
```

## Requirements.txt
```
fastapi
uvicorn
pydantic-settings
python-dotenv
```

## Environment Variables (`.env`)
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_knowledge_workspace
DB_USER=postgres
DB_PASSWORD=postgres
```

## Next Implementation Priorities (Phase 1+)

1. **Async Database Layer** — SQLAlchemy 2.0 + asyncpg, models for all entities
2. **Real Firebase Auth** — Firebase Admin SDK token verification
3. **Project CRUD** — Full project management with RBAC checks
4. **Document API** — Upload, list, delete, reindex with object storage
5. **Chat API** — Conversation management, streaming responses
6. **AI Runtime Abstractions** — LLMProvider, EmbeddingProvider, Retriever, Reranker
6. **Worker/Queue** — Redis + Celery or similar for async ingestion

## Important Patterns to Follow

- **Project isolation:** Every query must filter by `project_id` from authenticated user's membership
- **Provider abstraction:** Never call OpenAI/Gemini SDK directly in routes — use provider interfaces
- **Dependency injection:** Use FastAPI `Depends` for auth, database, services
- **Pydantic models:** Request/response validation for all endpoints
- **Error handling:** Standardized HTTPException with appropriate status codes
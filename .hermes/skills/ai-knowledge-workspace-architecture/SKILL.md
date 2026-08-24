---
name: ai-knowledge-workspace-architecture
description: AI Knowledge Workspace 项目架构、需求与设计规范全览。
---

# AI Knowledge Workspace — Architecture & Requirements Skill

This skill provides comprehensive context for the AI Knowledge Workspace project — a multi-tenant RAG platform with Project-level isolation, built with Flutter + FastAPI + PostgreSQL + pgvector.

## When to use
- Working on this codebase (backend, frontend, architecture decisions)
- Need to understand project requirements, architecture principles, or design system
- Implementing new features that must align with the established patterns
- Creating ADRs or making architectural decisions

## Project Overview

**AI Knowledge Workspace** is a multi-project, RAG-based AI knowledge platform where:
- Each Project is an independent AI application
- Users ask questions within a Project's knowledge corpus
- Backend enforces Project-level authorization & data isolation
- Frontend is Flutter (Web + Android + iOS) using Material 3
- Backend is FastAPI with PostgreSQL + pgvector

## Key Documentation Files

| File | Purpose |
|------|---------|
| `REQUIREMENTS.md` | Product vision, user roles, functional/non-functional requirements |
| `ARCHITECTURE.md` | High-level architecture, tech stack, data layer, AI runtime, RAG pipeline |
| `ROADMAP.md` | 7-phase development plan (Phase 0-7) |
| `DESIGN_SYSTEM.md` | Visual design tokens, components, responsive rules |
| `UI_GUIDELINES.md` | UI implementation rules, component reuse policy |
| `NAVIGATION.md` | User/Admin navigation, route structure |
| `CODEX_INSTRUCTIONS.md` | Rules for AI coding agents working on this project |
| `docs/phase0/PHASE0_DESIGN_BASELINE.md` | Phase 0 Chinese baseline with data models, API contracts |
| `docs/phase0/ADR_TEMPLATE.md` | Architecture Decision Record template |

## Architecture Principles (from ARCHITECTURE.md)

1. Keep it simple for a two-person team
2. Prefer managed/cloud services for AI inference
3. Keep AI providers replaceable
4. Keep RAG components independently testable
5. Keep Project data isolated at every layer
6. Prefer PostgreSQL + pgvector before another vector DB
7. Use async workers for document ingestion
8. Use AI coding agents but keep architecture decisions human-owned

## High-Level Architecture

```
Web/Mobile Users → Flutter → REST API → FastAPI
                                          ├── Auth/RBAC
                                          ├── Application Services
                                          └── AI Runtime
                                                ├── RAG
                                                ├── Agent
                                                └── Prompt
                                          ↓
                              PostgreSQL + pgvector
                                          ↓
                              Redis/Queue + Object Storage (S3/R2/MinIO)
                                          ↓
                              Worker → Document Ingestion (Parse → Chunk → Embed)
                                          ↓
                              Cloud LLM / Embedding APIs
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Riverpod, GoRouter, Dio, Freezed, json_serializable) |
| Backend | FastAPI |
| Database | PostgreSQL + pgvector |
| Object Storage | S3 / Cloudflare R2 / MinIO |
| Queue/Cache | Redis |
| Auth | Firebase / Auth0 / Clerk / Local (provider abstraction) |
| AI Providers | OpenAI, Gemini, Anthropic (abstracted) |

## Core Data Models (from PHASE0_DESIGN_BASELINE.md)

Key entities with **Project isolation** (every resource has `project_id`):
- `users` - auth_provider, provider_user_id, email, display_name
- `projects` - name, slug, description, status, created_by
- `project_memberships` - project_id, user_id, role (OWNER/ADMIN/MEMBER/VIEWER)
- `documents` - project_id, filename, storage_key, mime_type, status
- `document_chunks` - document_id, project_id, content, embedding, metadata_json
- `conversations` - project_id, user_id, title
- `messages` - conversation_id, project_id, role, content, metadata_json
- `prompts` - project_id, name, system_prompt, version, status
- `evaluation_sets` / `evaluation_cases` - project_id, question, expected_answer

## API Contract (v1)

```
Auth:
  POST /api/v1/auth/firebase/session

Projects:
  GET/POST /api/v1/projects
  GET/PATCH/DELETE /api/v1/projects/{projectId}

Documents:
  POST /api/v1/projects/{projectId}/documents/upload
  GET /api/v1/projects/{projectId}/documents
  GET/DELETE/POST(reindex) /api/v1/projects/{projectId}/documents/{documentId}

Chat:
  GET/POST /api/v1/projects/{projectId}/conversations
  POST /api/v1/projects/{projectId}/chat
  GET /api/v1/projects/{projectId}/conversations/{conversationId}/messages

Prompt:
  GET/POST /api/v1/projects/{projectId}/prompts
  PATCH /api/v1/projects/{projectId}/prompts/{promptId}
  POST /api/v1/projects/{projectId}/prompts/{promptId}/versions

Evaluation:
  GET/POST /api/v1/projects/{projectId}/evaluations
  POST /api/v1/projects/{projectId}/evaluations/run
  GET /api/v1/projects/{projectId}/evaluations/{id}
```

## RAG Pipeline Architecture

```
Question
  ↓
Optional Query Rewrite
  ↓
Project Metadata Filter
  ↓
Dense Vector Search + Full-Text Search
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

Components must be independently testable (Retriever, Reranker, PromptBuilder, LLMProvider, EmbeddingProvider, Tool, Agent, EvaluationRunner).

## Multi-Project Isolation (CRITICAL)

- Every Project-owned resource MUST have `project_id`
- Retrieval MUST apply Project filter before returning chunks
- Frontend CANNOT be trusted for authorization
- Server-side permission checks on ALL projectId requests

## Phase Roadmap Summary

| Phase | Target | Focus |
|-------|--------|-------|
| 0 | 1-2 weeks | Architecture, design baseline, ADR template, repo/CI |
| 1 | 4-6 weeks | Skeleton: Flutter + FastAPI + Auth + RBAC + basic chat |
| 2 | 4-6 weeks | Advanced RAG: parsing, chunking, embedding, hybrid retrieval |
| 3 | 3-5 weeks | Agent/Workflow: tool abstraction, intent routing |
| 4 | 3-4 weeks | Evaluation: datasets, runs, metrics, dashboard |
| 5 | 3-4 weeks | Production hardening: security, observability, CI/CD |
| 6 | 2-3 weeks | Portfolio polish: README, diagrams, demo, write-ups |
| 7 | Long-term | Optional: local models, multimodal, advanced agents |

## Codex/AI Agent Rules (from CODEX_INSTRUCTIONS.md)

- Do not redesign architecture without explicit approval
- Do not add infrastructure without justification
- Prefer existing project abstractions
- Do not duplicate shared components
- Follow the Design System
- Do not hard-code visual tokens in feature widgets
- Keep provider-specific AI code behind provider abstractions
- Maintain Project-level authorization
- Add tests for important logic
- Keep changes focused
- Update documentation when architecture changes

## Navigation Structure

**User:** Login → Project List → Project Chat → Conversation History
**Admin:** Dashboard → Projects → (Project Overview, Documents, Prompt, AI/Retrieval, Tools, Users, Evaluation) → Users → Evaluation → Settings

## Routes

```
/login
/projects
/projects/:projectId/chat
/projects/:projectId/history
/admin
/admin/projects
/admin/projects/:projectId
/admin/projects/:projectId/documents
/admin/projects/:projectId/prompt
/admin/projects/:projectId/ai
/admin/projects/:projectId/tools
/admin/projects/:projectId/users
/admin/projects/:projectId/evaluation
/admin/users
/admin/evaluation
/admin/settings
```

## Screen Specifications

Desktop screens (in `docs/design/desktop/`):
- `login_ui.md` - Screen 1: Login
- `dashboard_ui.md` - Screen 2: Dashboard
- `projectlist_ui.md` - Screen 3: Project List
- `projectoverview_ui.md` - Screen 4: Project Overview
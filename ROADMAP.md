# AI Knowledge Workspace — Development Roadmap

The project intentionally starts at Advanced RAG rather than spending major milestones on basic LLM/API tutorials.

Estimated schedule assumes approximately two people working part-time with heavy use of Codex/AI coding agents. Calendar duration is more important than raw engineering hours.

---

## Phase 0 — Architecture & Design
**Target: 1–2 weeks**

Deliverables:

- Requirements specification
- Architecture specification
- ADR template
- Design System
- Navigation
- Wireframes/mockups
- Database model
- API boundary
- Codex project instructions
- GitHub repository structure
- CI baseline

Exit criteria:

- Two people agree on architecture.
- Core screens are defined.
- Codex has explicit project rules.

---

## Phase 1 — Product Skeleton
**Target: 4–6 weeks**

Scope:

- Flutter Web + Mobile project
- FastAPI backend
- PostgreSQL + pgvector
- Authentication
- RBAC
- Project management
- Basic document management
- Object storage
- Basic chat
- Cloud LLM provider abstraction

Exit criteria:

A user can log in, enter a Project, and have a basic conversation.

---

## Phase 2 — Advanced RAG
**Target: 4–6 weeks**

Scope:

- document parsing
- chunking
- embedding
- vector search
- PostgreSQL full-text search
- hybrid retrieval
- metadata filtering
- reranking
- citations
- asynchronous ingestion
- retrieval debugging UI

Exit criteria:

A Project can answer questions using its document corpus with inspectable citations.

---

## Phase 3 — Agent / Workflow
**Target: 3–5 weeks**

Scope:

- Agent runtime
- tool abstraction
- intent routing
- configurable Project tools
- tool execution trace
- controlled agent loops
- prompt/context orchestration

Initial Agent scope should remain deliberately small.

Exit criteria:

At least one Project can use both RAG and a non-RAG tool in a controlled workflow.

---

## Phase 4 — Evaluation
**Target: 3–4 weeks**

Scope:

- evaluation dataset
- evaluation cases
- automated evaluation runs
- retrieval metrics
- answer quality metrics
- citation checks
- latency tracking
- model/prompt comparison
- evaluation dashboard

Exit criteria:

The team can demonstrate measurable improvement between two RAG/prompt configurations.

---

## Phase 5 — Production Hardening
**Target: 3–4 weeks**

Scope:

- security review
- authorization audit
- retry handling
- rate limiting
- logging
- observability
- backup strategy
- CI/CD
- deployment
- error handling
- document lifecycle robustness

Exit criteria:

A public demo deployment is stable enough for portfolio use.

---

## Phase 6 — Portfolio / Polish
**Target: 2–3 weeks**

Scope:

- README
- architecture diagrams
- demo data
- screenshots
- short demo video
- ADRs
- evaluation report
- technical write-up
- AI-assisted development write-up

Exit criteria:

A recruiter/interviewer can understand the product, architecture, AI techniques, and engineering decisions within a few minutes.

---

## Phase 7 — Long-Term / Optional

Possible additions:

- additional LLM providers
- local model provider
- advanced Agent workflows
- multimodal documents
- OCR
- advanced observability
- team/organization billing
- public API
- more evaluation techniques
- semantic caching

These are explicitly outside the initial project scope.

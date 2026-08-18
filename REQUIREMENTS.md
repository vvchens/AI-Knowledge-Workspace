# AI Knowledge Workspace — Requirements Specification

**Version:** 0.1  
**Status:** Draft / Architecture Baseline  
**Primary goal:** Build a portfolio-quality AI SaaS/RAG platform while learning and demonstrating practical LLM, RAG, Agent, Evaluation, and AI-assisted software engineering.

---

## 1. Product Vision

AI Knowledge Workspace is a multi-tenant knowledge platform in which administrators create independent AI-powered Projects, upload and manage project-specific documents, configure prompts and AI behavior, and provide ordinary users with a simple conversational interface.

The product should feel like a real AI SaaS rather than a generic "chat with PDF" demo.

The key idea is:

> **Simple user experience, sophisticated AI application layer.**

A user asks a normal question. The Project configuration determines how the system retrieves knowledge, constructs the prompt, invokes tools/agents, and generates a grounded answer.

---

## 2. Goals

### 2.1 Primary goals

1. Demonstrate real-world AI application architecture.
2. Demonstrate advanced RAG rather than basic vector search.
3. Demonstrate Agent/workflow concepts.
4. Demonstrate measurable AI evaluation.
5. Demonstrate RBAC, multi-project isolation, and production-style engineering.
6. Demonstrate effective use of AI coding agents such as Codex.
7. Produce a public portfolio project suitable for software/AI engineering job applications.
8. Produce a platform that can later be used as a personal RAG system.

### 2.2 Non-goals

The project will NOT initially:

- Train a foundation model.
- Build a vector database from scratch.
- Build an LLM inference engine.
- Build a general-purpose replacement for Dify/LangChain/LlamaIndex.
- Require a dedicated production GPU.
- Attempt to support every possible document format.
- Implement every possible Agent capability.

---

## 3. User Roles

### 3.1 Administrator

An administrator can:

- Create and manage Projects.
- Upload, delete, and re-index documents.
- Configure Project prompts.
- Manage AI/model settings.
- Configure retrieval behavior.
- Configure tools/workflows.
- Manage Project users.
- Run evaluations.
- Review evaluation results.
- View operational/project metrics.

### 3.2 Normal User

A normal user can:

- View Projects to which they have access.
- Ask questions within a Project.
- View conversation history.
- View source citations.
- Continue conversations.
- Provide basic answer feedback.

A normal user must NOT be able to modify Project configuration or access documents from Projects to which they do not belong.

---

## 4. Core Concepts

### Project

A Project is an isolated AI application.

A Project contains:

- Users/members
- Documents
- Knowledge chunks
- System prompt
- Prompt versions
- Model configuration
- Retrieval configuration
- Optional tools/workflows
- Evaluation datasets
- Conversations

### Document

An uploaded source file belonging to a Project.

Initial target formats:

- PDF
- Markdown
- TXT
- DOCX

Additional formats may be added later.

### Chunk

A searchable section extracted from a Document.

Each chunk should retain useful metadata such as:

- document ID
- page/section when available
- source filename
- chunk position
- language
- document type

### Conversation

A user conversation associated with a Project.

### Evaluation Case

A question with expected behavior/results used to measure RAG/LLM quality.

---

## 5. Functional Requirements

### FR-001 Authentication

The system shall support user authentication.

### FR-002 RBAC

The system shall enforce role- and Project-based authorization.

### FR-003 Project management

Administrators shall be able to create, edit, archive, and configure Projects.

### FR-004 Document ingestion

Administrators shall be able to upload multiple documents.

The ingestion pipeline shall:

1. Store the original document.
2. Parse the document.
3. Extract text.
4. Split text into chunks.
5. Generate embeddings.
6. Store chunks and metadata.
7. Mark indexing status.

### FR-005 Document lifecycle

Documents shall have observable states such as:

- Uploading
- Processing
- Indexed
- Failed
- Re-indexing

### FR-006 RAG retrieval

The system shall support:

- metadata filtering
- dense vector retrieval
- keyword/full-text retrieval
- hybrid retrieval
- configurable top-K
- optional reranking

### FR-007 Prompt management

Administrators shall be able to:

- define a Project system prompt
- create prompt versions
- activate a prompt version
- compare prompt versions
- test prompts

### FR-008 Chat

Users shall be able to ask questions in a Project.

The answer should support streaming output where practical.

### FR-009 Citations

Answers generated from Project knowledge should expose source citations.

A citation should identify the originating document and useful location information when available.

### FR-010 Agent/workflow

Projects may define optional tools/workflows.

The Agent layer may:

- classify intent
- decide whether retrieval is required
- call configured tools
- combine tool/RAG results
- produce a final answer

Agent behavior must remain observable and testable.

### FR-011 Evaluation

Administrators shall be able to:

- create evaluation datasets
- create evaluation cases
- execute evaluation runs
- inspect individual results
- compare evaluation runs

Target metrics include:

- answer correctness
- retrieval quality
- citation correctness
- groundedness/hallucination indicators
- latency
- token/cost usage where available

### FR-012 Conversation history

Users shall be able to view previous conversations within Projects they can access.

### FR-013 Feedback

Users may provide basic feedback on generated answers.

---

## 6. Initial Screen Set

### User

1. Login
2. Project List
3. Chat
4. Conversation History

### Administrator

5. Dashboard
6. Project List
7. Project Overview
8. Documents
9. Prompt
10. AI / Retrieval
11. Evaluation
12. Users

The first release should prioritize these screens rather than adding broad feature scope.

---

## 7. RAG Requirements

The target RAG architecture is:

```text
Question
   ↓
Optional Query Rewrite
   ↓
Metadata Filtering
   ↓
Dense Vector Search
   +
Full-Text Search
   ↓
Hybrid Rank Fusion
   ↓
Reranker
   ↓
Context Selection
   ↓
Prompt Construction
   ↓
LLM
   ↓
Answer + Citations
```

The implementation should keep retrieval components independently testable.

---

## 8. Agent Requirements

The Agent system should be implemented as an application/runtime layer rather than tightly coupling business logic to one model provider.

The design should allow:

- multiple LLM providers
- multiple tools
- explicit tool schemas
- controlled tool execution
- execution traces
- configurable Project behavior

The initial Agent should remain intentionally small and deterministic.

---

## 9. AI Provider Requirements

LLM access shall be abstracted behind a provider interface.

Conceptually:

```text
LLMProvider
 ├── OpenAIProvider
 ├── GeminiProvider
 ├── AnthropicProvider
 └── LocalProvider (future)
```

Embedding should similarly be abstracted.

A Project should record the embedding model used for its index. Changing embedding models should trigger a re-indexing strategy.

---

## 10. Non-Functional Requirements

### Security

- Project-level data isolation.
- Server-side authorization checks.
- No trust in client-side role checks.
- Secrets must not be stored in source code.
- Uploaded documents must not be directly exposed without authorization.
- Audit important administrative actions.

### Performance

Initial target:

- Typical chat request should begin responding within a few seconds under normal conditions.
- Retrieval should normally complete within the latency budget defined by the evaluation environment.
- Document indexing must be asynchronous.

### Reliability

- Background ingestion must survive transient failures.
- Failed jobs must be retryable.
- Important failures must be observable.

### Maintainability

- Feature-oriented Flutter structure.
- Clear API boundaries.
- Repository/service abstractions where useful.
- Shared UI components.
- Automated tests.
- CI checks.

---

## 11. Portfolio Requirements

The repository should demonstrate:

- Architecture documentation
- ADRs
- RAG architecture
- Agent architecture
- Evaluation methodology
- Test strategy
- CI/CD
- AI-assisted development workflow
- Security considerations
- Performance/quality measurements

The project should favor demonstrable engineering decisions over raw code volume.

---

## 12. Definition of Done

A feature is considered complete only when:

1. Requirements are documented.
2. Architecture is understood.
3. Implementation is complete.
4. Automated tests exist where appropriate.
5. UI works on target form factors.
6. Authorization is verified.
7. Relevant logs/observability exist.
8. Documentation is updated.
9. Codex/AI-generated code has been human-reviewed.
10. CI passes.

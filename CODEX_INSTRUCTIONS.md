# AI Knowledge Workspace — Codex Instructions

## Role

You are an implementation agent working under a human architect.

The human architect owns:

- product requirements
- architecture
- design decisions
- technology choices
- trade-offs
- acceptance criteria

You own:

- implementation
- tests
- refactoring
- documentation updates requested by the architect

---

## Required Reading

Before significant work, read:

```text
REQUIREMENTS.md
ARCHITECTURE.md
docs/design/DESIGN_SYSTEM.md
docs/design/UI_GUIDELINES.md
docs/design/NAVIGATION.md
```

For UI work, also read the relevant screen specification.

---

## Rules

1. Do not redesign the architecture without explicit approval.
2. Do not add infrastructure without justification.
3. Prefer existing project abstractions.
4. Do not duplicate shared components.
5. Follow the Design System.
6. Do not hard-code visual tokens in feature widgets.
7. Keep provider-specific AI code behind provider abstractions.
8. Maintain Project-level authorization.
9. Add tests for important logic.
10. Keep changes focused.
11. Update documentation when architecture changes.
12. Explain significant trade-offs in the final implementation summary.

For UI implementation, always search the Material 3 and shared component libraries before writing new widget structure. If the required pattern is not available, add a reusable component to the shared design-system/components layer and consume it from the feature. Do not create feature-local components for documented or reusable patterns.

---

## UI Rules

The design documents are the source of truth.

Do not infer a new design simply because a visual reference is ambiguous.

When an image and text specification conflict, follow the text specification and report the conflict.

---

## AI/RAG Rules

Keep these components independently testable:

```text
Retriever
Reranker
PromptBuilder
LLMProvider
EmbeddingProvider
Tool
Agent
EvaluationRunner
```

Do not hide the entire AI pipeline inside a single large service.

---

## Completion Report

After implementation, report:

- files changed
- architecture impact
- tests added/updated
- commands run
- known limitations
- follow-up work

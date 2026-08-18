# AI Knowledge Workspace — UI Implementation Guidelines

## 1. Source of Truth

UI implementation must follow this order:

1. `DESIGN_SYSTEM.md`
2. Target screen specification
3. `NAVIGATION.md`
4. Visual reference image
5. Existing Flutter components

The image is a visual reference. The Markdown specifications define behavior and constraints.

---

## 2. Before Implementing a Screen

The coding agent must:

1. Read the target screen specification.
2. Inspect existing shared components.
3. Reuse existing theme/design tokens.
4. Check desktop and mobile requirements.
5. Identify loading, empty, error, and success states.
6. Implement tests where appropriate.

---

## 3. Do Not Invent Visual Patterns

Do not independently introduce:

- new colors
- new typography scales
- arbitrary border radii
- arbitrary spacing systems
- unrelated navigation patterns
- duplicate components

If a new pattern is necessary, update the design system first.

---

## 4. Responsive Implementation

The application is not "desktop shrunk to mobile."

Every important screen must define:

- desktop layout
- tablet behavior
- mobile layout

Responsive layout may change structure when necessary.

---

## 5. UI States

Every data-driven screen should consider:

```text
Loading
Empty
Loaded
Error
Refreshing
Permission denied
```

Document processing screens should additionally support:

```text
Uploading
Processing
Indexed
Failed
Re-indexing
```

---

## 6. Accessibility

Use:

- semantic labels
- sufficient contrast
- keyboard navigation where applicable
- accessible touch targets
- meaningful tooltips for icon-only actions

---

## 7. Visual QA

For important screens:

```text
Design Reference
       ↓
Flutter Implementation
       ↓
Screenshot
       ↓
Visual Review
       ↓
Fix
```

The QA role should maintain a short visual regression checklist.

---

## 8. AI Coding Rule

Codex is an implementation agent, not the design authority.

When implementation conflicts with the documented design:

- preserve the documented design
- ask for clarification if requirements conflict
- do not silently redesign the product

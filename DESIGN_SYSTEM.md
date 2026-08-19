# AI Knowledge Workspace — Design System

**Foundation:** Flutter Material 3  
**Visual direction:** Modern AI SaaS  
**References:** Linear, Vercel, ChatGPT  
**Rule:** These products are visual references only; do not directly copy their branding or layouts.

---

## 1. Design Principles

- Professional
- Minimal
- Clean
- Low visual noise
- Strong hierarchy
- High information density on desktop
- Comfortable touch interaction on mobile
- Consistent visual language
- Accessibility-aware
- Reuse components instead of creating one-off UI

The application should look like a modern AI product, not a generic Bootstrap administration panel.

---

## 2. Material 3

Use Flutter Material 3 as the foundational component system.

Prefer existing Material 3 components:

- AppBar
- NavigationRail
- NavigationBar
- NavigationDrawer
- FilledButton
- OutlinedButton
- TextButton
- IconButton
- TextField
- SearchBar
- Dropdown/menus
- Dialog
- Card
- Chip
- Tabs
- SegmentedButton
- Progress indicators
- Data presentation components

Create custom components only when the product requires behavior or presentation that Material 3 cannot provide cleanly.

### Component Reuse Policy

All feature UI must use an existing Material 3 component, shared component, or design token whenever one provides the required behavior and presentation.

When no suitable component exists:

1. Confirm that the pattern is required by the product and cannot be composed from existing components.
2. Create the new component in the shared design-system/components layer.
3. Make the component configurable through semantic properties rather than feature-specific styling.
4. Document the component's intended use when its behavior is not self-evident.
5. Use the new shared component from the feature instead of implementing a local duplicate.

Feature folders must not contain one-off replacements for shared components. A component should be promoted to the shared layer when it is reused, represents a documented design pattern, or centralizes a visual or interaction rule that must remain consistent.

---

## 3. Theme

All visual values must be centralized.

Recommended architecture:

```text
AppTheme
 ├── ColorScheme
 ├── TextTheme
 ├── AppSpacing
 ├── AppRadius
 ├── AppElevation
 └── Component Themes
```

Feature widgets should not hard-code design values.

---

## 4. Color

Use Material 3 ColorScheme.

The initial visual direction is a restrained purple/indigo primary accent with neutral surfaces.

Example baseline:

```text
Primary:              #6750A4
Primary Container:    #EADDFF
Surface:              #FFFBFE
Surface Container:    #F3EDF7
Outline:              #79747E
Error:                #B3261E
```

These values are a starting point, not a permanent branding decision.

Semantic states:

- Success — green family
- Warning — amber/orange family
- Error — red family
- Info — blue family

Do not hard-code colors in feature widgets.

---

## 5. Typography

Use Flutter Material 3 TextTheme.

Target scale:

```text
Display:      32 / 40
Headline:     24 / 32
Title:        20 / 28
Body:         14 / 20
Label:        12 / 16
```

Typography should prioritize readability over decorative styling.

---

## 6. Spacing

Use this spacing scale:

```text
4
8
12
16
24
32
48
64
```

Prefer named design tokens such as:

```text
AppSpacing.xs
AppSpacing.sm
AppSpacing.md
AppSpacing.lg
AppSpacing.xl
```

Do not introduce arbitrary values unless justified.

---

## 7. Radius

```text
Small:    4
Medium:   8
Large:    12
XLarge:   16
```

Defaults:

- Card: 12
- Input: 8
- Button: 8
- Dialog: 12–16

---

## 8. Elevation

Prefer borders and surface contrast over heavy shadows.

Default cards should use:

- low/no elevation
- subtle outline when appropriate
- Material surface containers

---

## 9. Navigation

### Desktop

Use a left navigation area approximately 240px wide.

Typical Admin navigation:

```text
Dashboard
Projects
Documents
Evaluation
Users
Settings
```

Project-level navigation:

```text
Overview
Documents
Prompt
AI / Retrieval
Tools
Users
Evaluation
```

### Mobile

Do not force the desktop sidebar onto a phone.

Use:

- AppBar
- Drawer when necessary
- NavigationBar for primary user navigation

---

## 10. Cards

Cards should be used for:

- project summaries
- metrics
- document summaries
- configuration groups
- evaluation summaries

Avoid excessive card nesting.

---

## 11. Tables

Desktop:

- use tables for dense administrative data
- support sorting/filtering where useful

Mobile:

- convert tables into cards/list rows when the table cannot remain readable.

---

## 12. Chat

Chat is the primary User experience.

Requirements:

- clear distinction between user and AI messages
- streaming response support
- readable long-form AI answers
- source citations
- loading/processing state
- error state
- feedback controls

Citation presentation should be subtle but easy to inspect.

---

## 13. Status

Standard status patterns:

```text
Ready
Processing
Failed
Archived
Active
Disabled
```

Use chips/badges and semantic colors consistently.

---

## 14. Responsive Rules

### Desktop

- Sidebar visible
- Content max width around 1200px where appropriate
- Larger horizontal padding
- Dense tables permitted

### Tablet

- Sidebar may collapse
- Two-column layouts where appropriate

### Mobile

- NavigationBar/AppBar
- 16px page padding
- Single-column layouts
- Minimum comfortable touch targets
- Tables converted to cards where necessary

---

## 15. Component Naming

Shared UI components should live in a common design-system/shared layer.

Examples:

```text
AppButton
AppCard
AppTextField
AppDialog
AppDataTable
AppStatusChip
AppEmptyState
AppLoadingState
AppErrorState
AppCitation
```

Do not duplicate these components inside individual features.

---

## 16. Visual Reference

The design-system board is a visual reference only.

Codex must use this document and the screen specifications as the source of truth for implementation rules.

Reference:

`docs/design/references/design-system-board.png`

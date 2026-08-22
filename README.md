# AI Knowledge Workspace — Project Documents

This package contains the initial product/architecture/design baseline.

Recommended starting order:

1. REQUIREMENTS.md
2. ARCHITECTURE.md
3. ROADMAP.md
4. docs/design/DESIGN_SYSTEM.md
5. docs/design/UI_GUIDELINES.md
6. docs/design/NAVIGATION.md
7. CODEX_INSTRUCTIONS.md

The image under `docs/design/references/` is a visual reference only; the Markdown design documents are the implementation source of truth.

## Development Environment

Set `DEV=1` to enable development mode across the local services. The backend receives the variable through Docker Compose, and Flutter pre-fills the login form with `dev@dev.com` and `dev` when the same flag is passed at build time:

```bash
DEV=1 docker compose up --build
cd frontend
flutter run --dart-define=DEV=1
```

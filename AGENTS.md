# Project Agent Instructions

## Architecture

Read the relevant documents under `docs/architecture/`
before making architectural changes.

For product and UI changes, also read the design guidance under `docs/design/`, especially:

- `docs/design/DESIGN_SYSTEM.md`
- `docs/design/UI_GUIDELINES.md`
- `docs/design/NAVIGATION.md`

## Database

For any database schema change:

- Use SQLAlchemy models.
- Use Alembic migrations.
- Never modify production schema manually.
- Never rewrite an applied migration.
- Run `alembic upgrade head` during deployment.

Detailed database rules:

- `docs/architecture/database.md`

## Deployment

Follow:

- `docs/architecture/deployment.md`
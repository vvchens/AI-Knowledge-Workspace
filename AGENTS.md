# Project Agent Instructions

## Architecture

Read the relevant documents under `docs/architecture/`
before making architectural changes.

For product and UI changes, also read the design guidance under `docs/design/`, especially:

- `docs/design/DESIGN_SYSTEM.md`
- `docs/design/UI_GUIDELINES.md`
- `docs/design/NAVIGATION.md`

## Security / Secrets

This repository is public and must not contain any sensitive configuration, credentials, or secrets in source control.

Never commit:

- Firebase API keys or config values
- database credentials
- API tokens or private keys
- production/staging secrets
- environment files with real values

Use environment variables, CI secret injection, or a secret manager instead.

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
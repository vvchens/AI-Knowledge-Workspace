# Database Architecture & Migration Deployment Guidelines

## 1. Purpose

This document defines the mandatory database architecture, schema migration, initialization, and deployment rules for this project.

The project uses:

* Backend: FastAPI
* ORM: SQLAlchemy
* Database: PostgreSQL
* Migration tool: Alembic
* Containerization: Docker
* CI/CD: GitHub Actions
* Container Registry: GHCR
* Production deployment: Oracle Cloud VPS

The database schema must be treated as **version-controlled application code**.

Copilot / coding agents MUST follow the rules in this document whenever they modify database models, database schema, initialization logic, or deployment configuration.

---

# 2. Core Principle

## Database schema is code

Database schema changes MUST NOT be performed manually on production databases.

Do NOT:

* SSH into production and manually run `ALTER TABLE`
* Manually create production tables
* Modify production schema directly
* Depend on manually maintained SQL files
* Use Docker's `init.sql` mechanism as the production schema migration system

All schema changes MUST be represented by Alembic migrations and committed to Git.

The production database is updated by running:

```bash
alembic upgrade head
```

---

# 3. Project Structure

The backend should follow this general structure:

```text
backend/
├── app/
│   ├── api/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   └── main.py
│
├── migrations/
│   ├── versions/
│   │   ├── 001_initial_schema.py
│   │   ├── 002_add_projects.py
│   │   ├── 003_add_documents.py
│   │   └── ...
│   │
│   └── env.py
│
├── scripts/
│   └── seed.py
│
├── alembic.ini
├── Dockerfile
└── requirements.txt
```

The exact directory structure may evolve, but the separation between application code, migrations, and seed data MUST remain.

---

# 4. Database Technology

Use:

```text
PostgreSQL
SQLAlchemy
Alembic
```

Do not introduce another ORM or migration framework without explicit approval.

Database access should use SQLAlchemy rather than scattered raw SQL.

Raw SQL is allowed when necessary for:

* PostgreSQL-specific features
* Performance-critical queries
* Complex migrations
* Extensions
* Full-text search
* Vector/RAG functionality

When raw SQL is used, it should still be version-controlled and reproducible.

---

# 5. Alembic Migration Rules

Every database schema change MUST have an Alembic migration.

Examples:

* Add table
* Remove table
* Add column
* Remove column
* Rename column
* Change column type
* Add index
* Remove index
* Add foreign key
* Remove foreign key
* Add unique constraint
* Change database constraints
* Add PostgreSQL extension

Example:

```bash
alembic revision --autogenerate -m "add embedding model"
```

The generated migration MUST be reviewed before committing.

Do not blindly trust Alembic autogeneration.

Verify:

* Table creation
* Column types
* Nullable settings
* Default values
* Foreign keys
* Indexes
* Unique constraints
* Data migration requirements
* Potential destructive operations

---

# 6. Migration Naming

Migration messages should describe the actual schema change.

Good:

```text
001_initial_schema
002_add_projects
003_add_documents
004_add_embedding_model
005_add_document_status
```

Avoid vague names such as:

```text
update_database
fix_db
changes
test
misc
```

The migration history should be understandable by reading the filenames.

---

# 7. Initial Database Setup

A completely new database MUST be initialized through Alembic.

Example:

```bash
alembic upgrade head
```

This should create the complete current schema.

A new developer or deployment environment should NOT need to manually execute a sequence of SQL files.

The expected process is:

```text
Empty PostgreSQL database
        ↓
alembic upgrade head
        ↓
Current schema
```

Alembic maintains its migration version using:

```text
alembic_version
```

---

# 8. Never Use Docker init.sql as the Migration System

Do NOT use:

```text
/docker-entrypoint-initdb.d/
```

as the long-term production database schema management mechanism.

Docker initialization scripts only run when PostgreSQL initializes a new database volume.

They do not naturally handle future schema changes.

Instead use:

```text
Alembic migrations
```

Docker is responsible for running PostgreSQL.

Alembic is responsible for evolving the schema.

---

# 9. Seed Data

Schema migrations and application seed data MUST be treated separately.

Schema:

```text
migrations/
```

Seed data:

```text
scripts/
    seed.py
```

Examples of seed data:

* Default administrator account
* Default roles
* Default project
* Default prompt
* Default configuration records

Do NOT put normal application seed data into an initial schema migration unless there is a specific reason.

Seed operations should be designed to be idempotent whenever possible.

Running:

```bash
python scripts/seed.py
```

multiple times should not create duplicate default records.

---

# 10. Development Workflow

When changing the database schema:

## Step 1 — Modify SQLAlchemy models

Example:

```python
class Document(Base):
    ...
    embedding_model = Column(String)
```

## Step 2 — Generate migration

```bash
alembic revision --autogenerate -m "add embedding model"
```

## Step 3 — Review migration

The agent MUST inspect the generated migration.

## Step 4 — Test migration locally

```bash
alembic upgrade head
```

## Step 5 — Test application

Run the backend and verify affected functionality.

## Step 6 — Commit migration

The migration file MUST be committed together with the model/application changes.

Never commit application code that requires a schema change without committing the corresponding migration.

---

# 11. Production Deployment

Production deployment MUST automatically apply database migrations.

The deployment flow should be:

```text
GitHub
   ↓
GitHub Actions
   ↓
Build Docker image
   ↓
Push image to GHCR
   ↓
Production VPS pulls image
   ↓
Database backup
   ↓
alembic upgrade head
   ↓
Start/restart application
```

The migration command should be explicitly executed during deployment.

Example:

```bash
docker compose pull

docker compose run --rm backend alembic upgrade head

docker compose up -d
```

The exact Docker Compose commands may differ, but the logical order MUST remain.

---

# 12. Do Not Automatically Run Migrations During FastAPI Startup

Do NOT put:

```python
alembic upgrade head
```

inside:

```text
FastAPI startup
```

or:

```text
application startup event
```

The application container should not be responsible for modifying database schema automatically.

Reasons:

* Multiple application replicas could race
* Application startup becomes dependent on database migration state
* Migration failures become harder to diagnose
* Application restarts could unexpectedly modify the database
* Deployment and schema changes become difficult to control

Migration should be a separate deployment step.

---

# 13. Production Database Backup

Before applying production schema migrations, the deployment process SHOULD create a database backup.

Conceptually:

```text
Production deployment
        ↓
Database backup
        ↓
Run migration
        ↓
Deploy application
```

For PostgreSQL, a logical backup may use:

```bash
pg_dump
```

The exact backup strategy may later be replaced by:

* Automated PostgreSQL backups
* WAL archiving
* Managed database backups
* Snapshot-based backups

But production schema changes should never be performed without an appropriate recovery strategy.

---

# 14. Migration Safety

Agents MUST consider whether a migration is destructive.

Potentially destructive operations include:

```text
DROP TABLE
DROP COLUMN
TRUNCATE
DELETE
Changing a nullable column to NOT NULL
Changing column types
Removing indexes
Removing constraints
```

Before performing destructive operations, verify:

1. Whether existing production data depends on the object
2. Whether application code still references it
3. Whether a backup exists
4. Whether a multi-step migration is safer

Do not automatically generate destructive migrations merely because SQLAlchemy models changed.

---

# 15. Expand → Migrate → Contract

For production schema changes, prefer:

```text
Expand
   ↓
Migrate
   ↓
Contract
```

Example:

Current schema:

```text
documents
└── content
```

Desired schema:

```text
documents
└── text
```

Do NOT immediately:

```text
DROP content
ADD text
```

Instead:

### Phase 1 — Expand

Add:

```text
text
```

while keeping:

```text
content
```

### Phase 2 — Migrate

Copy existing data:

```text
content → text
```

Update application code to use `text`.

### Phase 3 — Contract

After confirming that `content` is no longer required:

```text
DROP content
```

This approach minimizes downtime and makes deployments safer.

---

# 16. Backward Compatibility

When deploying a new application version together with a database migration, consider that the old application version may temporarily coexist with the new version.

Therefore migrations should preferably be backward compatible.

Avoid migrations that immediately remove data or columns still required by the currently running application.

Prefer:

```text
Old application
       ↓
Compatible database
       ↓
New application
       ↓
Cleanup migration
```

rather than:

```text
Destructive migration
       ↓
Old application breaks
```

---

# 17. Database Environment Separation

The project should support separate databases for different environments.

At minimum:

```text
Development
Production
```

Preferably:

```text
Development
Staging
Production
```

Each environment has its own PostgreSQL database.

The same Alembic migration history is used in every environment.

Example:

```text
Migration history:

001
002
003
004
```

Development:

```text
001 → 002 → 003 → 004
```

Production:

```text
001 → 002 → 003
```

When deploying:

```bash
alembic upgrade head
```

Production becomes:

```text
001 → 002 → 003 → 004
```

Do not create environment-specific schema versions unless absolutely necessary.

---

# 18. Configuration and Secrets

Database connection strings MUST NOT be hardcoded in source code.

Use environment variables.

Example:

```text
DATABASE_URL
```

Development may use:

```text
DATABASE_URL=postgresql://...
```

Production should inject the value through:

* Docker environment
* Deployment secrets
* VPS environment configuration
* GitHub Actions secrets where appropriate

Never commit:

```text
DATABASE_URL
passwords
API keys
production credentials
```

to Git.

---

# 19. Docker Architecture

The backend Docker image should contain:

```text
Application code
Alembic configuration
Migration files
Dependencies
```

Example:

```text
backend image
├── app/
├── migrations/
├── alembic.ini
└── Python dependencies
```

This allows the exact same image to perform both:

```bash
alembic upgrade head
```

and:

```bash
uvicorn ...
```

This is important because the migration and application use the same version of the codebase.

---

# 20. CI/CD Responsibility

GitHub Actions is responsible for:

1. Running tests
2. Building Docker images
3. Publishing Docker images to GHCR
4. Deploying the image
5. Running database migrations
6. Starting the new application version

A production deployment should not require manual SSH commands under normal circumstances.

Manual intervention should only be required for exceptional recovery or infrastructure maintenance.

---

# 21. Migration Testing

CI SHOULD verify that migrations work.

At minimum:

```text
Empty PostgreSQL
       ↓
alembic upgrade head
       ↓
Application tests
```

For more advanced CI:

```text
Latest production-like schema
       ↓
Apply new migration
       ↓
Run tests
```

Migration failures should cause the deployment to fail rather than silently continuing.

---

# 22. Migration Failure Policy

If:

```bash
alembic upgrade head
```

fails:

```text
DO NOT continue normal application deployment.
```

The deployment should stop.

Expected flow:

```text
Migration
   │
   ├── Success → Deploy application
   │
   └── Failure → Stop deployment
```

Do not hide migration errors.

Do not ignore migration exit codes.

Do not force the application to start against an incompatible schema.

---

# 23. ORM Model and Migration Consistency

SQLAlchemy models and the database schema must remain synchronized.

When modifying a model that changes database structure:

```text
SQLAlchemy model
       +
Alembic migration
```

should normally be changed in the same commit.

Example:

```text
models/document.py
migrations/versions/005_add_status.py
```

Do not modify only the model and expect production to magically update.

SQLAlchemy model changes do NOT automatically modify the production database.

---

# 24. RAG-Specific Database Considerations

This project may contain RAG-related data such as:

```text
documents
document_chunks
embeddings
projects
prompts
```

Potential future schema:

```text
users
roles
projects
documents
document_chunks
embeddings
prompts
```

RAG-related migrations must follow the same Alembic rules.

If PostgreSQL vector functionality is introduced, such as `pgvector`, the extension and related schema changes must also be represented in migrations.

Example conceptual migration:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Do not manually enable required PostgreSQL extensions on production without documenting and versioning the change.

---

# 25. Do Not Mix Schema Migration With Business Data Migration Without Reason

Schema migration:

```text
Add column
Add table
Add index
Change constraint
```

Business data migration:

```text
Recalculate embeddings
Move documents between projects
Rebuild application data
Transform user-owned records
```

These are different concerns.

If a data migration is required, explicitly identify it as such and consider:

* Runtime cost
* Transaction size
* Locking
* Failure recovery
* Whether it should run asynchronously
* Whether it belongs in an Alembic migration or an application-level job

Do not put a potentially huge RAG re-embedding operation inside a normal deployment migration.

---

# 26. Migration Transactions

Prefer transactional migrations whenever PostgreSQL supports the required operation safely.

Avoid long-running transactions that lock large tables unnecessarily.

For large production data migrations, consider:

```text
Schema migration
        ↓
Background data migration
        ↓
Validation
        ↓
Cleanup migration
```

rather than performing everything inside one deployment transaction.

---

# 27. Agent Behavior Rules

When asked to modify database-related functionality, Copilot MUST first determine whether the change affects:

```text
Database schema
Database data
Database indexes
Database constraints
Database extensions
Database deployment
```

If the change affects schema:

1. Modify SQLAlchemy model if appropriate
2. Generate an Alembic migration
3. Review the migration
4. Test it locally
5. Include migration in the same change
6. Ensure deployment runs `alembic upgrade head`

The agent MUST NOT:

* Modify production database directly
* Ask the user to manually execute schema SQL as the normal workflow
* Delete existing migration history
* Rewrite old migrations that have already been deployed
* Automatically introduce a second migration framework
* Put schema migration into FastAPI startup
* Use Docker `init.sql` as the production migration mechanism

---

# 28. Never Rewrite Existing Production Migrations

Once an Alembic migration has been deployed to production:

```text
DO NOT MODIFY IT.
```

If the migration was:

```text
003_add_documents.py
```

and it has already been applied in production, do not edit it.

Create:

```text
004_fix_documents.py
```

instead.

This preserves a consistent migration history across environments.

---

# 29. Development Database Reset

For local development, it is acceptable to destroy and recreate the database.

Example:

```text
Drop development database
        ↓
Create empty database
        ↓
alembic upgrade head
        ↓
seed.py
```

This is NOT acceptable for production.

Never provide destructive database reset commands as part of normal production deployment.

---

# 30. Desired End State

The complete deployment architecture should look like:

```text
                 GitHub Repository
                        │
                        │
                GitHub Actions
                        │
             ┌──────────┴──────────┐
             │                     │
          Tests                Docker Build
                                   │
                                   ↓
                                  GHCR
                                   │
                                   ↓
                          Production VPS
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ↓                             ↓
             Database Backup              Pull Docker Image
                                                  │
                                                  ↓
                                       alembic upgrade head
                                                  │
                                                  ↓
                                         docker compose up
                                                  │
                                                  ↓
                                           FastAPI API
                                                  │
                                                  ↓
                                        PostgreSQL VPS
```

The database itself remains independent from the application server.

```text
Oracle DB VPS
└── PostgreSQL

Oracle Application VPS
├── FastAPI
├── Flutter Web
└── Docker Compose
```

---

# 31. Golden Rules

The following rules are mandatory:

1. **Database schema is code.**
2. **Every schema change requires an Alembic migration.**
3. **All migrations are committed to Git.**
4. **Never manually modify the production schema during normal operation.**
5. **Never rewrite a migration that has already reached production.**
6. **Run migrations as a separate deployment step.**
7. **Do not run migrations automatically inside FastAPI startup.**
8. **Run `alembic upgrade head` during production deployment.**
9. **Back up production data before risky schema changes.**
10. **Use Expand → Migrate → Contract for potentially breaking changes.**
11. **Keep seed data separate from schema migrations.**
12. **Never commit production database credentials.**
13. **The same migration history must work across development and production.**
14. **Migration failure must stop deployment.**
15. **The Docker image must contain the migration code required for that application version.**
16. **Do not use Docker `init.sql` as the long-term production migration mechanism.**
17. **Do not perform large business-data operations synchronously as part of ordinary schema migrations.**
18. **When in doubt, favor reversible, backward-compatible database changes.**

---

# 32. Agent Decision Rule

Whenever a task involves a database change, the agent should reason in this order:

```text
Does this change modify the database schema?
        │
        ├── No
        │    └── Normal application code change
        │
        └── Yes
             ↓
        Modify SQLAlchemy model
             ↓
        Generate Alembic migration
             ↓
        Review migration
             ↓
        Test migration locally
             ↓
        Commit model + migration together
             ↓
        CI validates migration
             ↓
        Production backup
             ↓
        alembic upgrade head
             ↓
        Deploy application
```

The agent should treat this workflow as the default database development and deployment process for the project.

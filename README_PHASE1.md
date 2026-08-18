# Phase 1 Skeleton

This repository now includes a minimal Phase 1 baseline for the AI Knowledge Workspace.

## Structure

- backend/: FastAPI app skeleton
- frontend/: Flutter app shell
- docker-compose.yml: local backend + PostgreSQL dev environment

## Run backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Run frontend

```bash
cd frontend
flutter pub get
flutter run
```

## Local dev stack

```bash
docker compose up --build
```

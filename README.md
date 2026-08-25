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

## Local Development

Local development runs directly on host machine (no Docker):

```bash
# backend
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# frontend (new terminal)
cd frontend
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=DEV=1
```

The `DEV=1` flag keeps the development defaults enabled in app behavior (for example, pre-filled login in Flutter).

The Flutter VS Code launch configuration reads Firebase Web values from the root `.env` file using `--dart-define-from-file`. Keep this file local and do not commit it.

## Production Deployment (Docker + SWAG)

Docker Compose is reserved for production-like deployment with DuckDNS + Let's Encrypt SSL:

```bash
docker compose up -d --build
```

Before first run, fill DuckDNS and SSL fields in `.env`:

- `DUCKDNS_SUBDOMAINS`
- `DUCKDNS_TOKEN`
- `LETSENCRYPT_EMAIL`

Recommendation: keep `LE_STAGING=true` on first issue test, then switch to `false` for real certificates.

The frontend GitHub Actions workflow injects Firebase Web configuration from GitHub Actions Secrets instead of reading a repository `.env` file. Configure `FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MESSAGING_SENDER_ID`, and `FIREBASE_APP_ID`; `FIREBASE_MEASUREMENT_ID` is optional.

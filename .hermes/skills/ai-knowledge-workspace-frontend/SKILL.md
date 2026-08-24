---
name: ai-knowledge-workspace-frontend
description: AI Knowledge Workspace 前端 Flutter 实现规范与现有代码结构。
---

# AI Knowledge Workspace — Frontend Skill

## When to use
- Working on the Flutter frontend (`frontend/`)
- Implementing new screens or UI components
- Understanding the design system, theme, and component patterns
- Adding navigation, state management, or API integration

## Current Structure (Phase 1 Skeleton)

```
frontend/
├── lib/
│   ├── main.dart                 # App entry, GoRouter, Theme
│   ├── theme/
│   │   ├── app_tokens.dart       # Spacing, Radius, Colors constants
│   │   └── app_theme.dart        # Material 3 ThemeData configuration
│   ├── components/
│   │   └── app_components.dart   # Shared UI components (AppCard, AppButton, AppStatusChip)
│   └── screens/
│       ├── login_screen.dart     # Screen 1: Login with form validation
│       └── projects_screen.dart  # Screen 3: Project List (responsive)
├── assets/
│   └── icons/                    # SVG icons (brain-circuit, mail, lock, eye)
├── Dockerfile
├── Dockerfile.swag               # Production with SWAG (Let's Encrypt)
└── pubspec.yaml
```

## Key Implementation Details

### Theme System (`lib/theme/`)

**Design Tokens** (`app_tokens.dart`):
- `AppSpacing`: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48, huge=64, card=40
- `AppRadius`: sm=4, md=8, lg=12, xl=16
- `AppColors`: loginBackground, cardSurface, inputOutline, success, warning, info

**Theme** (`app_theme.dart`):
- Material 3 with `ColorScheme.fromSeed(seedColor: #6750A4)`
- Centralized `TextTheme` matching DESIGN_SYSTEM.md scale
- `CardThemeData`: no elevation, outline border, radius 12
- `InputDecorationTheme`: filled, radius 8, custom borders
- `FilledButtonTheme` / `OutlinedButtonTheme`: min height 40, radius 8

### Shared Components (`lib/components/app_components.dart`)

| Component | Purpose |
|-----------|---------|
| `AppCard` | Wrapper around `Card` with standard padding |
| `AppButton` | `FilledButton` or `FilledButton.icon` with label + optional icon |
| `AppStatusChip` | `Chip` with semantic color, compact density |

**Rule:** Feature screens MUST use these shared components — no feature-local duplicates.

### Navigation & Routing (`main.dart`)

- `GoRouter` with routes: `/` → redirects to `/login`, `/login`, `/projects`
- `ProviderScope` for Riverpod state management
- Responsive: Desktop (≥900px) shows NavigationRail, Mobile shows NavigationBar

### Screen 1: Login (`login_screen.dart`)

- Form with email/password fields, validation
- Dev mode: `DEV=1` environment variable pre-fills credentials
- SVG icons for brain-circuit logo, mail, lock, eye toggle
- "Sign in" navigates to `/projects` (mock — not connected to backend yet)
- "Forgot password" shows snackbar

### Screen 3: Project List (`projects_screen.dart`)

- **Responsive layout:** Desktop (NavigationRail + 3-col grid), Tablet (2-col), Mobile (1-col + NavigationBar)
- **NavigationRail items:** Dashboard, Projects (selected), Documents, Users, Settings + user profile
- **Header:** Title, description, "New Project" button
- **Toolbar:** Search field + SegmentedButton filter (All/Active/Archived)
- **Project Cards:** Name, status chip, description, metrics (documents, members), updated timestamp
- **Mock data:** 6 projects matching `projectlist_ui.md` design spec
- All interactions show "not connected yet" snackbars

## Design System Compliance

Following `DESIGN_SYSTEM.md` and `UI_GUIDELINES.md`:

- ✅ Material 3 foundation
- ✅ Centralized tokens (no hard-coded colors/spacing in widgets)
- ✅ Shared component layer (`app_components.dart`)
- ✅ Responsive: Desktop sidebar (240px), Mobile NavigationBar
- ✅ Semantic status colors (success/error/neutral chips)
- ✅ Card-based layouts for project summaries
- ✅ Loading/Empty/Error states considered

## Screen Specifications Reference

| Screen | Spec File | Status |
|--------|-----------|--------|
| 1: Login | `docs/design/desktop/login_ui.md` | ✅ Implemented |
| 2: Dashboard | `docs/design/desktop/dashboard_ui.md` | ⏳ Not started |
| 3: Project List | `docs/design/desktop/projectlist_ui.md` | ✅ Implemented |
| 4: Project Overview | `docs/design/desktop/projectoverview_ui.md` | ⏳ Not started |

## Development Commands

```bash
# Local dev (web)
cd frontend
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=DEV=1

# Local dev (mobile)
flutter run

# Build web release
flutter build web --release

# Docker (production with SWAG)
docker compose up --build
```

## Dependencies (`pubspec.yaml` - inferred)

Key packages used:
- `flutter_riverpod` — state management
- `go_router` — navigation
- `flutter_svg` — SVG icons
- `dio` — HTTP client (not yet used in skeleton)

## Next Implementation Priorities (Phase 1+)

1. **Screen 2: Dashboard** — Metrics cards, recent activity, project health summary
2. **Screen 4: Project Overview** — Configuration summary, recent conversations
3. **Auth Integration** — Connect login to backend `/auth/firebase/session`, store token
4. **API Client** — Dio-based service with interceptors for auth token
5. **Project CRUD UI** — Create/edit/delete projects, navigate to project detail
6. **Document Management** — Upload, list, reindex within a project
7. **Chat Screen** — Conversation list, streaming messages, citations
8. **Responsive Polish** — Tablet breakpoints, drawer navigation on mobile

## Important Patterns to Follow

- **Reuse shared components** — Never create feature-local `Card`/`Button`/`Chip` variants
- **Use design tokens** — `AppSpacing.lg`, `AppRadius.md`, `theme.colorScheme.primary`
- **Responsive first** — Check `constraints.maxWidth` for desktop/tablet/mobile layouts
- **Form validation** — Use `Form` + `TextFormField` with validators
- **Dev mode** — `String.fromEnvironment('DEV') == '1'` for pre-filled credentials
- **Snackbars for unconnected features** — Consistent "not connected yet" messaging
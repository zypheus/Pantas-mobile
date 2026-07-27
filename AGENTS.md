# AGENTS.md — Pantas-UI

Flutter mobile app for PANTAS patrons. Consumes the Laravel mobile API in `pantas-v2.5/`.

Remote: `https://github.com/zypheus/Pantas-mobile.git`

Run all commands from this directory (`Pantas-UI/`).

## Stack

- Flutter SDK ^3.11
- go_router, http, flutter_secure_storage, intl
- Material/Cupertino widgets — **not** shadcn or daisyUI

## API Backend

- Base URL configured in `lib/core/config/api_config.dart`
- Endpoints under `/api/mobile` on `pantas-v2.5` (Sanctum bearer token auth)
- When changing API integration, coordinate with `pantas-v2.5/routes/api.php`

## Project Layout

```text
lib/
  core/
    config/       api_config.dart
    network/      api_client.dart, api_exception.dart
    router/       app_router.dart
    storage/      token_storage.dart
    theme/        app_colors, app_theme, app_text_styles
  features/       auth, catalog, home, rooms, profile, etc.
  services/       auth, catalog, borrow, room, user, notification
  shared/widgets/ reusable UI components
  models/         data classes
```

Prefer `lib/features/` for new screens. Legacy `lib/screens/` files exist — migrate toward feature folders when touching them.

## Common Commands

```bash
flutter pub get
flutter run
flutter test
flutter analyze
dart format lib/
```

## Coding Standards

- Keep API calls in `lib/services/`, not in widgets.
- Use `ApiClient` for HTTP; store tokens via `TokenStorage`.
- Handle loading, empty, and error states with shared widgets (`loading_state`, `empty_state`, `skeleton_loading`).
- Replace mock data in services with real API calls when integrating endpoints.
- Match existing theme tokens in `lib/core/theme/`.

## Cross-Repo Work

| Task | Repo |
| --- | --- |
| New mobile endpoint | `pantas-v2.5/` |
| New mobile screen | `Pantas-UI/` |
| USM web admin UI | `usm/` (separate app) |

## Verification

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed lib/
```

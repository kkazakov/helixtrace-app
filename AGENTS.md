# AGENTS.md

## Project Overview

HelixTrace is a Flutter mobile app for network mapping and tracing — users authenticate, then manage geographic points and analyze line-of-sight visibility on an interactive map. Always refer to this project as "HelixTrace" (exact capitalization).

**Stack (from `pubspec.yaml`):** Flutter SDK ^3.11.5, `flutter_riverpod ^3.3.1`, `go_router ^17.2.2`, `dio ^5.8.0+1`, `flutter_map ^8.3.0`, `geolocator ^14.0.2`, `flutter_dotenv ^6.0.1`, `shared_preferences ^2.5.3`, `shimmer ^3.0.0`, `latlong2 ^0.9.1`. Dev: `flutter_lints ^6.0.0`.

## Commands

```bash
flutter pub get                              # install dependencies
flutter run                                  # run on connected device
flutter test                                 # full test suite (run before committing)
flutter analyze                              # lint + static analysis
```

**Prerequisites:** A `.env` file with `BASE_URL` must exist (it is declared as a Flutter asset in `pubspec.yaml`). The app crashes at startup if `flutter_dotenv` cannot load it.

## Architecture

```
lib/main.dart              App entry — GoRouter config, AuthenticationShell (session restore), ProviderScope
lib/features/              Feature modules (UI + state)
  auth/                    LoginScreen, RegisterScreen, providers/
  home/                    MapScreen, PointsNotifier, LOS analysis, TerrainGraphPainter
    providers/             points_provider (StateNotifier for point list)
    widgets/               TerrainGraphPainter (CustomPainter for elevation profiles)
lib/data/                  Data layer
  models/                  AuthResponse, PointModel, TracePathModel, ElevationModel, LOS models
  services/                ApiService (Dio client + auth interceptor), AuthService (response parsing)
  repositories/            AuthRepository only
lib/core/                  Shared infrastructure
  config/                  AppConfig (default API URL)
  constants/               AppConstants (storage keys, route names)
  storage/                 StorageService (SharedPreferences singleton)
  theme/                   AppTheme (light/dark ThemeData)
  utils/                   Validators (email, password, URL)
  widgets/                 SleekButton, SleekTextField
```

## Key Rules

- **Provider dependency chain:** StorageService → ApiService → AuthService → AuthRepository → AuthNotifier. Do not break this layering.
- **AuthenticationShell:** A `ConsumerStatefulWidget` that calls `authProvider.notifier.init()` in `Future.microtask` on init, shows a loading spinner during `isInitializing`, then gates on `authState.user != null` to show `MapScreen` or `LoginScreen`.
- **PointModel serialization:** `toJson()` (all fields including id), `toCreateJson()` (no id), `toUpdateJson()` (label + public only). Use the correct one per HTTP verb.
- **ApiService auth interceptor:** Auto-injects `Authorization: Bearer <token>` for all endpoints EXCEPT `/api/login`, `/api/register`, `/api/health`.
- **ApiService error handling:** Catches `DioException` and re-throws `ApiException` with user-friendly messages. Never let Dio exceptions propagate to the UI layer.
- **Form validation:** `Validators` static methods returning `String?` (null = valid, non-null = error message).
- **Production vs test providers:** Production DI lives in `lib/features/auth/providers/providers.dart`. The `auth_provider.dart` file also declares `authRepositoryProvider` and `authProvider` that throw `UnimplementedError` — these exist for test overrides only. Do not import from `auth_provider.dart` for production DI.
- **Map defaults:** Map centers on Sofia, Bulgaria (`42.6977, 23.3219`) by default. Location permission is requested on startup; fails silently if denied.

## Framework Patterns

- Riverpod providers use `StateNotifierProvider` with immutable state classes. Auth state transitions: `initial → initializing → authenticated | initial` (session restore) and `initial → loading → authenticated | error` (login/register).
- Several files import `package:flutter_riverpod/legacy.dart` (auth_provider.dart, providers.dart, points_provider.dart) — this is intentional for Riverpod 3.x compatibility.
- Use `color.withValues(alpha: ...)` for alpha (not the deprecated `withOpacity()`).
- Debug prints are guarded with `kDebugMode`.

## Gotchas

- **SleekTextField typo:** The parameter is `obsecureTextState` (not `obscureTextState`). Do not rename it without updating all call sites.
- **Only AuthRepository exists:** `MapScreen` and `PointsNotifier` call `ApiService` directly for LOS trace paths and point info, bypassing the repository pattern. New repository methods should follow the `AuthRepository` pattern.
- **Theme mode persistence:** Stored as integer index into `ThemeMode.values`. Adding new `ThemeMode` values in Flutter would shift existing stored mappings.
- **LOS analysis uses Earth curvature correction:** `haversineDistance` + curvature drop formula `(d * (totalDistance - d)) / (2 * _earthRadius)`. Do not simplify to flat-earth line-of-sight.
- **Max LOS points:** 3 maximum. With 3 points, computes 3 pairwise traces (0→1, 1→2, 0→2).
- **StorageService keys:** Keys are defined in `AppConstants` and used as hardcoded strings in `StorageService` — they match. When adding new keys, update both locations.
- **Test setup:** Widget tests require `SharedPreferences.setMockInitialValues()` before `StorageService().init()`. The existing test in `test/widget_test.dart` sets `'theme_mode': 0`.

## Boundaries

NEVER:
- Read, modify, or commit `.env` files or any file containing API keys, tokens, or credentials
- Modify `pubspec.yaml` dependencies without noting them in your task summary
- Commit build artifacts (`build/`, `.dart_tool/`, `.flutter-plugins-dependencies`)
- Replace the `AuthenticationShell` auth-gating pattern with a different mechanism

REQUIRE HUMAN CONFIRMATION BEFORE:
- Adding any new external package dependency
- Changing the API base URL or endpoint structure
- Modifying `StorageService` storage keys (risk of data loss for existing users)

## CI/CD

Release workflow (`.github/workflows/release.yml`) triggers on `v*` tags, builds a signed release APK, and publishes it as a GitHub Release. Requires `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` secrets.

## Documentation

Detailed component docs are in `docs/explanation/`. See `docs/index.md` for the full index.

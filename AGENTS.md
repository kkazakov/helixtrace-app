# AGENTS.md

## Project Overview

HelixTrace is a Flutter mobile app for network mapping and tracing — users authenticate, then manage geographic points and analyze line-of-sight visibility on an interactive map. Stack: Flutter SDK ^3.11.5, Dart, flutter_riverpod ^2.6.1, go_router ^14.8.1, dio ^5.8.0+1, flutter_map ^7.0.2, geolocator ^13.0.2. You are a senior Flutter engineer working on a clean-architecture-style mobile app. Always refer to this project as "HelixTrace" (exact capitalization).

## Commands

```bash
flutter pub get                              # install dependencies
flutter run                                  # run on connected device
flutter test                                 # full test suite (run before committing)
flutter test test/widget_test.dart           # single test file
flutter analyze                              # lint + static analysis
```

## Architecture

```
lib/main.dart              App entry — GoRouter config, AuthenticationShell (with session restore), ProviderScope
lib/features/              Feature modules (UI + state)
  auth/                    Login, Register screens + Riverpod providers
  home/                    MapScreen, PointsNotifier, LOS analysis, TerrainGraphPainter
    providers/             points_provider (StateNotifier for point list)
    widgets/               TerrainGraphPainter (CustomPainter for elevation profiles)
lib/data/                  Data layer
  models/                  DTOs: AuthResponse, PointModel, TracePathModel, ElevationModel, PointCategory, LOS models
  services/                ApiService (Dio HTTP client + auth interceptor), AuthService (response parsing + token validation)
  repositories/            AuthRepository (orchestrates service + storage + session restore)
lib/core/                  Shared infrastructure
  config/                  AppConfig (default API URL)
  constants/               AppConstants (storage keys, route names)
  storage/                 StorageService (SharedPreferences singleton)
  theme/                   AppTheme (light/dark ThemeData)
  utils/                   Validators (email, password, URL)
  widgets/                 SleekButton, SleekTextField
```

Key rules:
- Riverpod providers form a dependency chain: StorageService → ApiService → AuthService → AuthRepository → AuthNotifier. Do not break this layering.
- `AuthenticationShell` is a `ConsumerStatefulWidget` that calls `authProvider.notifier.init()` on startup for session restoration, shows a loading spinner during `isInitializing`, then gates on `authState.user != null`.
- `PointModel` has three serialization methods: `toJson()` (full), `toCreateJson()` (no id), `toUpdateJson()` (label + public only). Use the correct one per HTTP verb.

## Conventions

- All Riverpod state uses `StateNotifierProvider` with immutable state classes. Auth state transitions follow `initial → initializing → authenticated | initial` (session restore) and `initial → loading → authenticated | error` (login/register).
- `ApiService` methods catch `DioException` and re-throw `ApiException` with user-friendly messages. Never let Dio exceptions propagate to the UI layer.
- Auth token is injected via a Dio `InterceptorsWrapper` that adds `Authorization: Bearer <token>` to all non-public endpoints (`/api/login`, `/api/register`, `/api/health` are excluded).
- Form validation uses `Validators` static methods returning `String?` (null = valid, non-null = error message).
- Production providers live in `providers.dart`. The `auth_provider.dart` file also declares `authRepositoryProvider` and `authProvider` that throw `UnimplementedError` — these exist for test overrides, not for production use.

Example provider pattern (production, from `providers.dart`):
```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authServiceProvider), ref.read(storageServiceProvider));
});
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
```

Test setup:
- Runner: `flutter_test`. Tests live in `test/`.
- Widget tests use `tester.pumpWidget()` with `ProviderScope` wrapper.
- The existing test (`test/widget_test.dart`) verifies app initialization.

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

## Gotchas

- `StorageService` is a singleton but its storage keys are hardcoded inside the class rather than imported from `AppConstants`. If you add new storage keys, add them both in `AppConstants` AND in `StorageService` — they are currently duplicated.
- `SleekTextField` has a typo: the parameter is named `obsecureTextState` (not `obscureTextState`). Do not rename it without updating all call sites.
- Only `AuthRepository` exists as a repository abstraction. `MapScreen` calls `ApiService` directly for LOS trace paths and point info, bypassing the repository pattern. Future repository methods should follow the `AuthRepository` pattern.
- `auth_provider.dart` declares `authRepositoryProvider` and `authProvider` that throw `UnimplementedError`. These are for test overrides. The production providers are in `providers.dart` — do not import from `auth_provider.dart` for production DI.
- Theme mode is persisted as an integer index into `ThemeMode.values`. Adding new `ThemeMode` values in Flutter would shift existing stored mappings.
- LOS analysis uses Earth curvature correction (`haversineDistance` + curvature drop). Do not simplify to a flat-earth line-of-sight check.

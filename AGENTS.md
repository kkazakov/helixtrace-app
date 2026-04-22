# AGENTS.md

## Project Overview

HelixTrace is a Flutter mobile app for network mapping and tracing — users authenticate, then manage geographic points and trace paths. Stack: Flutter SDK ^3.11.5, Dart, flutter_riverpod ^2.6.1, go_router ^14.8.1, dio ^5.8.0+1. You are a senior Flutter engineer working on a clean-architecture-style mobile app. Always refer to this project as "HelixTrace" (exact capitalization).

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
lib/main.dart              App entry point — GoRouter config, AuthenticationShell, ProviderScope
lib/features/              Feature modules (UI + state)
  auth/                    Login, Register screens + Riverpod providers
  home/                    MapScreen (placeholder — not yet implemented)
lib/data/                  Data layer
  models/                  DTOs: AuthResponse, PointModel, TracePathModel, ElevationModel, PointCategory
  services/                ApiService (Dio HTTP client), AuthService (response parsing)
  repositories/            AuthRepository (orchestrates service + storage)
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
- `AuthenticationShell` watches `authProvider` to gate navigation — if `authState.user != null`, show MapScreen; otherwise show LoginScreen.
- `PointModel` has three serialization methods: `toJson()` (full), `toCreateJson()` (no id), `toUpdateJson()` (label + public only). Use the correct one per HTTP verb.

## Conventions

- All Riverpod state uses `StateNotifierProvider` with immutable state classes. State transitions follow `initial → loading → authenticated | error`.
- `ApiService` methods catch `DioException` and re-throw `ApiException` with user-friendly messages. Never let Dio exceptions propagate to the UI layer.
- Auth token is stored in `StorageService` as a plain string. All authenticated `ApiService` calls inject it via `Authorization: Bearer <token>`.
- Form validation uses `Validators` static methods returning `String?` (null = valid, non-null = error message).

Example provider pattern:
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
```

Test setup:
- Runner: `flutter_test` (dart test). Tests live in `test/`.
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
- Implementing the MapScreen with a new mapping library

## Gotchas

- `StorageService` is a singleton but its storage keys are hardcoded inside the class rather than imported from `AppConstants`. If you add new storage keys, add them both in `AppConstants` AND in `StorageService` — they are currently duplicated.
- `SleekTextField` has a typo: the parameter is named `obsecureTextState` (not `obscureTextState`). Do not rename it without updating all call sites.
- The `MapScreen` in `lib/features/home/` is a static placeholder. Any work on map functionality should start from there.
- Only `AuthRepository` exists as a repository abstraction. Other endpoints (points, trace paths) are called directly from `ApiService`. Future repository methods should follow the `AuthRepository` pattern.
- Theme mode is persisted as an integer index into `ThemeMode.values`. Adding new `ThemeMode` values in Flutter would shift existing stored mappings.

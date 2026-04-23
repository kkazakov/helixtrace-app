# State Management

**Type:** Explanation — this doc describes the Riverpod-based state management architecture, the dependency injection chain, and the state providers used throughout the app.

## Responsibility

State management provides a consistent pattern for managing application state (authentication, theme, points) and wiring dependencies between layers. It enables the UI to reactively read state changes and triggers business logic through state notifiers. If this component fails, the app cannot respond to user actions or reflect data changes.

## Public Interface

### Providers

| Provider | Type | Location | Purpose |
|---|---|---|---|
| `storageServiceProvider` | `Provider<StorageService>` | `lib/features/auth/providers/providers.dart:10` | Provides a `StorageService` instance |
| `apiServiceProvider` | `Provider<ApiService>` | `lib/features/auth/providers/providers.dart:14` | Provides an `ApiService` with the configured base URL |
| `authServiceProvider` | `Provider<AuthService>` | `lib/features/auth/providers/providers.dart:23` | Provides an `AuthService` wired to `ApiService` |
| `authRepositoryProvider` | `Provider<AuthRepository>` | `lib/features/auth/providers/providers.dart:27` | Provides an `AuthRepository` wired to `AuthService` + `StorageService` |
| `authProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | `lib/features/auth/providers/providers.dart:34` | Main auth state provider |
| `themeProvider` | `StateNotifierProvider<ThemeNotifier, ThemeMode>` | `lib/features/auth/providers/providers.dart:38` | Theme mode state provider |
| `pointsProvider` | `StateNotifierProvider<PointsNotifier, PointsState>` | `lib/features/home/providers/points_provider.dart:55` | Points list state provider |
| `routerProvider` | `Provider<GoRouter>` | `lib/main.dart:43` | Navigation router provider |

**Note:** `lib/features/auth/providers/auth_provider.dart` also declares `authRepositoryProvider` and `authProvider` that throw `UnimplementedError`. These are intended for testing overrides and are not the production providers. The production providers are in `providers.dart`.

## Internal Structure

### Dependency Injection Chain

The providers form a layered dependency chain (`lib/features/auth/providers/providers.dart`):

```
StorageService (leaf)
    ↓
ApiService (depends on StorageService for base URL and auth token)
    ↓
AuthService (depends on ApiService)
    ↓
AuthRepository (depends on AuthService + StorageService)
    ↓
AuthNotifier (depends on AuthRepository)
    ↓
UI (LoginScreen, RegisterScreen, AuthenticationShell, MapScreen)
```

Each provider creates its dependency at the next layer down. `ProviderScope` at the app root (`lib/main.dart:21`) manages the lifecycle — all providers share a single instance of each dependency within the scope.

### Auth State (`AuthNotifier` + `AuthState`)

`AuthNotifier` (`lib/features/auth/providers/auth_provider.dart:29`) is a `StateNotifier<AuthState>` that manages authentication:

| Method | Effect |
|---|---|
| `init()` | Sets `state = AuthState.initializing()`, validates stored token via `_repository.restoreSession()`, reconstructs `AuthResponse` from storage if valid, sets authenticated or initial state |
| `login({email, password})` | Sets `state = AuthState.loading()`, calls `_repository.login()`, sets `state = AuthState.authenticated(response)` or `AuthState.error(e.toString())` |
| `register({email, password})` | Same pattern as login |
| `logout()` | Calls `_repository.logout()`, sets `state = AuthState.initial()` |
| `isAuthenticated` (getter) | Delegates to `_repository.isAuthenticated` |

`AuthState` (`lib/features/auth/providers/auth_provider.dart:5`) is an immutable data class:

```dart
class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final AuthResponse? user;
  final String? error;
}
```

Factory constructors: `AuthState.initial()`, `AuthState.initializing()`, `AuthState.loading()`, `AuthState.error(message)`, `AuthState.authenticated(user)`.

The `isInitializing` field is set during session restoration (app startup). When `true`, the `AuthenticationShell` displays a loading spinner instead of the login screen or map. This prevents UI flicker while validating a stored token.

### Theme State (`ThemeNotifier` + `ThemeProvider`)

`ThemeNotifier` (`lib/features/auth/providers/theme_provider.dart:9`) manages the app's theme mode:

| Method | Effect |
|---|---|
| Constructor | Reads initial mode from `StorageService.getThemeMode()` |
| `toggleTheme()` | Switches between `ThemeMode.dark` and `ThemeMode.light`, persists the change |
| `setThemeMode(ThemeMode mode)` | Sets a specific mode, persists the change |

`ThemeProvider` (`lib/features/auth/providers/providers.dart:38`) exposes the current `ThemeMode` to the UI. The `HelixTraceApp` widget watches it and passes it to `MaterialApp.themeMode`.

### Points State (`PointsNotifier` + `PointsState`)

`PointsNotifier` (`lib/features/home/providers/points_provider.dart:23`) manages the list of map points:

| Method | Effect |
|---|---|
| Constructor | Initializes state to `PointsState.loading()` |
| `fetchPoints()` | Sets loading, calls `ApiService.getPoints(includePublic: true, includeMeshcoreDashboard: true)`, parses response into `List<PointModel>`, sets loaded state |

`PointsState` (`lib/features/home/providers/points_provider.dart:7`):

| Field | Type | Description |
|---|---|---|
| `isLoading` | `bool` | Whether points are being fetched |
| `points` | `List<PointModel>` | The list of geographic points |
| `error` | `String?` | Error message if fetch failed |

Factory constructors: `PointsState.loading()`, `PointsState.error(message)`, `PointsState.loaded(points)`.

`pointsProvider` (`lib/features/home/providers/points_provider.dart:55`) watches `apiServiceProvider` and creates a `PointsNotifier` with the current `ApiService` instance.

### Router Provider

`routerProvider` (`lib/main.dart:43`) creates a `GoRouter` instance. It is a regular `Provider<GoRouter>` (not a `StateNotifierProvider`) because the route configuration is static — it does not change at runtime.

## Dependencies

### Internal Dependencies

- **Data layer** — `ApiService`, `AuthService`, `AuthRepository` are wired by providers.
- **Storage** (`lib/core/storage/storage_service.dart`) — Consumed by `AuthRepository`, `ThemeNotifier`, and `ApiService`.
- **Models** — `AuthResponse` is used by `AuthState` and `AuthNotifier`; `PointModel` is used by `PointsState`.

### External Dependencies

- `flutter_riverpod` — State management and dependency injection framework.

## Data Model

### `AuthState` (`lib/features/auth/providers/auth_provider.dart:5`)

| Field | Type | Description |
|---|---|---|
| `isLoading` | `bool` | Whether a login/register operation is in progress |
| `isInitializing` | `bool` | Whether session restoration is in progress |
| `user` | `AuthResponse?` | Authenticated user, null if not logged in |
| `error` | `String?` | Error message from failed operation |

### `PointsState` (`lib/features/home/providers/points_provider.dart:7`)

| Field | Type | Description |
|---|---|---|
| `isLoading` | `bool` | Whether points are being fetched |
| `points` | `List<PointModel>` | The list of geographic points |
| `error` | `String?` | Error message if fetch failed |

### `ThemeMode`

Standard Flutter `ThemeMode` enum: `light`, `dark`, `system`. Stored as an integer index in `StorageService` (0 = light, 1 = dark, 2 = system).

## Key Logic

### Provider scope and dependency lifecycle

All providers live within the `ProviderScope` created in `main()` (`lib/main.dart:21`). Dependencies are created once and reused — for example, a single `StorageService` instance is shared across `ApiService`, `AuthRepository`, and `ThemeNotifier`. This is efficient but means storage initialization in `main()` must complete before any provider is accessed.

### Session restoration on startup

`AuthNotifier.init()` is called once by the `AuthenticationShell` via `Future.microtask()` in `initState()`. It sets `isInitializing = true`, validates any stored token, and transitions to either `authenticated` (valid token) or `initial` (no token or invalid token). The shell shows a loading spinner during this phase.

### Reactive UI updates

Screens use `ConsumerWidget` (or `ConsumerStatefulWidget`) and call `ref.watch(provider)` to subscribe to state changes. When `authProvider` or `pointsProvider` emits a new state, all watching widgets rebuild automatically. The map screen watches `pointsProvider` to render point markers and `authProvider` for user identity.

### Theme persistence

`ThemeNotifier` reads the stored theme mode on construction and writes to storage on every change. The stored value is an integer index into `ThemeMode.values`, which is fragile if Flutter adds new `ThemeMode` values — it would shift the mapping.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| Theme mode | `StorageService` (SharedPreferences) | Persisted light/dark/system preference |

## Design Decisions & Trade-offs

### Single provider file for dependency wiring

All provider wiring lives in `lib/features/auth/providers/providers.dart`. This barrel file defines the full DI chain in one place but mixes auth-related providers with infrastructure providers (storage, API, router). As the app grows, splitting providers by layer (infrastructure vs. feature) would improve maintainability.

### Duplicate provider declarations in auth_provider.dart

`auth_provider.dart` declares its own `authRepositoryProvider` and `authProvider` that throw `UnimplementedError`. These exist for unit testing — tests can override these providers with mocks. The production providers in `providers.dart` override these with real implementations via the `ref.read()` chain.

### Integer-based theme mode storage

`StorageService.setThemeMode()` stores the theme as `themeMode.index` (`lib/core/storage/storage_service.dart:47`). This is simple but fragile — if Flutter adds a new `ThemeMode` value, existing stored indices could map to the wrong mode. Using a string-based key or explicit mapping would be more robust.

### No repository for points or trace paths

Only `AuthRepository` has a repository layer. The `PointsNotifier` calls `ApiService` directly, and the map screen calls `getTracePath()` and `getPointInfo()` via `apiServiceProvider`. This keeps the implementation simple but couples the UI to the API response format.

### Debug logging in PointsNotifier

`PointsNotifier.fetchPoints()` includes `debugPrint` statements for API responses and errors when `kDebugMode` is true. These are helpful for development but should be removed or replaced with a proper logging framework in production.

## Testing

- No tests exist for providers, notifiers, or state management logic.
- Riverpod's `ProviderContainer` and `fake_async` can be used to test providers in isolation.
- The `authRepositoryProvider` and `authProvider` in `auth_provider.dart` that throw `UnimplementedError` are intended for test overrides.
- To run existing tests: `flutter test`

## Related Components

- [Authentication](authentication.md) — `authProvider` drives the auth screens and shell.
- [App Entry & Routing](app-entry-routing.md) — `routerProvider` and `themeProvider` are defined in `main.dart`.
- [Data Layer](data-layer.md) — `ApiService`, `AuthService`, and `AuthRepository` are the leaf dependencies in the provider chain.
- [Map Screen](map-screen.md) — `pointsProvider` supplies point data for the map display.
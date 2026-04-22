# State Management

**Type:** Explanation — this doc describes the Riverpod-based state management architecture, the dependency injection chain, and the state providers used throughout the app.

## Responsibility

State management provides a consistent pattern for managing application state (authentication, theme) and wiring dependencies between layers. It enables the UI to reactively read state changes and triggers business logic through state notifiers. If this component fails, the app cannot respond to user actions or reflect data changes.

## Public Interface

### Providers

| Provider | Type | Location | Purpose |
|---|---|---|---|
| `storageServiceProvider` | `Provider<StorageService>` | `lib/features/auth/providers/theme_provider.dart:29` | Provides a `StorageService` instance |
| `apiServiceProvider` | `Provider<ApiService>` | `lib/features/auth/providers/providers.dart:14` | Provides an `ApiService` with the configured base URL |
| `authServiceProvider` | `Provider<AuthService>` | `lib/features/auth/providers/providers.dart:20` | Provides an `AuthService` wired to `ApiService` |
| `authRepositoryProvider` | `Provider<AuthRepository>` | `lib/features/auth/providers/providers.dart:23` | Provides an `AuthRepository` wired to `AuthService` + `StorageService` |
| `authProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | `lib/features/auth/providers/providers.dart:28` | Main auth state provider |
| `themeProvider` | `StateNotifierProvider<ThemeNotifier, ThemeMode>` | `lib/features/auth/providers/providers.dart:34` | Theme mode state provider |
| `routerProvider` | `Provider<GoRouter>` | `lib/main.dart:43` | Navigation router provider |

## Internal Structure

### Dependency Injection Chain

The providers form a layered dependency chain (`lib/features/auth/providers/providers.dart`):

```
StorageService (leaf)
    ↓
ApiService (depends on StorageService for base URL)
    ↓
AuthService (depends on ApiService)
    ↓
AuthRepository (depends on AuthService + StorageService)
    ↓
AuthNotifier (depends on AuthRepository)
    ↓
UI (LoginScreen, RegisterScreen, AuthenticationShell)
```

Each provider creates its dependency at the next layer down. `ProviderScope` at the app root (`lib/main.dart:21`) manages the lifecycle — all providers share a single instance of each dependency within the scope.

### Auth State (`AuthNotifier` + `AuthState`)

`AuthNotifier` (`lib/features/auth/providers/auth_provider.dart:17`) is a `StateNotifier<AuthState>` that manages authentication:

| Method | Effect |
|---|---|
| `login({email, password})` | Sets `state = AuthState.loading()`, calls `_repository.login()`, sets `state = AuthState.authenticated(response)` or `AuthState.error(e.message)` |
| `register({email, password})` | Same pattern as login |
| `logout()` | Calls `_repository.logout()`, sets `state = AuthState.initial()` |
| `isAuthenticated` (getter) | Delegates to `_repository.isAuthenticated` |

`AuthState` (`lib/features/auth/providers/auth_provider.dart:7`) is an immutable data class:

```dart
class AuthState {
  final bool isLoading;
  final AuthResponse? user;
  final String? error;
}
```

### Theme State (`ThemeNotifier` + `ThemeProvider`)

`ThemeNotifier` (`lib/features/auth/providers/theme_provider.dart:10`) manages the app's theme mode:

| Method | Effect |
|---|---|
| Constructor | Reads initial mode from `StorageService.getThemeMode()` |
| `toggleTheme()` | Switches between `ThemeMode.dark` and `ThemeMode.light`, persists the change |
| `setThemeMode(ThemeMode mode)` | Sets a specific mode, persists the change |

`ThemeProvider` (`lib/features/auth/providers/providers.dart:34`) exposes the current `ThemeMode` to the UI. The `HelixTraceApp` widget watches it and passes it to `MaterialApp.themeMode`.

### Router Provider

`routerProvider` (`lib/main.dart:43`) creates a `GoRouter` instance. It is a regular `Provider<GoRouter>` (not a `StateNotifierProvider`) because the route configuration is static — it does not change at runtime.

## Dependencies

### Internal Dependencies

- **Data layer** — `ApiService`, `AuthService`, `AuthRepository` are wired by providers.
- **Storage** (`lib/core/storage/storage_service.dart`) — Consumed by `AuthRepository`, `ThemeNotifier`, and `ApiService`.
- **Models** — `AuthResponse` is used by `AuthState` and `AuthNotifier`.

### External Dependencies

- `flutter_riverpod` — State management and dependency injection framework.

## Data Model

### `AuthState` (`lib/features/auth/providers/auth_provider.dart:7`)

| Field | Type | Description |
|---|---|---|
| `isLoading` | `bool` | Whether a login/register operation is in progress |
| `user` | `AuthResponse?` | Authenticated user, null if not logged in |
| `error` | `String?` | Error message from failed operation |

Factory constructors: `AuthState.initial()`, `AuthState.loading()`, `AuthState.error(message)`, `AuthState.authenticated(user)`.

### `ThemeMode`

Standard Flutter `ThemeMode` enum: `light`, `dark`, `system`. Stored as an integer index in `StorageService` (0 = light, 1 = dark, 2 = system).

## Key Logic

### Provider scope and dependency lifecycle

All providers live within the `ProviderScope` created in `main()` (`lib/main.dart:21`). Dependencies are created once and reused — for example, a single `StorageService` instance is shared across `ApiService`, `AuthRepository`, and `ThemeNotifier`. This is efficient but means storage initialization in `main()` must complete before any provider is accessed.

### Reactive UI updates

Screens use `ConsumerWidget` (or `ConsumerStatefulWidget`) and call `ref.watch(provider)` to subscribe to state changes. When `authProvider` emits a new state, all watching widgets rebuild automatically. This is how the login screen shows loading spinners, error messages, and success navigation.

### Theme persistence

`ThemeNotifier` reads the stored theme mode on construction and writes to storage on every change. This means the theme preference survives app restarts. The stored value is an integer index into `ThemeMode.values`, which is fragile if Flutter adds new `ThemeMode` values — it would shift the mapping.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| Theme mode | `StorageService` (SharedPreferences) | Persisted light/dark/system preference |

## Design Decisions & Trade-offs

### Riverpod over other state management options

The project uses `flutter_riverpod` for both state management and dependency injection. This eliminates the need for a separate DI framework and provides compile-safe provider references. The trade-off is an additional dependency and learning curve for developers unfamiliar with Riverpod.

### Single provider file for dependency wiring

All provider wiring lives in `lib/features/auth/providers/providers.dart`. This barrel file defines the full DI chain in one place but mixes auth-related providers with infrastructure providers (storage, API, router). As the app grows, splitting providers by layer (infrastructure vs. feature) would improve maintainability.

### Integer-based theme mode storage

`StorageService.setThemeMode()` stores the theme as `themeMode.index` (`lib/core/storage/storage_service.dart:55`). This is simple but fragile — if Flutter adds a new `ThemeMode` value, existing stored indices could map to the wrong mode. Using a string-based key or explicit mapping would be more robust.

### No provider for data layer repositories beyond auth

Only `AuthRepository` has a provider. The `ApiService` methods for points, trace paths, and categories are used directly without a repository abstraction or dedicated provider. Future providers will need to follow the same pattern as `authProvider` (notifier + state + repository).

## Testing

- No tests exist for providers, notifiers, or state management logic.
- Riverpod's `ProviderContainer` and `fake_async` can be used to test providers in isolation.
- To run existing tests: `flutter test`

## Related Components

- [Authentication](authentication.md) — `authProvider` drives the auth screens and shell.
- [App Entry & Routing](app-entry-routing.md) — `routerProvider` and `themeProvider` are defined in `main.dart`.
- [Data Layer](data-layer.md) — `ApiService`, `AuthService`, and `AuthRepository` are the leaf dependencies in the provider chain.

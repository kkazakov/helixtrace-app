# App Entry & Routing

**Type:** Explanation — this doc describes the application entry point, initialization sequence, navigation configuration, and the authentication shell with session restoration.

## Responsibility

The entry point and routing layer bootstraps the Flutter application, initializes shared services, configures the navigation system via `GoRouter`, and manages the authenticated vs. unauthenticated screen transition including session restoration on app startup. If this component fails, the entire app cannot start or navigate.

## Public Interface

- **`main()`** (`lib/main.dart:13`) — Application entry point. Called by the Flutter framework.
- **`HelixTraceApp`** (`lib/main.dart:24`) — Root `ConsumerWidget` that watches theme and router providers.
- **`AuthenticationShell`** (`lib/main.dart:67`) — `ConsumerStatefulWidget` that manages session restoration, shows a loading indicator during initialization, and conditionally shows the login screen or map based on auth state.
- **`routerProvider`** (`lib/main.dart:43`) — Riverpod provider that creates and configures the `GoRouter` instance.

## Internal Structure

### Initialization Sequence

The `main()` function executes in this order:

1. `WidgetsFlutterBinding.ensureInitialized()` — Ensures Flutter binding is ready before async operations.
2. `dotenv.load(fileName: '.env')` — Loads environment variables from `.env` file using `flutter_dotenv`. This provides the API base URL configuration.
3. `StorageService().init()` — Initializes the shared preferences storage. Must complete before the app runs.
4. `ProviderScope(child: HelixTraceApp())` — Wraps the app in Riverpod's `ProviderScope` to enable dependency injection.

### Router Configuration

The `routerProvider` provider creates a `GoRouter` with the following route structure:

| Route | Path | Screen |
|---|---|---|
| Login | `/` | `AuthenticationShell` → `LoginScreen` |
| Register | `/register` (child of login) | `RegisterScreen` |
| Home | `/home` | `MapScreen` |

The router starts at `AppConstants.routeLogin` (`'/'`). The `AuthenticationShell` widget watches the auth state and acts as a guard: if the user is initializing, it shows a loading spinner; if authenticated (`authState.user != null`), it renders `MapScreen`; otherwise, it renders `LoginScreen`.

### Authentication Shell

`AuthenticationShell` (`lib/main.dart:67`) is a `ConsumerStatefulWidget` that manages two concerns:

1. **Session restoration** — On `initState()`, it schedules `authProvider.notifier.init()` via `Future.microtask()`. This triggers the session restoration flow (validating the stored token against the API).
2. **Screen selection** — The `build()` method checks auth state:
   - `authState.isInitializing == true` → Shows a centered `CircularProgressIndicator` on a gradient background
   - `authState.user != null` → Shows `MapScreen`
   - Otherwise → Shows `LoginScreen`

The initialization loading state prevents the brief flash of the login screen that would occur while the stored token is being validated.

## Dependencies

### Internal Dependencies

- **Auth feature** (`lib/features/auth/`) — The shell reads `authProvider` to determine navigation state and triggers session restoration.
- **Storage service** (`lib/core/storage/storage_service.dart`) — Initialized in `main()` before the app runs.
- **Theme provider** (`lib/features/auth/providers/theme_provider.dart`) — Watched by `HelixTraceApp` to set theme mode.
- **Constants** (`lib/core/constants/app_constants.dart`) — Defines route names used by the router.

### External Dependencies

- `flutter_dotenv` — Environment variable loading.
- `flutter_riverpod` — Dependency injection via `ProviderScope` and `routerProvider`.
- `go_router` — Declarative routing.

## Data Model

This component does not own data. It references `AuthResponse` (from `lib/data/models/auth_response.dart`) indirectly through the `authProvider` state.

## Key Logic

### Session restoration on startup

The auth shell's `initState()` schedules a microtask to call `ref.read(authProvider.notifier).init()`. This method validates any stored token against the API. During validation, the shell shows a loading spinner with a gradient background (dark or light depending on system theme). Once validation completes, the shell transitions to either `MapScreen` (valid session) or `LoginScreen` (no session or invalid token).

### Auth-based screen selection

The authentication shell's conditional rendering is the core routing logic (`lib/main.dart:85-117`):

```dart
final authState = ref.watch(authProvider);

if (authState.isInitializing) {
  return Scaffold(/* gradient background + CircularProgressIndicator */);
}

if (authState.user != null) {
  return const MapScreen();
}
return const LoginScreen();
```

This means authentication state flows from the Riverpod provider → shell widget → screen selection. There is no separate auth middleware or route guard — the check happens at the widget level.

### Environment-based API configuration

The API base URL comes from `.env` (loaded via `flutter_dotenv`), with a fallback to `AppConfig.defaultBaseUrl` (`'https://trace-api.meshcore.bg/'`) in `ApiService` (`lib/data/services/api_service.dart:14`). Users can also set a custom URL at runtime via the login screen's API URL dialog, which persists it in `StorageService`.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| `API_BASE_URL` | `.env` file | Backend API endpoint — loaded by `flutter_dotenv` |
| Route names | `AppConstants` | Centralized string keys for login, register, home routes |
| Theme mode | `StorageService` (persistent) | Light, dark, or system — persisted across sessions |

## Design Decisions & Trade-offs

### Widget-level auth guard vs. route guard

The auth check happens in the `AuthenticationShell` widget rather than as a GoRouter redirect. This is simpler for the current two-route auth flow but does not protect the `/home` route directly — a user who knows the URL can navigate there without going through the shell's check. A route-level redirect would be more robust as the app grows.

### Session restoration with loading state

The `isInitializing` state prevents a brief flash of the login screen while the stored token is being validated. Without this, users with valid sessions would see the login screen for a moment before being redirected to the map. The trade-off is an extra loading screen on every app start, but it provides a smoother experience.

### Router as a provider

The `GoRouter` instance lives in a Riverpod provider (`routerProvider`) rather than being created directly in `main()`. This allows the router to depend on Riverpod-injected services. It also makes the router testable.

### Nested login/register routes

The register screen is nested under the login route (`/register` as a child of `/`). This gives the login shell a natural place to share chrome (background, branding) between both screens. The register screen uses `context.pop()` to navigate back rather than going to a specific route path.

## Testing

- **Widget test** exists in `test/widget_test.dart` that verifies the app initializes and renders a `Scaffold`. It pumps `HelixTraceApp` inside `ProviderScope` and asserts `find.byType(Scaffold)` finds one widget.
- No unit tests exist for the router configuration, authentication shell logic, or session restoration.
- To run: `flutter test`

## Related Components

- [Authentication](authentication.md) — The auth screens and state that drive the routing guard.
- [State Management](state-management.md) — The Riverpod providers that feed the router and shell.
- [Core Infrastructure](core-infrastructure.md) — Storage service and constants used during initialization.
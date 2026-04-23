# Authentication

**Type:** Explanation — this doc describes the authentication feature: login and registration screens, auth state management, session restoration, and the authentication flow.

## Responsibility

The authentication feature handles user identity verification through login and registration. It manages the auth state lifecycle (initializing, loading, success, error), persists credentials locally, restores sessions on app startup, and gates access to the authenticated home screen. If this component fails, users cannot access the application.

## Public Interface

### Screens

- **`LoginScreen`** (`lib/features/auth/login_screen.dart:11`) — `ConsumerStatefulWidget` that renders the login form with email/password fields, API URL configuration, theme toggle, and navigation to registration.
- **`RegisterScreen`** (`lib/features/auth/register_screen.dart:11`) — `ConsumerStatefulWidget` that renders the registration form with email/password/confirm-password fields and navigation back to login.

### State

- **`authProvider`** (`lib/features/auth/providers/providers.dart:34`) — `StateNotifierProvider<AuthNotifier, AuthState>` — the single source of truth for authentication state, consumed by both screens, the authentication shell, and the map screen menu.

## Internal Structure

### Login Screen

`LoginScreen` renders a branded form with:

1. Top-right toolbar: API URL configuration button (opens dialog), theme toggle button
2. Branded logo (gradient circle with GPS icon)
3. "HelixTrace" title and "Map the invisible network" subtitle
4. Email field (validated with `Validators.emailValidator`, disabled until API URL is set)
5. Password field (validated with `Validators.passwordValidator`, obscured with toggle)
6. Login button (disabled until API URL is set, shows shimmer animation when loading)
7. Error message display (styled with error color background)
8. Registration link (visible only when API URL is configured)

On submit, the screen calls `authProvider.notifier.login(email: email, password: password)` and navigates to `AppConstants.routeHome` (`'/home'`) on success using `context.go()`.

### Register Screen

`RegisterScreen` mirrors the login screen structure with:
1. Top-right toolbar: API URL configuration button, theme toggle button
2. Branded logo (gradient circle with person_add icon)
3. "Create Account" title and "Join HelixTrace today" subtitle
4. Email field, password field, confirm-password field
5. Registration button
6. Error message display
7. Login link ("Already have an account?")

It validates that both password fields match before submitting. On submit, it calls `authProvider.notifier.register(email: email, password: password)` and navigates to home on success.

### Auth State Machine

The `AuthNotifier` (`lib/features/auth/providers/auth_provider.dart:29`) implements a state machine with five states:

| State | Meaning | Transition |
|---|---|---|
| `AuthState.initial()` | Idle, no operation in progress | Default, after logout, or after failed init |
| `AuthState.initializing()` | Session restoration in progress | On app startup via `init()` |
| `AuthState.loading()` | Login/register request in flight | On submit |
| `AuthState.authenticated(user)` | Success — user object available | After successful API call or restored session |
| `AuthState.error(message)` | Failure — error message available | After failed API call |

Transitions: `initial → initializing → authenticated | initial` (session restoration), `initial → loading → authenticated | error` (login/register), `any → initial` (logout).

### Session Restoration

On app startup, the `AuthenticationShell` calls `authProvider.notifier.init()` via `Future.microtask()` in `initState()`. The `init()` method:

1. Sets state to `AuthState.initializing()`
2. Calls `AuthRepository.restoreSession()`, which validates the stored token against the API
3. If valid: reconstructs a minimal `AuthResponse` from stored email and token, sets `AuthState.authenticated()`
4. If invalid: clears storage, sets `AuthState.initial()`

The `AuthenticationShell` watches `authState.isInitializing` to show a loading spinner during this process.

### Auth Repository

`AuthRepository` (`lib/data/repositories/auth_repository.dart:5`) combines network calls and local storage:

| Method | Behavior |
|---|---|
| `login(email, password)` | Calls `AuthService.login()`, persists token + email via `StorageService`, validates token, returns `AuthResponse` |
| `register(email, password)` | Calls `AuthService.register()`, persists token + email via `StorageService`, validates token, returns `AuthResponse` |
| `logout()` | Clears token + email from `StorageService` |
| `restoreSession()` | Checks stored token + email, validates via `AuthService.validateToken()`, returns `true`/`false`; clears storage on failure |
| `isAuthenticated` | Returns `true` if a stored token exists |
| `currentUserEmail` | Returns the stored email, or `null` |
| `currentToken` | Returns the stored token, or `null` |

## Dependencies

### Internal Dependencies

- **Data layer** (`lib/data/`) — `AuthService` for HTTP calls, `AuthResponse` model, `ApiException` for errors.
- **Storage** (`lib/core/storage/storage_service.dart`) — Persists auth token, email, and API URL.
- **Validators** (`lib/core/utils/validators.dart`) — Email, password, and URL validation.
- **Constants** (`lib/core/constants/app_constants.dart`) — Route names.

### External Dependencies

- **HelixTrace Backend API** — `https://trace-api.meshcore.bg/` — handles actual authentication.
- `Dio` — HTTP client used by `ApiService`.
- `flutter_dotenv` — Loads API URL from `.env`.

## Data Model

### `AuthResponse` (`lib/data/models/auth_response.dart`)

| Field | Type | Description |
|---|---|---|
| `token` | `String` | Bearer token for authenticated requests |
| `email` | `String` | User's email address |
| `username` | `String` | User's display name |

Parsed from JSON via `fromJson()` factory constructor.

## Key Logic

### Error handling by status code

`ApiService.login()` and `ApiService.register()` (`lib/data/services/api_service.dart:46-86`) catch `DioException` and map specific HTTP status codes to user-friendly `ApiException` messages:

- `403` — "Account is disabled. Contact support."
- `401` — "Invalid email or password."
- `409` — "An account with this email already exists." (register only)
- Network errors — "Network error. Please check your connection."

### API URL requirement

Both login and register screens check whether an API URL has been configured (`_apiUrlSet` in `login_screen.dart:24`). The submit button and form fields are disabled until the user sets an API URL via the top-right dialog. This allows users to configure a custom backend endpoint before authenticating.

### Session restoration flow

```
App starts → AuthenticationShell.initState()
    ↓
Future.microtask() → authProvider.notifier.init()
    ↓
State = AuthState.initializing() → shows loading spinner
    ↓
AuthRepository.restoreSession()
    ↓
If stored token + email exist:
    AuthService.validateToken() → GET /api/points
    ↓
    Valid → AuthState.authenticated(reconstructed AuthResponse)
    Invalid → AuthRepository.logout() → AuthState.initial()
    ↓
Shell watches state → shows MapScreen (authenticated) or LoginScreen (initial)
```

### Token persistence

After successful login or register, the repository saves the auth token and email to `StorageService`. The token is then injected as a `Bearer` header in all subsequent authenticated API requests via the Dio interceptor in `ApiService`.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| `API_BASE_URL` | `.env` / `StorageService` | Backend API endpoint used for auth requests |
| `auth_token` | `StorageService` (SharedPreferences) | Persisted Bearer token |
| `user_email` | `StorageService` (SharedPreferences) | Persisted user email |

## Design Decisions & Trade-offs

### Repository as auth orchestrator

`AuthRepository` delegates HTTP calls to `AuthService` and persistence to `StorageService`. This keeps the notifier thin — it only manages state transitions. However, the repository currently has no interface/abstract layer, making it harder to mock in tests.

### Token stored in SharedPreferences

The auth token is stored in plain text in SharedPreferences. This is acceptable for a mobile app with device-level encryption but is not suitable for sensitive tokens in production. Consider encrypted storage (e.g., `flutter_secure_storage`) if the token sensitivity increases.

### Post-login token validation

Both `login()` and `register()` in `AuthRepository` call `AuthService.validateToken()` after persisting the token. This double-check ensures the returned token is actually accepted by the API before transitioning to the authenticated state. The trade-off is an extra network request on every login/register.

### Logout now available

The map screen side menu provides a logout button that calls `authProvider.notifier.logout()` and navigates to the login route. This was previously missing (noted in earlier docs as a known gap).

### Placeholder force-unwrap of email initial

The menu header in `MapScreen` accesses `(authState.user?.email ?? '')[0].toUpperCase()`, which would throw if `email` is an empty string. This is safe in practice because the backend validates email format.

## Testing

- **Widget test** in `test/widget_test.dart` verifies the app initializes correctly, which indirectly exercises the auth shell's default state (initializing → unauthenticated → login screen).
- No dedicated tests exist for `AuthNotifier`, `AuthRepository`, or the auth screens.
- The `authRepositoryProvider` and `authProvider` declarations in `auth_provider.dart` that throw `UnimplementedError` are intended for test overrides.
- To run: `flutter test`

## Related Components

- [App Entry & Routing](app-entry-routing.md) — The authentication shell that gates access based on auth state.
- [Data Layer](data-layer.md) — `AuthService` and `ApiService` handle the actual HTTP auth requests.
- [State Management](state-management.md) — The `authProvider` dependency injection chain.
- [Map Screen](map-screen.md) — Provides the logout button in the side menu.
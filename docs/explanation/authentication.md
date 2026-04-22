# Authentication

**Type:** Explanation — this doc describes the authentication feature: login and registration screens, auth state management, and the authentication flow.

## Responsibility

The authentication feature handles user identity verification through login and registration. It manages the auth state lifecycle (loading, success, error), persists credentials locally, and gates access to the authenticated home screen. If this component fails, users cannot access the application.

## Public Interface

### Screens

- **`LoginScreen`** (`lib/features/auth/login_screen.dart:1`) — `ConsumerStatefulWidget` that renders the login form with email/password fields, API URL configuration, and navigation to registration.
- **`RegisterScreen`** (`lib/features/auth/register_screen.dart:1`) — `ConsumerStatefulWidget` that renders the registration form with email/password/confirm-password fields and navigation back to login.

### State

- **`authProvider`** (`lib/features/auth/providers/providers.dart:28`) — `StateNotifierProvider<AuthNotifier, AuthState>` — the single source of truth for authentication state, consumed by both screens and the authentication shell.

## Internal Structure

### Login Screen

`LoginScreen` renders a branded form with:

1. Email field (validated with `Validators.emailValidator`)
2. Password field (validated with `Validators.passwordValidator`, obscured)
3. API URL configuration button (opens a dialog validated with `Validators.urlValidator`)
4. Login button (disabled until an API URL is set via `StorageService`)
5. Register navigation link

On submit, the screen calls `authProvider.notifier.login(email: email, password: password)` and navigates to `AppConstants.routeHome` (`'/home'`) on success using `context.go()`.

### Register Screen

`RegisterScreen` mirrors the login screen structure with an additional confirm-password field. It validates that both password fields match before submitting. On submit, it calls `authProvider.notifier.register(email: email, password: password)` and navigates to home on success.

### Auth State Machine

The `AuthNotifier` (`lib/features/auth/providers/auth_provider.dart`) implements a three-state machine:

| State | Meaning | Transition |
|---|---|---|
| `AuthState.initial()` | Idle, no operation in progress | Default, or after logout |
| `AuthState.loading()` | Login/register request in flight | On submit |
| `AuthState.authenticated(user)` | Success — user object available | After successful API call |
| `AuthState.error(message)` | Failure — error message available | After failed API call |

Transitions: `initial → loading → authenticated | error → initial` (on retry or logout).

### Auth Repository

`AuthRepository` (`lib/features/auth/providers/auth_provider.dart`) combines network calls and local storage:

| Method | Behavior |
|---|---|
| `login(email, password)` | Calls `AuthService.login()`, persists token + email via `StorageService`, returns `AuthResponse` |
| `register(email, password)` | Calls `AuthService.register()`, persists token + email via `StorageService`, returns `AuthResponse` |
| `logout()` | Clears token + email from `StorageService` |
| `isAuthenticated` | Returns `true` if a stored token exists |
| `currentUserEmail` | Returns the stored email, or `null` |

## Dependencies

### Internal Dependencies

- **Data layer** (`lib/data/`) — `AuthService` for HTTP calls, `AuthResponse` model, `ApiException` for errors.
- **Storage** (`lib/core/storage/storage_service.dart`) — Persists auth token and email.
- **Validators** (`lib/core/utils/validators.dart`) — Email, password, and URL validation.
- **Constants** (`lib/core/constants/app_constants.dart`) — Route names.

### External Dependencies

- **HelixTrace Backend API** — `https://trace-api.meshcore.bg/` — handles actual authentication.
- `Dio` — HTTP client used by `ApiService`.
- `flutter_dotenv` — Loads API URL from `.env`.

## Data Model

### `AuthResponse` (`lib/data/models/auth_response.dart`)

Represents the response from login/register endpoints:

| Field | Type | Description |
|---|---|---|
| `token` | `String` | Bearer token for authenticated requests |
| `email` | `String` | User's email address |
| `username` | `String` | User's display name |

Parsed from JSON via `fromJson()` factory constructor.

## Key Logic

### Error handling by status code

`ApiService.login()` and `ApiService.register()` (`lib/data/services/api_service.dart:26-67`) catch `DioException` and map specific HTTP status codes to user-friendly `ApiException` messages:

- `403` — "Account is disabled. Contact support."
- `401` — "Invalid email or password."
- `409` — "An account with this email already exists." (register only)
- Network errors — "Network error. Please check your connection."

### API URL requirement

Both login and register screens check whether an API URL has been configured (`_hasApiUrl()` in `login_screen.dart:144-147`). The submit button is disabled until the user sets one via the "API URL" dialog. This allows users to configure a custom backend endpoint (e.g., a local development server) before authenticating.

### Token persistence

After successful login or register, the repository saves the auth token to `StorageService` using the key `'auth_token'`. The token is then included as a `Bearer` header in all subsequent authenticated API requests via `ApiService._addAuthHeaders()`.

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

### No logout UI yet

The `AuthNotifier` exposes a `logout()` method and the repository supports logout, but neither screen has a logout button. The user remains authenticated until the token is manually cleared or the app data is wiped.

### Placeholder home screen

After authentication, users are routed to `MapScreen` which is currently a static placeholder. The actual map/tracing functionality is not yet implemented.

## Testing

- **Widget test** in `test/widget_test.dart` verifies the app initializes correctly, which indirectly exercises the auth shell's default state (unauthenticated → login screen).
- No dedicated tests exist for `AuthNotifier`, `AuthRepository`, or the auth screens.
- To run: `flutter test`

## Related Components

- [App Entry & Routing](app-entry-routing.md) — The authentication shell that gates access based on auth state.
- [Data Layer](data-layer.md) — `AuthService` and `ApiService` handle the actual HTTP auth requests.
- [State Management](state-management.md) — The `authProvider` dependency injection chain.

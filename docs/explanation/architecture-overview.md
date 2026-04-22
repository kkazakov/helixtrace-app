# Architecture Overview

**Type:** Explanation — this doc provides a system-level map of HelixTrace using C4 model concepts.

## System Context

HelixTrace is a mobile application for network mapping and tracing. It allows users to create accounts, authenticate, and manage geographic points (markers with location, elevation, and categorization). The app communicates with a backend API that handles authentication, point storage, trace path computation, and elevation data.

### Actors

- **Registered user** — Creates an account, logs in, manages points, views trace paths.
- **HelixTrace Backend API** — External system that provides authentication, data storage, and trace computation.

### External Systems

| System | Role | Criticality |
|---|---|---|
| HelixTrace Backend API (`trace-api.meshcore.bg`) | Authentication, point CRUD, trace paths, elevation data, categories | Critical — app is unusable without it |

## Containers

The system consists of two containers:

| Container | Technology | Responsibility |
|---|---|---|
| HelixTrace Mobile App | Flutter (Dart), iOS + Android | UI, navigation, local state, API client |
| HelixTrace Backend API | Unknown (hosted at `trace-api.meshcore.bg`) | Authentication, data persistence, trace computation |

## Components

### App Entry & Routing

Entry point (`lib/main.dart`), `GoRouter` navigation configuration, and `AuthenticationShell` that guards authenticated routes.

→ [Full documentation](app-entry-routing.md)

### Authentication

Login and registration screens (`lib/features/auth/`), `AuthNotifier` state machine, and `AuthRepository` that orchestrates HTTP calls and local storage.

→ [Full documentation](authentication.md)

### Data Layer

`ApiService` (Dio HTTP client), `AuthService` (response parsing), `AuthRepository` (service + storage), and data models (`AuthResponse`, `PointModel`, `TracePathModel`, `ElevationModel`, `PointCategory`).

→ [Full documentation](data-layer.md)

### State Management

Riverpod providers (`lib/features/auth/providers/providers.dart`), `AuthNotifier`/`AuthState`, `ThemeNotifier`/`ThemeProvider`, and the dependency injection chain.

→ [Full documentation](state-management.md)

### Core Infrastructure

Shared utilities: `StorageService` (SharedPreferences), `AppTheme` (light/dark themes), `Validators` (form validation), `AppConstants` (string keys), `SleekButton` and `SleekTextField` (reusable widgets).

→ [Full documentation](core-infrastructure.md)

### Home / Map (Placeholder)

`MapScreen` (`lib/features/home/map_screen.dart`) — Currently a static placeholder. Will display network maps and trace paths once the mapping functionality is implemented.

## Data Flow

### Authentication Flow

```
User enters email/password
       ↓
LoginScreen calls authProvider.notifier.login()
       ↓
AuthNotifier calls AuthRepository.login()
       ↓
AuthRepository calls AuthService.login() → ApiService.login() → POST /api/login
       ↓
Backend returns token + user data
       ↓
AuthRepository saves token + email to StorageService
       ↓
AuthNotifier sets state = AuthState.authenticated(user)
       ↓
LoginScreen watches state, navigates to /home via context.go()
```

### Point Creation Flow (defined but not yet wired to UI)

```
User creates a point (future UI)
       ↓
Provider calls ApiService.createPoint(lat, lon, categoryId, label, public)
       ↓
Backend stores point, returns PointModel with id
       ↓
Provider updates UI state with new point
```

### Trace Path Flow (defined but not yet wired to UI)

```
User selects from/to coordinates (future UI)
       ↓
Provider calls ApiService.getTracePath(fromLat, fromLng, toLat, toLng)
       ↓
Backend computes path, returns TracePathModel
       ↓
Provider updates UI state with trace points for display
```

## Cross-Cutting Concerns

### Authentication

All API endpoints except `/api/login`, `/api/register`, and `/api/health` require a `Bearer` token in the `Authorization` header. `ApiService._addAuthHeaders()` injects the token from `StorageService`. The token is set on login and cleared on logout.

### Error Handling

`ApiService` catches all `DioException` instances and re-throws them as `ApiException` with user-friendly messages and HTTP status codes. The UI layer (auth screens) reads `ApiException.message` and displays it to the user. Error handling is consistent across all API calls.

### Theming

The app supports light and dark themes via `AppTheme.lightTheme` and `AppTheme.darkTheme`. The user's preference is persisted in `StorageService` and restored on app launch via `ThemeNotifier`. Theme changes are reactive through `ThemeProvider`.

### Validation

Form validation is centralized in `Validators` with regex-based email validation, minimum-length password validation, and URL validation. All validation follows the Flutter convention of returning `null` for valid input and a `String` error message for invalid input.

### Local Storage

`StorageService` persists API URL, auth token, user email, and theme mode using `SharedPreferences`. It is initialized in `main()` before the app runs and accessed throughout the app via Riverpod providers.

## Quality Attributes

### Performance

- API timeouts are conservative (15s connect, 30s receive) to handle slow network conditions.
- The app uses `StatelessWidget` for most UI components, avoiding unnecessary rebuilds.
- No caching layer exists — each API call fetches fresh data from the backend.

### Reliability

- `ApiService` provides structured error handling for all network failures.
- The auth flow gracefully handles disabled accounts, invalid credentials, and duplicate registrations.
- No offline support — the app requires an active network connection for all operations.

### Scalability

- The provider-based architecture (`providers.dart`) supports adding new features with their own providers and notifiers.
- The data layer's model serialization pattern (`toJson`, `toCreateJson`, `toUpdateJson`) scales well as the API grows.
- The repository pattern for auth is not extended to other endpoints — this is a gap that will need addressing as the app grows.

## Known Technical Debt

- **Missing repository abstraction** — Only `AuthRepository` exists; other API endpoints are called directly from UI/future providers.
- **Hardcoded storage keys** — `StorageService` duplicates the keys defined in `AppConstants`.
- **No logout UI** — `AuthNotifier.logout()` exists but no screen exposes it.
- **Placeholder map screen** — `MapScreen` is a static placeholder; actual mapping functionality is not implemented.
- **No API client tests** — `ApiService` has no unit or integration tests.
- **No provider tests** — `AuthNotifier`, `ThemeNotifier`, and the provider chain are untested.
- **Fragile theme mode storage** — Theme is stored as an integer index into `ThemeMode.values`, which breaks if Flutter adds new modes.

# Architecture Overview

**Type:** Explanation — this doc provides a system-level map of HelixTrace using C4 model concepts.

## System Context

HelixTrace is a mobile application for network mapping and tracing. It allows users to create accounts, authenticate, manage geographic points (markers with location, elevation, and categorization), and analyze line-of-sight visibility between points on an interactive map. The app communicates with a backend API that handles authentication, point storage, trace path computation, and elevation data.

### Actors

- **Registered user** — Creates an account, logs in, manages points, views network maps, analyzes line-of-sight between points.
- **HelixTrace Backend API** — External system that provides authentication, data storage, trace computation, and elevation data.

### External Systems

| System | Role | Criticality |
|---|---|---|
| HelixTrace Backend API (`trace-api.meshcore.bg`) | Authentication, point CRUD, trace paths, elevation data, categories | Critical — app is unusable without it |
| OpenStreetMap / Tile providers | Map tile rendering (OSM, OpenTopoMap, Stamen, ESRI, CartoDB) | Critical — map display requires tiles |
| Device location services | Provides user location for map centering | Useful — app falls back to Sofia, Bulgaria |

## Containers

The system consists of two containers:

| Container | Technology | Responsibility |
|---|---|---|
| HelixTrace Mobile App | Flutter (Dart), iOS + Android | UI, navigation, local state, API client, map rendering, LOS analysis |
| HelixTrace Backend API | Unknown (hosted at `trace-api.meshcore.bg`) | Authentication, data persistence, trace computation, elevation lookup |

## Components

### App Entry & Routing

Entry point (`lib/main.dart`), `GoRouter` navigation configuration, `AuthenticationShell` with session restoration that guards authenticated routes.

→ [Full documentation](app-entry-routing.md)

### Authentication

Login and registration screens (`lib/features/auth/`), `AuthNotifier` state machine with session restoration, `AuthRepository` that orchestrates HTTP calls, token validation, and local storage.

→ [Full documentation](authentication.md)

### Data Layer

`ApiService` (Dio HTTP client with auth interceptor), `AuthService` (response parsing + token validation), `AuthRepository` (service + storage), and data models (`AuthResponse`, `PointModel`, `TracePathModel`, `ElevationModel`, `PointCategory`, LOS models).

→ [Full documentation](data-layer.md)

### State Management

Riverpod providers (`lib/features/auth/providers/providers.dart`, `lib/features/home/providers/points_provider.dart`), `AuthNotifier`/`AuthState` with session restoration, `ThemeNotifier`/`ThemeProvider`, `PointsNotifier`/`PointsState`, and the dependency injection chain.

→ [Full documentation](state-management.md)

### Core Infrastructure

Shared utilities: `StorageService` (SharedPreferences including map layer persistence), `AppTheme` (light/dark themes), `Validators` (form validation), `AppConstants` (string keys), `SleekButton` and `SleekTextField` (reusable widgets).

→ [Full documentation](core-infrastructure.md)

### Map Screen

Interactive map display (`lib/features/home/map_screen.dart`) with FlutterMap, point markers with category-based colors, line-of-sight analysis mode, terrain elevation graph visualization, multiple tile layer support with persistence, slide-out user menu with logout, and device location integration.

→ [Full documentation](map-screen.md)

### LOS Analysis

Line-of-sight computation model (`lib/data/models/los_model.dart`) with Earth curvature correction, terrain graph data generation, visibility classification, and `TerrainGraphPainter` (`lib/features/home/widgets/terrain_graph_painter.dart`) for elevation profile rendering.

→ [Full documentation](los-analysis.md)

## Data Flow

### Authentication Flow (with Session Restoration)

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
Shell shows MapScreen (authenticated) or LoginScreen (initial)
```

### Login Flow

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
AuthRepository validates token (GET /api/points)
AuthRepository saves token + email to StorageService
       ↓
AuthNotifier sets state = AuthState.authenticated(user)
       ↓
LoginScreen navigates to /home via context.go()
```

### Point Fetching Flow

```
MapScreen.initState() → _fetchPoints()
       ↓
PointsNotifier.fetchPoints()
       ↓
ApiService.getPoints(includePublic: true, includeMeshcoreDashboard: true) → GET /api/points
       ↓
Backend returns list of point objects
       ↓
PointsNotifier parses into List<PointModel>
PointsNotifier sets state = PointsState.loaded(points)
       ↓
MapScreen watches pointsProvider → renders MarkerLayer
```

### LOS Analysis Flow

```
User toggles LOS mode → selects 2-3 points on map
       ↓
_fetchTraceResults() computes point pairs
       ↓
For each pair: ApiService.getTracePath(from, to) → GET /api/trace-path
       ↓
Response parsed into TraceData
       ↓
computeLOSStatus() checks terrain against LOS line (with curvature correction)
       ↓
computeGraphData() generates SVG paths for terrain, LOS line, blocked/clear segments
       ↓
MapScreen renders polylines on map + DraggableScrollableSheet with TerrainGraphPainter
```

### Theme Persistence Flow

```
User toggles theme → ThemeNotifier.toggleTheme()
       ↓
State = new ThemeMode
StorageService.setThemeMode(newMode) → persists index
       ↓
HelixTraceApp watches themeProvider → MaterialApp.themeMode updates
```

## Cross-Cutting Concerns

### Authentication

All API endpoints except `/api/login`, `/api/register`, and `/api/health` require a `Bearer` token in the `Authorization` header. A Dio `InterceptorsWrapper` in `ApiService` automatically injects the token from `StorageService` for non-public endpoints. The token is set on login, validated on register, and validated again on app startup via session restoration.

### Error Handling

`ApiService` catches all `DioException` instances and re-throws them as `ApiException` with user-friendly messages and HTTP status codes. The UI layer (auth screens, map screen) reads `ApiException.message` and displays it to the user. For LOS analysis, failed trace requests produce `LOSStatus.unknown` results rather than blocking the UI.

### Theming

The app supports light and dark themes via `AppTheme.lightTheme` and `AppTheme.darkTheme`. The user's preference is persisted in `StorageService` and restored on app launch via `ThemeNotifier`. Theme changes are reactive through `ThemeProvider`. The map screen's CartoDB tile layer also adapts to the current theme (dark vs. light tiles).

### Validation

Form validation is centralized in `Validators` with regex-based email validation, minimum-length password validation, and URL validation. All validation follows the Flutter convention of returning `null` for valid input and a `String` error message for invalid input.

### Local Storage

`StorageService` persists API URL, auth token, user email, theme mode, and map layer preference using `SharedPreferences`. It is initialized in `main()` before the app runs and accessed throughout the app via Riverpod providers or direct singleton access.

### Session Restoration

On app startup, the `AuthenticationShell` triggers `AuthNotifier.init()` which validates the stored token against the API. This prevents showing the login screen to already-authenticated users. A loading spinner is shown during validation.

## Quality Attributes

### Performance

- API timeouts are conservative (15s connect, 30s receive) to handle slow network conditions.
- The app uses `StatelessWidget` for most UI components, avoiding unnecessary rebuilds.
- LOS trace requests for multiple point pairs are made sequentially (not in parallel), which keeps the logic simple but increases latency for 3-point analysis.
- No caching layer exists — each API call fetches fresh data from the backend.

### Reliability

- `ApiService` provides structured error handling for all network failures.
- The auth flow gracefully handles disabled accounts, invalid credentials, and duplicate registrations.
- Failed LOS trace requests fall back to `LOSStatus.unknown` rather than crashing.
- No offline support — the app requires an active network connection for all operations.
- Session restoration validates the stored token on every app start, clearing stale credentials automatically.

### Scalability

- The provider-based architecture (`providers.dart`) supports adding new features with their own providers and notifiers (e.g., `pointsProvider` was added for the map feature).
- The data layer's model serialization pattern (`toJson`, `toCreateJson`, `toUpdateJson`) scales well as the API grows.
- The repository pattern for auth is not extended to other endpoints — this is a gap that will need addressing as the app grows.
- The map screen directly calls `ApiService` for LOS and elevation operations without a repository abstraction, creating coupling.

## Known Technical Debt

- **Missing repository abstraction** — Only `AuthRepository` exists; other API endpoints are called directly from UI code or `PointsNotifier`. The map screen calls `ApiService` directly for LOS operations.
- **Hardcoded storage keys** — `StorageService` duplicates the keys defined in `AppConstants`.
- **No API client tests** — `ApiService` has no unit or integration tests.
- **No provider tests** — `AuthNotifier`, `ThemeNotifier`, `PointsNotifier`, and the provider chain are untested.
- **Fragile theme mode storage** — Theme is stored as an integer index into `ThemeMode.values`, which breaks if Flutter adds new modes.
- **Raw response type from ApiService** — `ApiService` methods return `Response` rather than typed model objects, pushing response parsing into callers.
- **Duplicate providers in auth_provider.dart** — `authRepositoryProvider` and `authProvider` are declared in both `auth_provider.dart` (throwing `UnimplementedError` for testing) and `providers.dart` (production). This can cause confusion.
- **Direct API access from MapScreen** — The map screen calls `ApiService` directly for LOS trace paths and point info, bypassing any repository or provider layer.
- **Debug print statements in PointsNotifier** — `debugPrint` calls exist in `fetchPoints()` that should be replaced with a proper logging framework.
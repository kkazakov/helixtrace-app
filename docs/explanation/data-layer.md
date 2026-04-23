# Data Layer

**Type:** Explanation — this doc describes the data layer: HTTP communication, services, repositories, and data models.

## Responsibility

The data layer handles all communication with the HelixTrace backend API and represents the data structures exchanged with it. It provides a clean separation between raw HTTP operations and business logic, with models as immutable data transfer objects (DTOs). If this component fails, the app cannot authenticate, fetch data, or interact with the backend.

## Public Interface

### API Service

`ApiService` (`lib/data/services/api_service.dart:5`) is the public HTTP client. All API calls go through its methods:

| Method | HTTP | Endpoint | Purpose |
|---|---|---|---|
| `login()` | POST | `/api/login` | User authentication |
| `register()` | POST | `/api/register` | Account creation |
| `getProfile()` | GET | `/api/profile` | Fetch authenticated user profile |
| `getTracePath()` | GET | `/api/trace-path` | Compute trace path between two coordinates (takes `from` and `to` as coordinate strings) |
| `getPoints()` | GET | `/api/points` | List points (supports `includePublic` and `includeMeshcoreDashboard` query params) |
| `createPoint()` | POST | `/api/point` | Create a new geographic point |
| `getPoint()` | GET | `/api/point/:id` | Fetch a single point by ID |
| `updatePoint()` | PUT | `/api/point/:id` | Update an existing point |
| `deletePoint()` | DELETE | `/api/point/:id` | Delete a point |
| `getPointInfo()` | GET | `/api/point/info` | Fetch elevation info for a lat/lon |
| `getPointCategories()` | GET | `/api/point-categories` | Fetch available point categories |
| `healthCheck()` | GET | `/api/health` | Ping API health status |

### Auth Service

`AuthService` (`lib/data/services/auth_service.dart:4`) is a thin adapter that calls `ApiService` and parses raw JSON responses into `AuthResponse` models. It also includes:

| Method | Purpose |
|---|---|
| `login(email, password)` | Authenticates and returns `AuthResponse` |
| `register(email, password)` | Registers and returns `AuthResponse` |
| `validateToken()` | Validates stored token by calling GET `/api/points` |

### Auth Repository

`AuthRepository` (`lib/data/repositories/auth_repository.dart:5`) combines `AuthService` and `StorageService` to provide the full auth lifecycle:

| Method | Behavior |
|---|---|
| `login(email, password)` | Calls `AuthService.login()`, persists token + email, validates token, returns `AuthResponse` |
| `register(email, password)` | Calls `AuthService.register()`, persists token + email, validates token, returns `AuthResponse` |
| `logout()` | Clears token + email from `StorageService` |
| `restoreSession()` | Validates stored token against API, returns `true` if valid; clears storage and returns `false` if invalid |
| `isAuthenticated` | Returns `true` if a stored token exists |
| `currentUserEmail` | Returns the stored email, or `null` |
| `currentToken` | Returns the stored token, or `null` |

## Internal Structure

### HTTP Client Configuration

`ApiService` wraps `Dio` with the following configuration (`lib/data/services/api_service.dart:14-21`):

- **Base URL** — Sourced from constructor `customBaseUrl` parameter, falls back to `dotenv.env['BASE_URL']`, then to `AppConfig.defaultBaseUrl` (`'https://trace-api.meshcore.bg/'`).
- **Content type** — `application/json; charset=utf-8` set via `BaseOptions`.
- **Timeouts** — Connect timeout: 15 seconds, receive timeout: 30 seconds.
- **Auth interceptor** — A `Dio` interceptor (`InterceptorsWrapper`) automatically injects `Authorization: Bearer <token>` for all non-public endpoints. Public endpoints (`/api/login`, `/api/register`, `/api/health`) skip the token header.

### Error Handling

Every `ApiService` method follows the same pattern:

1. Wrap the Dio call in a `try/catch`.
2. On `DioException`, extract the status code and message.
3. Map known status codes to user-friendly messages (e.g., `403` → "Account is disabled").
4. Re-throw as `ApiException` with the message and optional status code.

`ApiException` (`lib/data/services/api_service.dart:225`) is a simple data class with `message` (String) and `statusCode` (int?).

### Model Serialization

All models are immutable (`final` fields) with factory `fromJson()` constructors and `toJson()` methods. Operation-specific serialization is used where appropriate:

- **`PointModel`** has three serialization methods:
  - `toJson()` — Full serialization including `id` (for GET responses).
  - `toCreateJson()` — Omits `id` (for POST `/api/point`).
  - `toUpdateJson()` — Only includes mutable fields `label` and `public` (for PUT `/api/point/:id`).

## Dependencies

### Internal Dependencies

- **Storage** (`lib/core/storage/storage_service.dart`) — `ApiService` reads the API URL from storage and injects auth tokens via interceptor.
- **Constants** (`lib/core/constants/app_constants.dart`) — Defines the `'api_url'` storage key.

### External Dependencies

- **HelixTrace Backend API** — `https://trace-api.meshcore.bg/` — the primary external dependency.
- `Dio` — HTTP client library.
- `flutter_dotenv` — Environment variable loading for API URL.

## Data Models

### `AuthResponse` (`lib/data/models/auth_response.dart`)

| Field | Type | Description |
|---|---|---|
| `token` | `String` | Bearer token for authenticated requests |
| `email` | `String` | User's email address |
| `username` | `String` | User's display name |

### `PointModel` (`lib/data/models/point_model.dart`)

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique identifier |
| `lat` | `double` | Latitude |
| `lon` | `double` | Longitude |
| `elevation` | `double` | Elevation at this point |
| `public` | `bool` | Public visibility flag |
| `label` | `String?` | Optional human-readable label |
| `categoryId` | `int` | Foreign key to `PointCategory` |
| `user` | `String?` | Owning user |

### `TracePathModel` (`lib/data/models/trace_path_model.dart`)

| Field | Type | Description |
|---|---|---|
| `points` | `List<TracePathPoint>` | Ordered trace points |
| `count` | `int` | Total point count |
| `distanceBetweenPoints` | `double` | Spacing between consecutive points |
| `status` | `String` | Processing status indicator |

### `TracePathPoint` (`lib/data/models/trace_path_model.dart`)

| Field | Type | Description |
|---|---|---|
| `lat` | `double` | Latitude |
| `lng` | `double` | Longitude |
| `elv` | `double` | Elevation |

### `ElevationModel` (`lib/data/models/elevation_model.dart`)

| Field | Type | Description |
|---|---|---|
| `lat` | `double` | Latitude |
| `lon` | `double` | Longitude |
| `elevation` | `double` | Elevation value |

Parsed from `data` sub-object: `json['data']['elevation']`.

### `PointCategory` (`lib/data/models/point_category.dart`)

| Field | Type | Description |
|---|---|---|
| `id` | `int` | Category identifier |
| `name` | `String` | Human-readable name |

### LOS Models (`lib/data/models/los_model.dart`)

See [LOS Analysis](los-analysis.md) for full documentation of `TracePoint`, `TraceData`, `TraceResult`, `LOSStatus`, `GraphData`, and the computation functions.

## Key Logic

### Trace path computation

`getTracePath()` (`lib/data/services/api_service.dart:97`) takes `from` and `to` as coordinate strings (e.g., `"42.6977,23.3219"`) and returns the raw API response. The map screen parses this into `TraceData` and computes LOS status.

### Point filtering

`getPoints()` (`lib/data/services/api_service.dart:115`) takes `includePublic` and `includeMeshcoreDashboard` boolean parameters, which are sent as `include_public` and `include_meshcore_dashboard` query parameters.

### Operation-specific serialization

`PointModel.toUpdateJson()` (`lib/data/models/point_model.dart:57`) only sends `label` and `public` fields, avoiding accidental transmission of immutable fields like `id`, `lat`, `lon`, and `elevation`.

### Token validation

`AuthService.validateToken()` (`lib/data/services/auth_service.dart:37`) validates the stored auth token by calling GET `/api/points`. A successful response (200) means the token is valid.

### Session restoration

`AuthRepository.restoreSession()` (`lib/data/repositories/auth_repository.dart:50`) checks for a stored token and email, then validates the token via `AuthService.validateToken()`. If the token is invalid, it calls `logout()` to clear storage and returns `false`.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| `API_BASE_URL` | Constructor param / `.env` / `AppConfig.defaultBaseUrl` | Backend API endpoint |
| Connect timeout | Hardcoded: 15s | Dio connection timeout |
| Receive timeout | Hardcoded: 30s | Dio response receive timeout |

## Design Decisions & Trade-offs

### Dio interceptor for auth headers

Auth headers are injected via a Dio `InterceptorsWrapper` that checks each request path against a list of public endpoints (`/api/login`, `/api/register`, `/api/health`). Non-public requests receive the stored Bearer token. This centralizes auth logic but means the interceptor runs on every request.

### No repository abstraction for non-auth endpoints

Only `AuthRepository` exists as a repository layer. All other API endpoints (points, trace paths, categories) are called directly from `ApiService` by UI code or providers. This works for the current scope but will need abstraction as the app grows.

### Immutable models with separate serialization methods

`PointModel`'s three serialization methods (`toJson`, `toCreateJson`, `toUpdateJson`) ensure that each HTTP operation sends the correct fields. This is more explicit than optional fields but adds boilerplate.

### ApiException over DioException in UI

The UI layer never sees `DioException` directly — it always receives `ApiException` with user-friendly messages. This keeps error handling consistent across all API calls.

### Raw Response return type

`ApiService` methods return `Response` rather than typed model objects. This means callers must parse the response data themselves (e.g., casting `response.data` to `Map<String, dynamic>`). This was a deliberate choice to keep `ApiService` simple, but it pushes parsing logic into consumers.

### Parallel LOS and TraceData models

The LOS feature introduced `TraceData`/`TracePoint` alongside the existing `TracePathModel`/`TracePathPoint`. Both represent similar trace path data but serve different purposes: `TracePathModel` is the API serialization model, while `TraceData` is an immutable computation model for LOS analysis.

## Testing

- No tests exist for `ApiService`, `AuthService`, `AuthRepository`, or any data models.
- To run existing tests: `flutter test`

## Related Components

- [State Management](state-management.md) — Providers consume `ApiService` and models to drive the UI.
- [Authentication](authentication.md) — `AuthRepository` is the bridge between the data layer and the auth feature.
- [LOS Analysis](los-analysis.md) — Uses `ApiService.getTracePath()` and `getPointInfo()`.
- [Map Screen](map-screen.md) — Consumes point and trace path data via `ApiService`.
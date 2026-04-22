# Data Layer

**Type:** Explanation — this doc describes the data layer: HTTP communication, services, repositories, and data models.

## Responsibility

The data layer handles all communication with the HelixTrace backend API and represents the data structures exchanged with it. It provides a clean separation between raw HTTP operations and business logic, with models as immutable data transfer objects (DTOs). If this component fails, the app cannot authenticate, fetch data, or interact with the backend.

## Public Interface

### API Service

`ApiService` (`lib/data/services/api_service.dart:16`) is the public HTTP client. All authenticated API calls go through its methods:

| Method | HTTP | Endpoint | Purpose |
|---|---|---|---|
| `login()` | POST | `/api/login` | User authentication |
| `register()` | POST | `/api/register` | Account creation |
| `getProfile()` | GET | `/api/profile` | Fetch authenticated user profile |
| `getTracePath()` | GET | `/api/trace-path` | Compute trace path between two coordinates |
| `getPoints()` | GET | `/api/points` | List user's points (supports `public` and `meshcore` query params) |
| `createPoint()` | POST | `/api/point` | Create a new geographic point |
| `getPoint()` | GET | `/api/point/:id` | Fetch a single point by ID |
| `updatePoint()` | PUT | `/api/point/:id` | Update an existing point |
| `deletePoint()` | DELETE | `/api/point/:id` | Delete a point |
| `getPointInfo()` | GET | `/api/point/info` | Fetch elevation info for lat/lon |
| `getPointCategories()` | GET | `/api/point-categories` | Fetch available point categories |
| `healthCheck()` | GET | `/api/health` | Ping API health status |

### Auth Service

`AuthService` (`lib/data/services/auth_service.dart:10`) is a thin adapter that calls `ApiService` and parses raw JSON responses into `AuthResponse` models.

### Auth Repository

`AuthRepository` (`lib/data/repositories/auth_repository.dart:9`) combines `AuthService` and `StorageService` to provide the full auth lifecycle: login, register, logout, and auth state checks.

## Internal Structure

### HTTP Client Configuration

`ApiService` wraps `Dio` with the following configuration (`lib/data/services/api_service.dart:21-26`):

- **Base URL** — Sourced from `flutter_dotenv` (`API_BASE_URL`), falls back to `AppConfig.defaultBaseUrl` (`'https://trace-api.meshcore.bg/'`).
- **Content type** — `application/json; charset=utf-8` set via `Options.headers`.
- **Timeouts** — Connect timeout: 15 seconds, receive timeout: 30 seconds.
- **Auth header** — All authenticated methods include `Authorization: Bearer <token>` via `_addAuthHeaders()`.

### Error Handling

Every `ApiService` method follows the same error handling pattern:

1. Wrap the Dio call in a `try/catch`.
2. On `DioException`, extract the status code and message.
3. Map known status codes to user-friendly messages (e.g., `403` → "Account is disabled").
4. Re-throw as `ApiException` with the message and optional status code.

`ApiException` (`lib/data/services/api_service.dart:228`) is a simple data class with `message` (String) and `statusCode` (int?).

### Model Serialization

All models are immutable (`final` fields) with factory `fromJson()` constructors and `toJson()` methods. Operation-specific serialization is used where appropriate:

- **`PointModel`** has three serialization methods:
  - `toJson()` — Full serialization including `id` (for GET responses).
  - `toCreateJson()` — Omits `id` (for POST `/api/point`).
  - `toUpdateJson()` — Only includes mutable fields `label` and `public` (for PUT `/api/point/:id`).

## Dependencies

### Internal Dependencies

- **Storage** (`lib/core/storage/storage_service.dart`) — `ApiService` reads the API URL from storage; `AuthRepository` reads/writes auth tokens.
- **Constants** (`lib/core/constants/app_constants.dart`) — Defines the `'api_url'` storage key.

### External Dependencies

- **HelixTrace Backend API** — `https://trace-api.meshcore.bg/` — the primary external dependency.
- `Dio` — HTTP client library.
- `flutter_dotenv` — Environment variable loading for API URL.

## Data Models

### `AuthResponse` (`lib/data/models/auth_response.dart`)

| Field | Type | Description |
|---|---|---|
| `token` | `String` | Bearer token |
| `email` | `String` | User email |
| `username` | `String` | Display name |

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

### `PointCategory` (`lib/data/models/point_category.dart`)

| Field | Type | Description |
|---|---|---|
| `id` | `int` | Category identifier |
| `name` | `String` | Human-readable name |

## Key Logic

### Trace path computation

`getTracePath()` (`lib/data/services/api_service.dart:89-105`) takes `fromLat`, `fromLng`, `toLat`, `toLng` as query parameters and returns a `TracePathModel`. The backend computes the path; the app only handles display.

### Point filtering

`getPoints()` (`lib/data/services/api_service.dart:107-126`) supports optional `public` and `meshcore` boolean query parameters to filter points. This suggests the backend supports both user-private and shared/public points.

### Operation-specific serialization

`PointModel.toUpdateJson()` (`lib/data/models/point_model.dart:55-58`) only sends `label` and `public` fields, avoiding accidental transmission of immutable fields like `id`, `lat`, `lon`, and `elevation`. This is a deliberate design choice to minimize the update payload.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| `API_BASE_URL` | `.env` / `StorageService` | Backend API endpoint |
| Connect timeout | Hardcoded: 15s | Dio connection timeout |
| Receive timeout | Hardcoded: 30s | Dio response receive timeout |

## Design Decisions & Trade-offs

### No repository abstraction for non-auth endpoints

Only `AuthRepository` exists as a repository layer. All other API endpoints (points, trace paths, categories) are called directly from `ApiService` by UI components or future providers. This works for the current scope but will need abstraction as the points/tracing features grow.

### Immutable models with separate serialization methods

`PointModel`'s three serialization methods (`toJson`, `toCreateJson`, `toUpdateJson`) ensure that each HTTP operation sends the correct fields. This is more explicit than using optional fields but adds boilerplate.

### ApiException over DioException in UI

The UI layer never sees `DioException` directly — it always receives `ApiException` with user-friendly messages. This keeps error handling consistent across all API calls.

### Hardcoded timeouts

Dio timeouts are hardcoded in `ApiService` rather than being configurable. This is simple but makes it harder to tune for different network conditions without code changes.

## Testing

- No tests exist for `ApiService`, `AuthService`, `AuthRepository`, or any data models.
- To run existing tests: `flutter test`

## Related Components

- [State Management](state-management.md) — Providers consume `ApiService` and models to drive the UI.
- [Authentication](authentication.md) — `AuthRepository` is the bridge between the data layer and the auth feature.

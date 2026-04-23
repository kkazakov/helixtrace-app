# Map Screen

**Type:** Explanation — this doc describes the map screen: interactive map display, point markers, line-of-sight analysis mode, slide-out menu, and location services.

## Responsibility

The map screen is the primary authenticated view of HelixTrace. It renders an interactive map with geographic point markers, supports switching between multiple tile layers, provides a line-of-sight (LOS) analysis mode for computing visibility between points, and displays terrain elevation graphs. It also provides navigation via a slide-out menu with user identity and logout. If this component fails, authenticated users cannot interact with their network data.

## Public Interface

- **`MapScreen`** (`lib/features/home/map_screen.dart:72`) — `ConsumerStatefulWidget` that renders the full map experience. It is the target of the `/home` route.

## Internal Structure

### Map Display

The map uses `FlutterMap` (`flutter_map` package) with a `MapController` for programmatic control. The default center is Sofia, Bulgaria (`42.6977, 23.3219`) at zoom level 13. On initialization, the screen requests the user's device location via `Geolocator` and moves the map viewport there. If location permission is denied or location services are disabled, the map stays centered on Sofia.

### Tile Layers

The screen supports five map tile sources via the `MapLayer` enum (`lib/features/home/map_screen.dart:59`):

| Layer | Key | Tile URL | Notes |
|---|---|---|---|
| OpenStreetMap | `osm` | `tile.openstreetmap.org` | Default |
| OpenTopoMap | `opentopomap` | `tile.opentopomap.org` | Topographic maps |
| Stamen Terrain | `stamenterrain` | `tiles.stadiamaps.com` | Terrain relief |
| ESRI Satellite | `esri` | `server.arcgisonline.com` | Satellite imagery |
| CartoDB | `cartodb` | `basemaps.cartocdn.com` | Light/dark variant auto-selected by theme |

The selected layer persists in `StorageService` under the key `'map_layer'` and is restored on app launch via `_loadSavedLayer()`.

### Point Markers

Points are fetched from the API via `PointsNotifier.fetchPoints()` and rendered as a `MarkerLayer`. Each point displays as a colored circle with an inner dot — rendered by `_MarkerPainter` (`lib/features/home/map_screen.dart:1225`), a `CustomPainter` that draws a shadow disc, a colored fill, a white stroke ring, and a white inner dot.

Marker colors are determined by category ID and visibility:

| Category ID | Public Color | Private Color |
|---|---|---|
| 1 | `#1976d2` (blue) | `#7b1fa2` (purple) |
| 2 | `#2e7d32` (green) | `#d32f2f` (red) |
| 3 | `#f9a825` (amber) | `#ef6c00` (orange) |

Points with unrecognized category IDs default to `#f9a825` (amber).

Tapping a point marker outside LOS mode opens a modal bottom sheet showing point details (ID, coordinates, elevation, category, visibility, owner).

### Line-of-Sight Mode

The LOS analysis mode (toggled by the eye icon button) lets users select 2–3 points on the map and compute visibility between them. See [LOS Analysis](los-analysis.md) for the full algorithm and data model.

**Selection behavior:**
- Tapping an existing point marker selects it for LOS analysis
- Tapping empty map space creates a temporary marker at that position
- Tapping an already-selected point or temporary marker deselects it
- Temporary markers support long-press drag to reposition
- Maximum of 3 points can be selected simultaneously

**Visual feedback:**
- Selected markers change to black (`_losSelectedMarkerColor`)
- Temporary markers are black by default (`_losTempMarkerColor`)
- Lines between selected points are drawn as polylines with color-coding:
  - Green (`#2E7D32`) for clear LOS
  - Red (`#D32F2F`) for blocked LOS
  - Gray (`#9E9E9E`) for unknown/pending status
- Blocked lines use dashed strokes in 2-point mode; in 3-point mode, all lines are dashed if fewer than 2 are clear

**Bottom sheet:** When LOS mode is active and points are selected, a `DraggableScrollableSheet` appears showing selected point names and elevations, loading state, and terrain profile graph cards for each pair.

### Slide-Out Menu

A hamburger button in the top-left opens an animated slide-out menu (280px wide) with:
- A gradient header showing the user's email initial and full email
- A "Map" menu item (currently active)
- A "Logout" item that calls `authProvider.notifier.logout()` and navigates to the login route

The menu slides in from the left using an `AnimationController` with a 280ms `easeOutCubic` curve. An overlay scrim covers the map behind the menu; tapping the scrim closes the menu.

### Location Services

`_requestLocation()` (`lib/features/home/map_screen.dart:372`) uses `Geolocator` to:
1. Check if location services are enabled; if not, shows a dialog offering to open device settings
2. Request location permission if not yet granted
3. Move the map to the user's current position

If any step fails, the map silently stays centered on Sofia.

## Dependencies

### Internal Dependencies

- **Points provider** (`lib/features/home/providers/points_provider.dart`) — `pointsProvider` supplies the list of `PointModel` markers
- **Auth provider** (`lib/features/auth/providers/providers.dart`) — `authProvider` provides user identity for the menu header; `authProvider.notifier.logout()` for sign-out
- **API service** (`lib/data/services/api_service.dart`) — `getTracePath()`, `getPointInfo()` for LOS analysis
- **Storage** (`lib/core/storage/storage_service.dart`) — Persists map layer preference
- **LOS model** (`lib/data/models/los_model.dart`) — `TraceData`, `TraceResult`, `LOSStatus`, `computeLOSStatus()`, `computeGraphData()`
- **Terrain graph painter** (`lib/features/home/widgets/terrain_graph_painter.dart`) — `TerrainGraphPainter` for elevation profile rendering

### External Dependencies

- `flutter_map` — Map widget with tile layers, markers, polylines
- `latlong2` — `LatLng` coordinate type used by `flutter_map`
- `geolocator` — Device location services and permissions

## Data Model

The map screen does not own persistent data models. It manages local state for:
- `_selectedLayer` (`MapLayer`) — Current tile layer
- `_isMenuOpen` (`bool`) — Side menu state
- `_losMode` (`bool`) — Whether LOS analysis is active
- `_losPoints` (`List<_LosPoint>`) — Selected LOS analysis points
- `_traceResults` (`List<TraceResult>`) — Computed LOS results
- `_isLoadingTrace` (`bool`) — Trace computation loading state

### `_LosPoint` (private)

| Field | Type | Description |
|---|---|---|
| `name` | `String` | Display label |
| `position` | `LatLng` | Geographic coordinates |
| `elevation` | `double?` | Elevation in meters (null until fetched) |
| `isTemporary` | `bool` | True if placed by map tap (not from API point) |
| `color` | `Color` | Marker fill color |

### `_ColorPair` (private)

| Field | Type | Description |
|---|---|---|
| `public` | `String` | Hex color for public points |
| `private` | `String` | Hex color for private points |

## Key Logic

### Point fetching

`_fetchPoints()` (`lib/features/home/map_screen.dart:142`) calls `pointsProvider.notifier.fetchPoints()` on `initState`. The provider fetches from `ApiService.getPoints(includePublic: true, includeMeshcoreDashboard: true)`. The screen rebuilds reactively when `pointsProvider` changes.

### LOS trace computation

When 2 or 3 points are selected in LOS mode, `_fetchTraceResults()` (`lib/features/home/map_screen.dart:160`) computes all pairs (1 pair for 2 points, 3 pairs for 3 points). For each pair, it calls `ApiService.getTracePath()` with coordinate strings, parses the response into `TraceData`, computes the LOS status via `computeLOSStatus()`, and builds `TraceResult` objects. Failed trace requests produce `LOSStatus.unknown` results.

### Elevation fetching for map taps

When the user taps the map to create a temporary LOS point, the screen calls `ApiService.getPointInfo()` to fetch elevation data for that location. The response is parsed to extract the `elevation` value from either the `data` sub-object or the response root.

### Session restoration

The `AuthenticationShell` in `main.dart` calls `authProvider.notifier.init()` on startup. This checks for a stored token and validates it against the API. If valid, the user is authenticated and sees the map screen; otherwise, they see the login screen.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| Map center | Hardcoded: `LatLng(42.6977, 23.3219)` | Default map center (Sofia, Bulgaria) |
| Default zoom | Hardcoded: `13.0` | Initial zoom level |
| LOS max points | Hardcoded: `3` | Maximum points in LOS analysis |
| Layer preference | `StorageService` key `'map_layer'` | Persisted tile layer choice |
| Menu width | Hardcoded: `280.0` | Side menu width in pixels |

## Design Decisions & Trade-offs

### Direct API access from screen

The map screen calls `ApiService` directly via `ref.read(apiServiceProvider)` for LOS and elevation operations, bypassing the repository pattern. This keeps the screen self-contained for the current scope but should be refactored into a repository/provider layer as the feature grows.

### Temporary markers with server-side elevation

Temporary marker positions (created by map taps) start with null elevation and fetch it asynchronously from the API. This means the terrain graph cannot be computed until elevation data arrives. The UI shows "Fetching elevation..." in the interim.

### Black LOS markers over category-colored markers

When LOS mode is active, selected points are rendered in black regardless of their original category color. This provides visual distinction for analysis mode but loses category information during LOS selection.

### No point CRUD UI

While `ApiService` provides full CRUD for points (`createPoint`, `updatePoint`, `deletePoint`), the map screen only displays points and opens detail popups. There is no UI for creating, editing, or deleting points yet.

## Testing

- No dedicated tests exist for `MapScreen`, `_MarkerPainter`, or LOS analysis logic.
- The existing widget test only verifies app initialization, not map behavior.
- `PointsNotifier` and the LOS computation functions are untested.
- To run: `flutter test`

## Related Components

- [LOS Analysis](los-analysis.md) — LOS computation model, terrain graph, and visibility algorithm
- [Data Layer](data-layer.md) — `ApiService` methods for points, trace paths, and elevation
- [State Management](state-management.md) — `pointsProvider` for point state, `authProvider` for identity
- [App Entry & Routing](app-entry-routing.md) — Routes and authentication shell
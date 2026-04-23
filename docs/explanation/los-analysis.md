# LOS Analysis

**Type:** Explanation — this doc describes the line-of-sight analysis feature: the LOS computation model, terrain graph rendering, visibility algorithm, and supporting data structures.

## Responsibility

The LOS analysis feature computes whether two geographic points have unobstructed line-of-sight, accounting for terrain elevation and Earth's curvature. It provides the data model for trace path results, the algorithm for determining LOS status, and the graph data computation for terrain profile visualization. If this component fails, users cannot analyze visibility between network points.

## Public Interface

### Data Models (`lib/data/models/los_model.dart`)

| Class | Purpose |
|---|---|
| `LOSStatus` | Enum: `unknown`, `clear`, `blocked` — visibility result |
| `TracePoint` | Single point in a trace path (lat, lng, elv) |
| `TraceData` | Collection of trace points with count and distance metadata |
| `TraceResult` | Complete LOS result: trace data, elevations, labels, status |
| `GraphData` | Pre-computed SVG path data and scales for terrain graph rendering |

### Functions

| Function | Location | Purpose |
|---|---|---|
| `computeLOSStatus(TraceData, double, double)` | `los_model.dart:67` | Determines if LOS between two elevated points is clear or blocked |
| `computeGraphData(TraceData, double, double)` | `los_model.dart:224` | Produces `GraphData` with SVG paths, axes, and scaling for the terrain graph |
| `haversineDistance(double, double, double, double)` | `los_model.dart:56` | Computes great-circle distance between two coordinates |

### Widget

| Widget | Location | Purpose |
|---|---|---|
| `TerrainGraphPainter` | `lib/features/home/widgets/terrain_graph_painter.dart:4` | `CustomPainter` that renders terrain elevation profiles with LOS overlay |

## Internal Structure

### LOS Computation Algorithm

`computeLOSStatus()` (`lib/data/models/los_model.dart:67`) determines visibility between two elevated points:

1. Compute total distance between first and last trace points using `haversineDistance()`
2. Calculate cumulative distances for each trace point
3. Apply Earth curvature correction: each point's elevation is reduced by `(d * (totalDistance - d)) / (2 * R)` where `d` is distance from start and `R` is Earth's radius (6,371,000 m)
4. Normalize all elevations (terrain + endpoints) into a 0–100 range (innerHeight)
5. Compute a straight LOS line from the first point's elevation to the last point's elevation
6. For each intermediate terrain point, check if it is below the LOS line — if any point's terrain elevation is below the LOS line (i.e., `terrainYs[i] < losYAt(i)`), the LOS is **blocked**
7. If no terrain point obstructs the LOS line, the result is **clear**
8. If fewer than 2 trace points exist, the result is **unknown**

### Haversine Distance

`haversineDistance()` (`lib/data/models/los_model.dart:56`) implements the haversine formula for great-circle distance between two lat/lng coordinates. It returns distance in meters.

### Terrain Graph Data Computation

`computeGraphData()` (`lib/data/models/los_model.dart:224`) produces all the data needed by `TerrainGraphPainter`:

1. Define a fixed viewport: 320×160 pixels with padding (left: 36, top: 24, right: 24, bottom: 28)
2. Compute total trace path distance from point count and spacing
3. Build an SVG path string for the terrain elevation profile
4. Build an SVG path string for the LOS line (straight line from start to end elevation)
5. Call `_computeSegments()` to classify terrain regions as clear or blocked relative to the LOS line
6. Compute Y-axis tick marks (adaptive step: 200m, 100m, 50m, or 20m depending on range)
7. Compute X-axis tick marks with labels (km for distances ≥ 1km, m otherwise)
8. Return a `GraphData` object with all rendering data

### Segment Classification

`_computeSegments()` (`lib/data/models/los_model.dart:123`) divides the terrain into blocked and clear segments relative to the LOS line. For each segment, it generates SVG path strings:

- **Blocked segments**: terrain above the LOS line — rendered with red fill (`0x3FF44336`)
- **Clear segments**: terrain below the LOS line — rendered with green fill (`0x3F4CAF50`)

Each segment path forms a closed shape from terrain points down to the LOS line and back.

### Terrain Graph Rendering

`TerrainGraphPainter` (`lib/features/home/widgets/terrain_graph_painter.dart:4`) takes `GraphData` and renders:
- Y-axis grid lines and elevation labels
- X-axis grid lines and distance labels
- Clear segment fills (green, semi-transparent)
- Blocked segment fills (red, semi-transparent)
- Terrain elevation line (blue, `#2196F3`, 1.5px stroke)
- LOS line (red, `#D32F2F`, 1.5px stroke)
- From/to labels at the bottom
- LOS status label in the top-right corner, color-coded:
  - Green (`#4CAF50`) + "LOS: Clear"
  - Red (`#D32F2F`) + "LOS: Blocked"
  - Gray + "LOS: Unknown"

The painter scales `GraphData`'s fixed viewport (320×160) to the actual widget size.

## Dependencies

### Internal Dependencies

- **Map screen** (`lib/features/home/map_screen.dart`) — Consumes `TraceResult`, `computeLOSStatus()`, and `computeGraphData()` for LOS analysis; passes `GraphData` to `TerrainGraphPainter`

### External Dependencies

- `flutter` — `CustomPainter` for graph rendering
- `dart:math` — `min`/`max` for elevation range computation

## Data Models

### `LOSStatus` (`lib/data/models/los_model.dart:3`)

| Value | Meaning |
|---|---|
| `unknown` | Insufficient data to determine visibility |
| `clear` | LOS is unobstructed |
| `blocked` | Terrain obstructs the LOS line |

### `TracePoint` (`lib/data/models/los_model.dart:5`)

| Field | Type | Description |
|---|---|---|
| `lat` | `double` | Latitude |
| `lng` | `double` | Longitude |
| `elv` | `double` | Elevation in meters |

Created via `TracePoint.fromJson()` which parses `lat`, `lng`, `elv` from a JSON map.

### `TraceData` (`lib/data/models/los_model.dart:18`)

| Field | Type | Description |
|---|---|---|
| `points` | `List<TracePoint>` | Ordered trace points |
| `count` | `int` | Total number of points |
| `distanceBetweenPoints` | `double` | Distance between consecutive points in meters |

### `TraceResult` (`lib/data/models/los_model.dart:37`)

| Field | Type | Description |
|---|---|---|
| `traceData` | `TraceData` | The computed trace path |
| `fromElevation` | `double` | Elevation of the start point |
| `toElevation` | `double` | Elevation of the end point |
| `fromLabel` | `String` | Display name of the start point |
| `toLabel` | `String` | Display name of the end point |
| `losStatus` | `LOSStatus` | Computed visibility result |

### `GraphData` (`lib/data/models/los_model.dart:182`)

| Field | Type | Description |
|---|---|---|
| `terrainPath` | `String` | SVG path string for terrain elevation line |
| `losPath` | `String` | SVG path string for LOS line |
| `blockedPaths` | `List<String>` | SVG path strings for blocked terrain segments |
| `clearPaths` | `List<String>` | SVG path strings for clear terrain segments |
| `minElevation` | `double` | Y-axis minimum |
| `maxElevation` | `double` | Y-axis maximum |
| `xScale` | `double Function(double)` | Converts distance to X pixel coordinate |
| `yScale` | `double Function(double)` | Converts elevation to Y pixel coordinate |
| `yTicks` | `List<double>` | Y-axis tick elevation values |
| `xTicks` | `List<double>` | X-axis tick distance values |
| `xTickLabels` | `List<String>` | X-axis tick label strings |
| `totalDistance` | `double` | Total trace distance |
| `dimsLeft/Top/Width/Height` | `double` | Viewport dimensions |
| `innerWidth/innerHeight` | `double` | Inner graph area dimensions |

## Key Logic

### Relationship with TracePathModel

`TraceData` and `TracePathModel` (`lib/data/models/trace_path_model.dart`) both represent trace path data but serve different purposes:
- `TracePathModel` is the raw API response model with `fromJson()`/`toJson()` for network serialization
- `TraceData` is the LOS computation model with immutability (`const` constructor) and no serialization methods — it is created by parsing `TracePathModel` data in `TraceData.fromJson()`

The map screen parses API responses as `TraceData` (not `TracePathModel`) because the LOS computation functions operate on `TraceData`.

### Earth curvature correction

The LOS algorithm accounts for Earth's curvature by subtracting a curvature drop value from each terrain elevation. The drop at distance `d` from the transmitter is `d * (totalDistance - d) / (2R)`. This ensures that the LOS check is accurate for long-distance visibility analysis rather than using a flat-earth approximation.

### Failed traces produce unknown status

If `ApiService.getTracePath()` throws an exception for a given pair, the map screen creates a `TraceResult` with `LOSStatus.unknown` and an empty `TraceData`. This prevents the UI from displaying false clear/blocked results when network errors occur.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| Earth radius | Hardcoded: `6,371,000` meters | Haversine and curvature calculations |
| Graph viewport | Hardcoded: 320×160px with margins | Fixed-size terrain graph rendering |

## Design Decisions & Trade-offs

### Separate model from API model

`TraceData` is separate from `TracePathModel` because the LOS computation needs an immutable, const-constructible model without serialization. This duplication (similar fields: lat/lng/elv vs lat/lng/elevation) is intentional to keep the computation layer independent of the API layer.

### Fixed graph viewport

The terrain graph uses a fixed 320×160 pixel coordinate space that the painter scales to the actual widget size. This simplifies the graph computation but means the aspect ratio is fixed. Very wide or very narrow widgets may distort the graph.

### SVG path strings for segment fills

Blocked and clear regions are pre-computed as SVG path strings in `GraphData`. The painter parses these strings at render time. This approach decouples computation from rendering but adds parsing overhead per frame.

## Testing

- No tests exist for `computeLOSStatus()`, `computeGraphData()`, `haversineDistance()`, or `TerrainGraphPainter`.
- The LOS algorithm would benefit from unit tests with known geographic inputs and expected clear/blocked results.
- To run: `flutter test`

## Related Components

- [Map Screen](map-screen.md) — UI layer that triggers LOS computation and renders results
- [Data Layer](data-layer.md) — `ApiService.getTracePath()` provides the raw trace data
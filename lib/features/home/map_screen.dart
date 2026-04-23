import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:helixtrace/core/constants/app_constants.dart';
import 'package:helixtrace/core/storage/storage_service.dart';
import 'package:helixtrace/data/models/los_model.dart';
import 'package:helixtrace/data/models/point_model.dart';
import 'package:helixtrace/features/auth/providers/auth_provider.dart' show AuthState;
import 'package:helixtrace/features/auth/providers/providers.dart';
import 'package:helixtrace/features/home/providers/points_provider.dart';
import 'package:helixtrace/features/home/widgets/terrain_graph_painter.dart';
import 'package:latlong2/latlong.dart';

const _categoryColors = <int, _ColorPair>{
  1: _ColorPair(public: '#1976d2', private: '#7b1fa2'),
  2: _ColorPair(public: '#2e7d32', private: '#d32f2f'),
  3: _ColorPair(public: '#f9a825', private: '#ef6c00'),
};

const _losTempMarkerColor = Color(0xFF000000);
const _losSelectedMarkerColor = Color(0xFF000000);
const _losLineColor = Color(0xFF9E9E9E);
const _losLineWidth = 3.0;
const _losClearColor = Color(0xFF2E7D32);
const _losBlockedColor = Color(0xFFD32F2F);

class _LosPoint {
  final String name;
  final LatLng position;
  final double? elevation;
  final bool isTemporary;
  final Color color;
  const _LosPoint({
    required this.name,
    required this.position,
    required this.elevation,
    required this.isTemporary,
    required this.color,
  });
}

class _ColorPair {
  final String public;
  final String private;
  const _ColorPair({required this.public, required this.private});
}

Color _markerColor(PointModel point) {
  final pair = _categoryColors[point.categoryId];
  if (pair == null) return const Color(0xFFF9A825);
  final hex = point.public ? pair.public : pair.private;
  return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
}

enum MapLayer {
  osm('osm', 'OpenStreetMap', Icons.map_outlined),
  opentopomap('opentopomap', 'OpenTopoMap', Icons.nature_outlined),
  stamenterrain('stamenterrain', 'Stamen Terrain', Icons.terrain_outlined),
  esri('esri', 'ESRI Satellite', Icons.satellite_alt_outlined),
  cartodb('cartodb', 'CartoDB', Icons.adjust_outlined);

  const MapLayer(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  static const _menuWidth = 280.0;
  static const _sofiaCenter = LatLng(42.6977, 23.3219);
  static const _defaultZoom = 13.0;
  static const _sheetMinHeight = 0.25;
  static const _sheetMaxHeight = 0.85;
  static const _maxLosPoints = 3;

  MapLayer _selectedLayer = MapLayer.osm;
  bool _isMenuOpen = false;
  bool _losMode = false;
  List<_LosPoint> _losPoints = [];
  int? _draggingIndex;
  List<TraceResult> _traceResults = [];
  bool _isLoadingTrace = false;

  late final MapController _mapController;
  final _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _mapController = MapController();

    _loadSavedLayer();
    _requestLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPoints());
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLayer() async {
    final storage = StorageService();
    final saved = storage.getMapLayer();
    if (saved != null) {
      final layer = MapLayer.values.firstWhere(
        (l) => l.key == saved,
        orElse: () => MapLayer.osm,
      );
      if (mounted) {
        setState(() => _selectedLayer = layer);
      }
    }
  }

  Future<void> _fetchPoints() async {
    await ref.read(pointsProvider.notifier).fetchPoints();
  }

  void _toggleLosMode() {
    setState(() {
      _losMode = !_losMode;
      if (!_losMode) {
        _losPoints = [];
        _traceResults = [];
        _isLoadingTrace = false;
      }
    });
    if (_losMode) {
      _showToast('Select 2 or 3 markers or tap on the map');
    }
  }

  Future<void> _fetchTraceResults() async {
    if (_losPoints.length < 2) {
      setState(() {
        _traceResults = [];
        _isLoadingTrace = false;
      });
      return;
    }

    setState(() => _isLoadingTrace = true);

    final apiService = ref.read(apiServiceProvider);
    final results = <TraceResult>[];

    final pairs = <(int, int)>[];
    if (_losPoints.length == 2) {
      pairs.add((0, 1));
    } else if (_losPoints.length == 3) {
      pairs.add((0, 1));
      pairs.add((1, 2));
      pairs.add((0, 2));
    }

    for (final (i, j) in pairs) {
      final from = _losPoints[i];
      final to = _losPoints[j];
      final fromElev = from.elevation ?? 0.0;
      final toElev = to.elevation ?? 0.0;

      try {
        final response = await apiService.getTracePath(
          from: '${from.position.latitude},${from.position.longitude}',
          to: '${to.position.latitude},${to.position.longitude}',
        );
        final body = response.data as Map<String, dynamic>;
        final traceData = TraceData.fromJson(body);
        final status = computeLOSStatus(traceData, fromElev, toElev);
        results.add(TraceResult(
          traceData: traceData,
          fromElevation: fromElev,
          toElevation: toElev,
          fromLabel: from.name,
          toLabel: to.name,
          losStatus: status,
        ));
      } catch (_) {
        results.add(TraceResult(
          traceData: TraceData(points: [], count: 0, distanceBetweenPoints: 0),
          fromElevation: fromElev,
          toElevation: toElev,
          fromLabel: from.name,
          toLabel: to.name,
          losStatus: LOSStatus.unknown,
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _traceResults = results;
      _isLoadingTrace = false;
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _onMapTapped(
    dynamic tapPosition,
    LatLng position,
  ) async {
    if (!_losMode) return;
    if (_losPoints.length >= _maxLosPoints) return;

    final existingIndex = _losPoints.indexWhere(
      (p) =>
          (p.position.latitude - position.latitude).abs() < 0.0001 &&
          (p.position.longitude - position.longitude).abs() < 0.0001,
    );

    if (existingIndex >= 0) {
      _deselectLosPointAt(existingIndex);
      return;
    }

    final allPoints = ref.read(pointsProvider).points;
    final existingMarker = allPoints.firstWhere(
      (p) => (p.lat - position.latitude).abs() < 0.0001 &&
          (p.lon - position.longitude).abs() < 0.0001,
      orElse: () => PointModel(
        id: '',
        lat: 0,
        lon: 0,
        elevation: 0,
        public: false,
        categoryId: 0,
      ),
    );

    if (existingMarker.id.isNotEmpty) {
      _selectExistingMarker(existingMarker);
      return;
    }

    final nextNum = _nextTempPointNumber();
    final name = 'Point $nextNum';

    setState(() {
      _losPoints.add(_LosPoint(
        name: name,
        position: position,
        elevation: null,
        isTemporary: true,
        color: _losTempMarkerColor,
      ));
    });

    final apiService = ref.read(apiServiceProvider);
    try {
      final response = await apiService.getPointInfo(
        lat: position.latitude,
        lon: position.longitude,
      );
      final body = response.data;
      double? elevation;
      if (body is Map<String, dynamic>) {
        final dataBlock = body['data'];
        if (dataBlock is Map<String, dynamic>) {
          elevation = (dataBlock['elevation'] as num?)?.toDouble();
        } else {
          elevation = (body['elevation'] as num?)?.toDouble();
        }
      }
      if (!mounted) return;
      setState(() {
        final idx = _losPoints.indexWhere(
          (p) => p.position.latitude == position.latitude &&
              p.position.longitude == position.longitude,
        );
        if (idx >= 0) {
          _losPoints[idx] = _LosPoint(
            name: name,
            position: position,
            elevation: elevation,
            isTemporary: true,
            color: _losTempMarkerColor,
          );
        }
      });
    } catch (_) {
      // elevation stays null for map tap
    }

    _fetchTraceResults();
  }

  void _selectExistingMarker(PointModel point) {
    final existingIndex = _losPoints.indexWhere(
      (p) =>
          (p.position.latitude - point.lat).abs() < 0.0001 &&
          (p.position.longitude - point.lon).abs() < 0.0001,
    );

    if (existingIndex >= 0) {
      _deselectLosPointAt(existingIndex);
      return;
    }

    if (_losPoints.length >= _maxLosPoints) return;

    setState(() {
      _losPoints.add(_LosPoint(
        name: point.label ?? 'Unnamed',
        position: LatLng(point.lat, point.lon),
        elevation: point.elevation,
        isTemporary: false,
        color: _markerColor(point),
      ));
    });

    _fetchTraceResults();
  }

  int _nextTempPointNumber() {
    final usedNumbers = _losPoints
        .where((p) => p.isTemporary)
        .map((p) {
          final match = RegExp(r'Point (\d+)').firstMatch(p.name);
          return match != null ? int.parse(match.group(1)!) : 0;
        })
        .toSet();
    int n = 1;
    while (usedNumbers.contains(n)) {
      n++;
    }
    return n;
  }

  void _deselectLosPointAt(int index) {
    setState(() {
      _losPoints.removeAt(index);
      _traceResults = [];
    });
    _fetchTraceResults();
  }

  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                'Please enable location services to center the map on your current position. '
                'Otherwise, the map will show Sofia, Bulgaria.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (shouldOpen == true) {
            await Geolocator.openLocationSettings();
            serviceEnabled = await Geolocator.isLocationServiceEnabled();
          }
          if (!serviceEnabled) {
            return;
          }
        } else {
          return;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _defaultZoom,
        );
      }
    } catch (_) {
      // Silently fail — map stays on Sofia
    }
  }

  void _openMenu() {
    _controller.forward();
    setState(() => _isMenuOpen = true);
  }

  void _closeMenu() {
    _controller.reverse();
    setState(() => _isMenuOpen = false);
  }

  String _getTileUrl(MapLayer layer) {
    switch (layer) {
      case MapLayer.osm:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayer.opentopomap:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case MapLayer.stamenterrain:
        return 'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}.png';
      case MapLayer.esri:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayer.cartodb:
        return Theme.of(context).brightness == Brightness.dark
            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
  }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sofiaCenter,
              initialZoom: _defaultZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {},
              onTap: _onMapTapped,
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(_selectedLayer),
                userAgentPackageName: 'helixtrace',
              ),
              SimpleAttributionWidget(
                source: Text(_selectedLayer.label),
              ),
              _buildMarkersLayer(),
              _buildLosLinesLayer(),
              _buildLosTempMarkersLayer(),
            ],
          ),
          _buildHamburgerButton(colorScheme, topPadding),
          _buildLayerButton(colorScheme, topPadding),
          _buildLosButton(colorScheme, topPadding),
          if (_isMenuOpen) _buildScrimOverlay(),
          _buildSlideMenu(theme, colorScheme, authState, topPadding),
          if (_losMode && _losPoints.isNotEmpty) _buildLosBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMarkersLayer() {
    final pointsState = ref.watch(pointsProvider);

    if (pointsState.isLoading) return const SizedBox.shrink();
    if (pointsState.error != null) return const SizedBox.shrink();

    final points = pointsState.points;
    final colorScheme = Theme.of(context).colorScheme;

    if (points.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      markers: points.map((point) {
        Color color;
        if (_losMode) {
          final isSelected = _losPoints.any(
            (p) => p.position.latitude == point.lat &&
                p.position.longitude == point.lon,
          );
          color = isSelected ? _losSelectedMarkerColor : _markerColor(point);
        } else {
          color = _markerColor(point);
        }

        return Marker(
          point: LatLng(point.lat, point.lon),
          width: 28,
          height: 28,
          child: GestureDetector(
            onTap: () {
              if (_losMode) {
                _selectExistingMarker(point);
              } else {
                _showPointPopup(point, colorScheme);
              }
            },
            child: CustomPaint(
              painter: _MarkerPainter(color: color),
              size: const Size(28, 28),
            ),
          ),
        );
      }).toList(),
    );
  }

Widget _buildLosLinesLayer() {
    if (_losPoints.length < 2) return const SizedBox.shrink();

    final lines = <Polyline>[];
    final pairs = <(int, int)>[];
    if (_losPoints.length == 2) {
      pairs.add((0, 1));
    } else if (_losPoints.length == 3) {
      pairs.add((0, 1));
      pairs.add((1, 2));
      pairs.add((0, 2));
    }

    if (_traceResults.isEmpty) {
      for (final (i, j) in pairs) {
        lines.add(Polyline(
          points: [_losPoints[i].position, _losPoints[j].position],
          color: _losLineColor,
          strokeWidth: _losLineWidth,
          strokeJoin: StrokeJoin.round,
        ));
      }
    } else {
      final clearCount = _traceResults.where((r) => r.losStatus == LOSStatus.clear).length;
      for (int idx = 0; idx < pairs.length && idx < _traceResults.length; idx++) {
        final (i, j) = pairs[idx];
        final result = _traceResults[idx];
        final status = result.losStatus;

        Color color;
        bool dashed = false;

        if (status == LOSStatus.clear) {
          color = _losClearColor;
        } else if (status == LOSStatus.blocked) {
          color = _losBlockedColor;
        } else {
          color = _losLineColor;
        }

        if (_losPoints.length == 2) {
          if (status == LOSStatus.blocked) dashed = true;
        } else if (_losPoints.length == 3) {
          if (clearCount < 2) dashed = true;
        }

        lines.add(Polyline(
          points: [_losPoints[i].position, _losPoints[j].position],
          color: color,
          strokeWidth: _losLineWidth,
          strokeJoin: StrokeJoin.round,
          pattern: dashed
              ? StrokePattern.dashed(segments: [8, 6])
              : const StrokePattern.solid(),
        ));
      }
    }

    return PolylineLayer(polylines: lines);
  }

  Widget _buildLosTempMarkersLayer() {
    if (_losPoints.isEmpty) return const SizedBox.shrink();

    final tempPoints = _losPoints
        .asMap()
        .entries
        .where((e) => e.value.isTemporary)
        .toList();
    if (tempPoints.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      markers: tempPoints.map((entry) {
        final index = entry.key;
        final losPoint = entry.value;
        final isDragging = _draggingIndex == index;
        return Marker(
          point: losPoint.position,
          width: isDragging ? 36 : 28,
          height: isDragging ? 36 : 28,
          child: GestureDetector(
            onTap: () => _deselectLosPointAt(index),
            onLongPressStart: (_) {
              setState(() => _draggingIndex = index);
            },
            onLongPressMoveUpdate: (details) {
              _onMarkerDrag(index, details);
            },
            onLongPressEnd: (_) {
              _onMarkerDragEnd(index);
            },
            child: CustomPaint(
              painter: _MarkerPainter(color: _losTempMarkerColor),
              size: Size(isDragging ? 36 : 28, isDragging ? 36 : 28),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _onMarkerDrag(int index, LongPressMoveUpdateDetails details) {
    final mapContext = _mapKey.currentContext;
    if (mapContext == null) return;
    final box = mapContext.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    final offset = Offset(local.dx, local.dy);

    try {
      final latLng = _mapController.camera.screenOffsetToLatLng(offset);
      setState(() {
        _losPoints[index] = _LosPoint(
          name: _losPoints[index].name,
          position: latLng,
          elevation: _losPoints[index].elevation,
          isTemporary: true,
          color: _losTempMarkerColor,
        );
      });
    } catch (_) {
      // ignore out-of-bounds
    }
  }

  Future<void> _onMarkerDragEnd(int index) async {
    setState(() => _draggingIndex = null);
    final point = _losPoints[index];
    final apiService = ref.read(apiServiceProvider);
    try {
      final response = await apiService.getPointInfo(
        lat: point.position.latitude,
        lon: point.position.longitude,
      );
      final body = response.data;
      double? elevation;
      if (body is Map<String, dynamic>) {
        final dataBlock = body['data'];
        if (dataBlock is Map<String, dynamic>) {
          elevation = (dataBlock['elevation'] as num?)?.toDouble();
        } else {
          elevation = (body['elevation'] as num?)?.toDouble();
        }
      }
      if (!mounted) return;
      setState(() {
        _losPoints[index] = _LosPoint(
          name: point.name,
          position: point.position,
          elevation: elevation,
          isTemporary: true,
          color: _losTempMarkerColor,
        );
      });
    } catch (_) {
      // elevation stays null after drag
    }

    _fetchTraceResults();
  }

  void _showPointPopup(PointModel point, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              point.label ?? 'Unnamed Point',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _infoRow('ID', point.id),
            _infoRow('Latitude', point.lat.toStringAsFixed(6)),
            _infoRow('Longitude', point.lon.toStringAsFixed(6)),
            _infoRow('Elevation', '${point.elevation.toStringAsFixed(1)} m'),
            _infoRow('Category ID', point.categoryId.toString()),
            _infoRow('Public', point.public ? 'Yes' : 'No'),
            if (point.user != null) _infoRow('Owner', point.user!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHamburgerButton(ColorScheme colorScheme, double topPadding) {
    return Positioned(
      top: topPadding + 16,
      left: 16,
      child: GestureDetector(
        onTap: _openMenu,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.menu, color: colorScheme.onSurface, size: 22),
        ),
      ),
    );
  }

  Widget _buildLayerButton(ColorScheme colorScheme, double topPadding) {
    return Positioned(
      top: topPadding + 16,
      right: 16,
      child: PopupMenuButton<MapLayer>(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        offset: const Offset(0, 8),
        tooltip: '',
        itemBuilder: (context) => MapLayer.values.map((layer) {
          return PopupMenuItem<MapLayer>(
            value: layer,
            child: Row(
              children: [
                Icon(
                  layer.icon,
                  size: 20,
                  color: _selectedLayer == layer
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  layer.label,
                  style: TextStyle(
                    fontWeight: _selectedLayer == layer
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _selectedLayer == layer
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _selectedLayer.icon,
            color: colorScheme.onSurface,
            size: 22,
          ),
        ),
        onSelected: (layer) {
          setState(() => _selectedLayer = layer);
          StorageService().setMapLayer(layer.key);
        },
      ),
    );
  }

  Widget _buildLosButton(ColorScheme colorScheme, double topPadding) {
    return Positioned(
      top: topPadding + 16,
      right: 76,
      child: GestureDetector(
        onTap: _toggleLosMode,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _losMode
                ? colorScheme.primary
                : colorScheme.surfaceContainer,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.visibility_outlined,
            color: _losMode
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildScrimOverlay() {
    return GestureDetector(
      onTap: _closeMenu,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildSlideMenu(
    ThemeData theme,
    ColorScheme colorScheme,
    AuthState authState,
    double topPadding,
  ) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-_menuWidth * (1 - _slideAnimation.value), 0),
          child: child,
        );
      },
      child: SizedBox(
        width: _menuWidth,
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : const Color(0xFFFAFBFF),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(4, 0),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMenuHeader(theme, colorScheme, authState, topPadding),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.map_outlined,
                label: 'Map',
                colorScheme: colorScheme,
                theme: theme,
                isSelected: true,
                onTap: _closeMenu,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(height: 8),
              _buildLogoutItem(theme, colorScheme),
              SizedBox(height: topPadding > 0 ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    AuthState authState,
    double topPadding,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 24,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Text(
              (authState.user?.email ?? '')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              authState.user?.email ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () async {
          _closeMenu();
          await ref.read(authProvider.notifier).logout();
          if (mounted) {
            context.go(AppConstants.routeLogin);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 22,
                color: colorScheme.error,
              ),
              const SizedBox(width: 14),
              Text(
                'Logout',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLosBottomSheet() {
    final theme = Theme.of(context);
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (_) => false,
      child: DraggableScrollableSheet(
        initialChildSize: _sheetMinHeight,
        minChildSize: _sheetMinHeight,
        maxChildSize: _sheetMaxHeight,
        snap: true,
        snapSizes: const [_sheetMinHeight, _sheetMaxHeight],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Line of Sight',
                            style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final point = _losPoints[index];
                      return ListTile(
                        title: Text(point.name),
                        subtitle: Text(
                          point.elevation != null
                              ? '${point.elevation!.toStringAsFixed(1)} m'
                              : 'Fetching elevation...',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _deselectLosPointAt(index),
                        ),
                      );
                    },
                    childCount: _losPoints.length,
                  ),
                ),
                if (_isLoadingTrace)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (!_isLoadingTrace && _traceResults.isNotEmpty)
                  ..._traceResults.map((result) => SliverToBoxAdapter(
                        child: _buildGraphCard(result),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraphCard(TraceResult result) {
    final graphData = computeGraphData(result.traceData, result.fromElevation, result.toElevation);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${result.fromLabel} → ${result.toLabel}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 160,
            child: CustomPaint(
              painter: TerrainGraphPainter(
                data: graphData,
                fromLabel: result.fromLabel,
                toLabel: result.toLabel,
                losStatus: result.losStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  final Color color;
  const _MarkerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx, cy), radius, shadowPaint);

    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), radius, strokePaint);

    final innerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius * 0.35, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) =>
      color != oldDelegate.color;
}

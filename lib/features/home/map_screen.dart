import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:helixtrace/core/constants/app_constants.dart';
import 'package:helixtrace/core/storage/storage_service.dart';
import 'package:helixtrace/data/models/point_model.dart';
import 'package:helixtrace/features/auth/providers/auth_provider.dart' show AuthState;
import 'package:helixtrace/features/auth/providers/providers.dart';
import 'package:helixtrace/features/home/providers/points_provider.dart';
import 'package:latlong2/latlong.dart';

const _categoryColors = <int, _ColorPair>{
  1: _ColorPair(public: '#1976d2', private: '#7b1fa2'),
  2: _ColorPair(public: '#2e7d32', private: '#d32f2f'),
  3: _ColorPair(public: '#f9a825', private: '#ef6c00'),
};

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  static const _menuWidth = 280.0;
  static const _sofiaCenter = LatLng(42.6977, 23.3219);
  static const _defaultZoom = 13.0;

  MapLayer _selectedLayer = MapLayer.osm;
  bool _isMenuOpen = false;

  late final MapController _mapController;

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
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey(_selectedLayer.key),
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sofiaCenter,
              initialZoom: _defaultZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
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
            ],
          ),
          _buildHamburgerButton(colorScheme, topPadding),
          _buildLayerButton(colorScheme, topPadding),
          if (_isMenuOpen) _buildScrimOverlay(),
          _buildSlideMenu(theme, colorScheme, authState, topPadding),
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
        final color = _markerColor(point);
        return Marker(
          point: LatLng(point.lat, point.lon),
          width: 25,
          height: 41,
          child: GestureDetector(
            onTap: () => _showPointPopup(point, colorScheme),
            child: CustomPaint(
              painter: _MarkerPinPainter(color: color),
              size: const Size(25, 41),
            ),
          ),
        );
      }).toList(),
    );
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
}

class _MarkerPinPainter extends CustomPainter {
  final Color color;
  const _MarkerPinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final cx = size.width / 2;
    final radius = size.width / 2;
    final pinBottom = size.height;

    final path = ui.Path();
    path.addOval(Rect.fromCircle(center: Offset(cx, radius), radius: radius));
    path.lineTo(cx, pinBottom);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, radius), radius * 0.4, whitePaint);
  }

  @override
  bool shouldRepaint(covariant _MarkerPinPainter oldDelegate) =>
      color != oldDelegate.color;
}

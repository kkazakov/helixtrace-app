import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:helixtrace/core/constants/app_constants.dart';
import 'package:helixtrace/features/auth/providers/auth_provider.dart' show AuthState;
import 'package:helixtrace/features/auth/providers/providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scrimAnimation;

  static const _menuWidth = 280.0;

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
    _scrimAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMenu() => _controller.forward();
  void _closeMenu() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(theme, colorScheme),
          _buildMapContent(theme, colorScheme),
          _buildHamburgerButton(colorScheme, topPadding),
          _buildScrimOverlay(),
          _buildSlideMenu(theme, colorScheme, authState, topPadding),
        ],
      ),
    );
  }

  Widget _buildBackground(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.brightness == Brightness.dark
              ? [const Color(0xFF0B1120), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFEFF3FF)],
        ),
      ),
    );
  }

  Widget _buildMapContent(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.map_outlined, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            'Map',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your network map will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
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
        child: Opacity(
          opacity: 0.5,
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
      ),
    );
  }

  Widget _buildScrimOverlay() {
    return AnimatedBuilder(
      animation: _scrimAnimation,
      builder: (context, _) {
        if (_scrimAnimation.value == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: _closeMenu,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4 * _scrimAnimation.value),
          ),
        );
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authState.user?.email ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
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
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () async {
            _closeMenu();
            await ref.read(authProvider.notifier).logout();
            if (mounted) {
              context.go(AppConstants.routeLogin);
            }
          },
          borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}
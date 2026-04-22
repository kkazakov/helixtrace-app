import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF0A0A12),
                    const Color(0xFF12121F),
                  ]
                : [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFEEEEF5),
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF00D9FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Map',
                style: theme.textTheme.headlineLarge?.copyWith(
                  background: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        const Color(0xFF00D9FF),
                      ],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 100, 60),
                    ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your network map will appear here',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

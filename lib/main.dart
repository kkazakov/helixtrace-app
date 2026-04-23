import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:helixtrace/core/constants/app_constants.dart';
import 'package:helixtrace/core/storage/storage_service.dart';
import 'package:helixtrace/core/theme/app_theme.dart';
import 'package:helixtrace/features/auth/login_screen.dart';
import 'package:helixtrace/features/auth/providers/providers.dart';
import 'package:helixtrace/features/auth/register_screen.dart';
import 'package:helixtrace/features/home/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final storage = StorageService();
  await storage.init();

  runApp(const ProviderScope(child: HelixTraceApp()));
}

class HelixTraceApp extends ConsumerWidget {
  const HelixTraceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HelixTrace',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeLogin,
    routes: [
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) {
          return const AuthenticationShell();
        },
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const MapScreen(),
      ),
    ],
  );
});

class AuthenticationShell extends ConsumerStatefulWidget {
  const AuthenticationShell({super.key});

  @override
  ConsumerState<AuthenticationShell> createState() => _AuthenticationShellState();
}

class _AuthenticationShellState extends ConsumerState<AuthenticationShell> {
  @override
  void initState() {
    super.initState();
    // Kick off session restoration from storage on app start.
    Future.microtask(() {
      try {
        ref.read(authProvider.notifier).init();
      } catch (_) {
        // Storage may not be initialized in tests or edge cases.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show a loading indicator while checking for an existing session.
    if (authState.isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0B1120),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFEFF3FF),
                    ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (authState.user != null) {
      return const MapScreen();
    }
    return const LoginScreen();
  }
}
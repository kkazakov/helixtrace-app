import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helixtrace/core/storage/storage_service.dart';
import 'package:helixtrace/data/repositories/auth_repository.dart';
import 'package:helixtrace/data/services/api_service.dart';
import 'package:helixtrace/data/services/auth_service.dart';
import 'package:helixtrace/features/auth/providers/auth_provider.dart';
import 'package:helixtrace/features/auth/providers/theme_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final customUrl = storage.getApiKey();
  return ApiService(
    storageService: storage,
    customBaseUrl: customUrl,
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref.read(storageServiceProvider)),
);
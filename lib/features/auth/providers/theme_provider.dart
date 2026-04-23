import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:helixtrace/core/storage/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeNotifier(this._storageService) : super(_storageService.getThemeMode());

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    _storageService.setThemeMode(newMode);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _storageService.setThemeMode(mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref.read(storageServiceProvider)),
);

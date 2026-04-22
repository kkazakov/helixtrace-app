import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getApiKey() => _prefs.getString('api_url');

  Future<void> setApiKey(String url) async {
    await _prefs.setString('api_url', url);
  }

  String? getAuthToken() => _prefs.getString('auth_token');

  Future<void> setAuthToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove('auth_token');
  }

  String? getUserEmail() => _prefs.getString('user_email');

  Future<void> setUserEmail(String email) async {
    await _prefs.setString('user_email', email);
  }

  Future<void> clearUserEmail() async {
    await _prefs.remove('user_email');
  }

  ThemeMode getThemeMode() {
    final index = _prefs.getInt('theme_mode') ?? 0;
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt('theme_mode', mode.index);
  }
}

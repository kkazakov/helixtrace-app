import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  String? getApiKey() {
    if (!_initialized) return null;
    return _prefs.containsKey('api_url') ? _prefs.getString('api_url') : null;
  }

  Future<void> setApiKey(String url) async {
    await _prefs.setString('api_url', url);
  }

  String? getAuthToken() {
    if (!_initialized) return null;
    return _prefs.containsKey('auth_token') ? _prefs.getString('auth_token') : null;
  }

  Future<void> setAuthToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove('auth_token');
  }

  String? getUserEmail() {
    if (!_initialized) return null;
    return _prefs.containsKey('user_email') ? _prefs.getString('user_email') : null;
  }

  Future<void> setUserEmail(String email) async {
    await _prefs.setString('user_email', email);
  }

  Future<void> clearUserEmail() async {
    await _prefs.remove('user_email');
  }

  ThemeMode getThemeMode() {
    if (!_initialized) return ThemeMode.light;
    final index = _prefs.getInt('theme_mode') ?? 0;
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt('theme_mode', mode.index);
  }

  String? getMapLayer() {
    if (!_initialized) return null;
    return _prefs.getString('map_layer');
  }

  Future<void> setMapLayer(String layer) async {
    await _prefs.setString('map_layer', layer);
  }
}

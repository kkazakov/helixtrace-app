import 'package:helixtrace/core/storage/storage_service.dart';
import 'package:helixtrace/data/models/auth_response.dart';
import 'package:helixtrace/data/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  final StorageService _storageService;

  AuthRepository(this._authService, this._storageService);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final authResponse = await _authService.login(
      email: email,
      password: password,
    );

    await _storageService.setAuthToken(authResponse.token);
    await _storageService.setUserEmail(authResponse.email);

    // Validate the token immediately against a protected endpoint
    await _authService.validateToken();

    return authResponse;
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    final authResponse = await _authService.register(
      email: email,
      password: password,
    );

    await _storageService.setAuthToken(authResponse.token);
    await _storageService.setUserEmail(authResponse.email);

    // Validate the token immediately against a protected endpoint
    await _authService.validateToken();

    return authResponse;
  }

  /// Attempts to restore an existing session from storage.
  /// Validates the stored token against the API.
  /// Returns true if the session is valid, false otherwise.
  Future<bool> restoreSession() async {
    final token = _storageService.getAuthToken();
    final email = _storageService.getUserEmail();

    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      return false;
    }

    try {
      await _authService.validateToken();
      return true;
    } catch (_) {
      // Token is invalid or expired — clear storage
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAuthToken();
    await _storageService.clearUserEmail();
  }

  bool get isAuthenticated => _storageService.getAuthToken() != null;

  String? get currentUserEmail => _storageService.getUserEmail();

  String? get currentToken => _storageService.getAuthToken();
}
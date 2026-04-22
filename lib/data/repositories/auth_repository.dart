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

    return authResponse;
  }

  Future<void> logout() async {
    await _storageService.clearAuthToken();
    await _storageService.clearUserEmail();
  }

  bool get isAuthenticated => _storageService.getAuthToken() != null;

  String? get currentUserEmail => _storageService.getUserEmail();
}

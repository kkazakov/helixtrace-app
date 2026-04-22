import 'package:helixtrace/data/models/auth_response.dart';
import 'package:helixtrace/data/services/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );

    final data = response.data as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.register(
      email: email,
      password: password,
    );

    final data = response.data as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }
}

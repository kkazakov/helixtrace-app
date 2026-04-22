import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helixtrace/data/models/auth_response.dart';
import 'package:helixtrace/data/repositories/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final AuthResponse? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState.initial() : this(isLoading: false, user: null, error: null);

  AuthState.loading() : this(isLoading: true, user: null, error: null);

  AuthState.error(String message) : this(isLoading: false, user: null, error: message);

  AuthState.authenticated(AuthResponse user) : this(isLoading: false, user: user, error: null);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(response);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final response = await _repository.register(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(response);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.initial();
  }

  bool get isAuthenticated => _repository.isAuthenticated;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider must be overridden');
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

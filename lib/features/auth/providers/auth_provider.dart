import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:helixtrace/data/models/auth_response.dart';
import 'package:helixtrace/data/repositories/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final AuthResponse? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isInitializing = false,
    this.user,
    this.error,
  });

  AuthState.initial() : this(isLoading: false, isInitializing: false, user: null, error: null);

  AuthState.initializing() : this(isLoading: false, isInitializing: true, user: null, error: null);

  AuthState.loading() : this(isLoading: true, isInitializing: false, user: null, error: null);

  AuthState.error(String message) : this(isLoading: false, isInitializing: false, user: null, error: message);

  AuthState.authenticated(AuthResponse user) : this(isLoading: false, isInitializing: false, user: user, error: null);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  bool _hasInitialized = false;

  AuthNotifier(this._repository) : super(AuthState.initial());

  /// Checks storage for an existing token and validates it against the API.
  /// Should be called once on app startup.
  Future<void> init() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    state = AuthState.initializing();

    final isValid = await _repository.restoreSession();
    if (isValid) {
      // Reconstruct a minimal AuthResponse from storage since the API
      // doesn't return it on token validation.
      final email = _repository.currentUserEmail;
      final token = _repository.currentToken;
      if (email != null && token != null) {
        state = AuthState.authenticated(
          AuthResponse(token: token, email: email, username: email),
        );
      } else {
        state = AuthState.initial();
      }
    } else {
      state = AuthState.initial();
    }
  }

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

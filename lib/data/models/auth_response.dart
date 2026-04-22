class AuthResponse {
  final String token;
  final String email;
  final String username;

  AuthResponse({
    required this.token,
    required this.email,
    required this.username,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'username': username,
    };
  }
}

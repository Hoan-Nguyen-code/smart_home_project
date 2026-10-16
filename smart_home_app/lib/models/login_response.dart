
class LoginResponse {
  final String token;
  final String tokenType;
  final String email;
  final String role;

  LoginResponse({
    required this.token,
    required this.tokenType,
    required this.email,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}

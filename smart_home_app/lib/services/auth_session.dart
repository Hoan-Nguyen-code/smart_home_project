
class AuthSession {
  AuthSession._();

  static String? token;
  static String? role;
  static String? email;

  static bool get isLoggedIn => token != null;

  static bool get isAdmin => role == 'ADMIN';

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static void clear() {
    token = null;
    role = null;
    email = null;
  }
}

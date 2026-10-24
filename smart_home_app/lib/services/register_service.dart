
import 'dart:convert';

import 'package:http/http.dart' as http;

class RegisterService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api/auth/register';

  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    String message = 'Đăng ký thất bại. Vui lòng thử lại.';

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is Map<String, dynamic> &&
          data['message'] is String) {
        message = data['message'] as String;
      }
    } catch (_) {
      // Giữ thông báo mặc định nếu server không trả JSON hợp lệ.
    }

    if (response.statusCode == 409) {
      throw Exception(message);
    }

    if (response.statusCode == 400) {
      throw Exception(message);
    }

    throw Exception(
      'Lỗi máy chủ (${response.statusCode}): $message',
    );
  }
}


import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/login_response.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/auth';

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(json);
    }

    if (response.statusCode == 401) {
      throw Exception('Email hoặc mật khẩu không chính xác');
    }

    throw Exception(
      'Đăng nhập thất bại (HTTP ${response.statusCode})',
    );
  }
}

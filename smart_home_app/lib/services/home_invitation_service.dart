
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session.dart';

class HomeInvitationService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api/home-invitations';

  // ADMIN tạo mã mời cho một nhà.
  static Future<Map<String, dynamic>> createInvitation({
    required int homeId,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'homeId': homeId,
      }),
    );

    if (response.statusCode == 201) {
      final dynamic data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu mã mời không hợp lệ.');
      }

      return data;
    }

    if (response.statusCode == 400) {
      throw Exception('Thông tin nhà không hợp lệ.');
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Chỉ ADMIN mới có quyền tạo mã mời.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Không tìm thấy nhà cần tạo mã mời.');
    }

    throw Exception(
      'Không thể tạo mã mời (${response.statusCode}).',
    );
  }

  // USER nhập mã mời để tham gia nhà.
  static Future<void> joinHome(String code) async {
    final invitationCode = code.trim();

    if (invitationCode.isEmpty) {
      throw Exception('Vui lòng nhập mã mời.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/join'),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'code': invitationCode,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 400) {
      throw Exception(
        'Mã mời không hợp lệ hoặc đã hết hạn.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Tài khoản không có quyền sử dụng mã mời.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Không tìm thấy mã mời.',
      );
    }

    if (response.statusCode == 409) {
      throw Exception(
        'Mã mời đã được sử dụng hoặc bạn đã tham gia nhà.',
      );
    }

    throw Exception(
      'Không thể tham gia nhà (${response.statusCode}).',
    );
  }
}


import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_session.dart';

class HomeService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api/homes';

  // Lấy danh sách nhà của tài khoản đang đăng nhập.
  static Future<List<Map<String, dynamic>>> getMyHomes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my'),
      headers: AuthSession.authHeaders,
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);

      if (data is! List) {
        throw Exception('Dữ liệu danh sách nhà không hợp lệ.');
      }

      return data
          .map(
            (item) => Map<String, dynamic>.from(
              item as Map,
            ),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Bạn không có quyền xem danh sách nhà.',
      );
    }

    throw Exception(
      'Không thể kiểm tra danh sách nhà '
      '(${response.statusCode}).',
    );
  }

  // true: đã tham gia ít nhất một nhà.
  // false: chưa tham gia nhà nào.
  static Future<bool> hasJoinedHome() async {
    final homes = await getMyHomes();
    return homes.isNotEmpty;
  }
}

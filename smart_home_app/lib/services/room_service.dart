
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/room.dart';
import 'auth_session.dart';

class RoomService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/rooms';

  // GET - Lấy danh sách phòng (ADMIN và USER)
  static Future<List<Room>> getRooms() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: AuthSession.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể tải danh sách phòng'),
    );
  }

  // POST - Tạo phòng mới (chỉ ADMIN)
  static Future<Room> createRoom({
    required int homeId,
    required String name,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'homeId': homeId,
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Room.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể tạo phòng'),
    );
  }

  // PUT - Sửa thông tin phòng (chỉ ADMIN)
  static Future<Room> updateRoom({
    required int id,
    required String name,
    String? description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return Room.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể cập nhật phòng'),
    );
  }

  // DELETE - Xóa phòng (chỉ ADMIN)
  static Future<void> deleteRoom(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: AuthSession.authHeaders,
    );

    if (response.statusCode == 204) {
      return;
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể xóa phòng'),
    );
  }

  // Xử lý thông báo lỗi chung cho các API
  static String _getErrorMessage(
    http.Response response,
    String defaultMessage,
  ) {
    if (response.statusCode == 401) {
      return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. '
          'Vui lòng đăng nhập lại.';
    }

    if (response.statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }

    String message = '$defaultMessage (${response.statusCode})';

    try {
      final error = jsonDecode(response.body);

      if (error is Map && error['message'] != null) {
        message = error['message'].toString();
      }
    } catch (_) {
      // Giữ thông báo mặc định nếu response không phải JSON.
    }

    return message;
  }
}

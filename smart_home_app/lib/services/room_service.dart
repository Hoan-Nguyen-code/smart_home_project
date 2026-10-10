import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/room.dart';

class RoomService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/rooms';

  static Future<List<Room>> getRooms() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Không thể tải danh sách phòng: ${response.statusCode}');
    }
  }

  static Future<Room> createRoom({
    required int homeId,
    required String name,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'homeId': homeId,
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Room.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    String message = 'Không thể tạo phòng (${response.statusCode})';

    try {
      final error = jsonDecode(response.body);
      if (error is Map && error['message'] != null) {
        message = error['message'].toString();
      }
    } catch (_) {
      // Giữ thông báo mặc định nếu phản hồi không phải JSON.
    }

    throw Exception(message);
  }

  static Future<Room> updateRoom({
    required int id,
    required String name,
    String? description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': name, 'description': description}),
    );

    if (response.statusCode == 200) {
      return Room.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    String message = 'Không thể cập nhật phòng (${response.statusCode})';

    try {
      final error = jsonDecode(response.body);

      if (error is Map && error['message'] != null) {
        message = error['message'].toString();
      }
    } catch (_) {
      // Giữ thông báo mặc định nếu phản hồi không phải JSON.
    }

    throw Exception(message);
  }

  static Future<void> deleteRoom(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 204) {
      return;
    }

    String message = 'Không thể xóa phòng (${response.statusCode})';

    try {
      final error = jsonDecode(response.body);

      if (error is Map && error['message'] != null) {
        message = error['message'].toString();
      }
    } catch (_) {
      // Giữ thông báo mặc định nếu phản hồi không phải JSON.
    }

    throw Exception(message);
  }
}


import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/device.dart';
import 'auth_session.dart';

class DeviceService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/devices';

  // GET - Lấy toàn bộ thiết bị (ADMIN và USER)
  static Future<List<Device>> getDevices() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: AuthSession.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Device.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể tải danh sách thiết bị'),
    );
  }

  // GET - Lấy thiết bị theo phòng (ADMIN và USER)
  static Future<List<Device>> getDevicesByRoomId(int roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/room/$roomId'),
      headers: AuthSession.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Device.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể tải thiết bị của phòng'),
    );
  }

  // PATCH - Bật/tắt thiết bị (ADMIN và USER)
  static Future<Device> updateDeviceStatus({
    required int id,
    required bool status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/status'),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return Device.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể cập nhật trạng thái thiết bị'),
    );
  }

  // POST - Thêm thiết bị (chỉ ADMIN)
  static Future<Device> createDevice({
    required int roomId,
    required int nodeId,
    required String name,
    required String type,
    required bool status,
    required String mqttChannel,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'roomId': roomId,
        'nodeId': nodeId,
        'name': name,
        'type': type,
        'status': status,
        'mqttChannel': mqttChannel,
      }),
    );

    if (response.statusCode == 201) {
      return Device.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể tạo thiết bị'),
    );
  }

  // PUT - Sửa thông tin thiết bị (chỉ ADMIN)
  static Future<Device> updateDevice({
    required int id,
    required int roomId,
    required int nodeId,
    required String name,
    required String type,
    required String mqttChannel,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: AuthSession.authHeaders,
      body: jsonEncode({
        'roomId': roomId,
        'nodeId': nodeId,
        'name': name,
        'type': type,
        'mqttChannel': mqttChannel,
      }),
    );

    if (response.statusCode == 200) {
      return Device.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể cập nhật thiết bị'),
    );
  }

  // DELETE - Xóa thiết bị (chỉ ADMIN)
  static Future<void> deleteDevice(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: AuthSession.authHeaders,
    );

    if (response.statusCode == 204) {
      return;
    }

    throw Exception(
      _getErrorMessage(response, 'Không thể xóa thiết bị'),
    );
  }

  // Xử lý thông báo lỗi chung
  static String _getErrorMessage(
    http.Response response,
    String defaultMessage,
  ) {
    if (response.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. '
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

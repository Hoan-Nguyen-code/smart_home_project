
class Device {
  final int id;
  final int roomId;
  final int nodeId;
  final String name;
  final String type;
  final bool status;
  final String mqttChannel;

  const Device({
    required this.id,
    required this.roomId,
    required this.nodeId,
    required this.name,
    required this.type,
    required this.status,
    required this.mqttChannel,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      roomId: json['roomId'] as int,
      nodeId: json['nodeId'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as bool,
      mqttChannel: json['mqttChannel'] as String,
    );
  }
}

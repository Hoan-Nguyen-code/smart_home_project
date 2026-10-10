
class Room {
  final int id;
  final int homeId;
  final String name;
  final String? description;

  Room({
    required this.id,
    required this.homeId,
    required this.name,
    this.description,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      homeId: json['homeId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

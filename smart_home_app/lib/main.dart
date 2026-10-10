import 'package:flutter/material.dart';

import 'widgets/edit_room_dialog.dart';
import 'services/room_service.dart';
import 'models/room.dart';

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RoomScreen(),
    );
  }
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late Future<List<Room>> roomsFuture;

  @override
  void initState() {
    super.initState();
    roomsFuture = RoomService.getRooms();
  }

  void reloadRooms() {
    setState(() {
      roomsFuture = RoomService.getRooms();
    });
  }

  Future<void> editRoom(Room room) async {
    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return EditRoomDialog(room: room);
      },
    );

    if (!mounted) return;

    if (updated == true) {
      reloadRooms();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật phòng thành công!')),
      );
    }
  }

  Future<void> deleteRoom(Room room) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa phòng'),
          content: Text('Ông có chắc muốn xóa phòng "${room.name}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    try {
      await RoomService.deleteRoom(room.id);

      if (!mounted) return;

      reloadRooms();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Xóa phòng thành công!')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> showRoomOptions(Room room) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thông tin phòng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tên phòng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(room.name),
              const SizedBox(height: 16),
              const Text(
                'Mô tả',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                room.description?.isNotEmpty == true
                    ? room.description!
                    : 'Không có mô tả',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                editRoom(room);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Cập nhật'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteRoom(room);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(onPressed: reloadRooms, icon: const Icon(Icons.refresh)),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              final nameController = TextEditingController();
              final descriptionController = TextEditingController();

              return AlertDialog(
                title: const Text('Thêm phòng mới'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên phòng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final description = descriptionController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tên phòng không được để trống'),
                          ),
                        );
                        return;
                      }

                      try {
                        await RoomService.createRoom(
                          homeId: 1,
                          name: name,
                          description: description,
                        );

                        if (!mounted) return;

                        Navigator.pop(dialogContext);
                        reloadRooms();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thêm phòng thành công!'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder<List<Room>>(
        future: roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(child: Text('Chưa có phòng nào'));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final Room room = rooms[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(

                    leading: const Icon(Icons.meeting_room),
                    title: Text(room.name),
                    subtitle: Text(room.description ?? ''),
                    onTap: () => showRoomOptions(room),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Thông tin và tùy chọn phòng',
                      onPressed: () => showRoomOptions(room),
                    ),
                  ),

              );
            },
          );
        },
      ),
    );
  }
}

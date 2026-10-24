
import 'package:flutter/material.dart';

import 'widgets/edit_room_dialog.dart';
import 'services/room_service.dart';
import 'services/auth_session.dart';
import 'models/room.dart';
import 'screens/device_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_invitation_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
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

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ADMIN - Thêm phòng
  Future<void> addRoom() async {
    if (!AuthSession.isAdmin) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    try {
      final bool? created = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          bool isSaving = false;

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Thêm phòng mới'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Tên phòng',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name =
                                nameController.text.trim();
                            final description =
                                descriptionController.text.trim();

                            if (name.isEmpty) {
                              showMessage(
                                'Tên phòng không được để trống',
                              );
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              await RoomService.createRoom(
                                homeId: 1,
                                name: name,
                                description: description,
                              );

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext, true);
                            } catch (e) {
                              showMessage(
                                e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              );

                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  isSaving = false;
                                });
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Lưu'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted) return;

      if (created == true) {
        reloadRooms();
        showMessage('Thêm phòng thành công!');
      }
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  // ADMIN - Sửa phòng
  Future<void> editRoom(Room room) async {
    if (!AuthSession.isAdmin) return;

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return EditRoomDialog(room: room);
      },
    );

    if (!mounted) return;

    if (updated == true) {
      reloadRooms();
      showMessage('Cập nhật phòng thành công!');
    }
  }

  // ADMIN - Xóa phòng
  Future<void> deleteRoom(Room room) async {
    if (!AuthSession.isAdmin) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa phòng'),
          content: Text(
            'Ông có chắc muốn xóa phòng "${room.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
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
      showMessage('Xóa phòng thành công!');
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ADMIN có nút sửa/xóa; USER chỉ xem thông tin
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(room.name),
              const SizedBox(height: 16),
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Đóng'),
            ),
            if (AuthSession.isAdmin)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  editRoom(room);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Cập nhật'),
              ),
            if (AuthSession.isAdmin)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  deleteRoom(room);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                label: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  // Đăng xuất - ADMIN và USER
  Future<void> logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi Smart Home?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    // Xóa JWT, role và email của phiên hiện tại
    AuthSession.clear();

    // Xóa lịch sử điều hướng và quay về LoginScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AuthSession.isAdmin
              ? 'Quản lý phòng'
              : 'Danh sách phòng',
        ),
        backgroundColor: Colors.blue.shade100,
        actions: [
          // Chỉ ADMIN được hiển thị nút tạo mã mời.
          if (AuthSession.isAdmin)
            IconButton(
              tooltip: 'Tạo mã mời tham gia nhà',
              icon: const Icon(Icons.vpn_key_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreateInvitationScreen(),
                  ),
                );
              },
            ),

          IconButton(
            tooltip: 'Tải lại danh sách phòng',
            onPressed: reloadRooms,
            icon: const Icon(Icons.refresh),
          ),

          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      // Chỉ ADMIN có nút thêm phòng
      floatingActionButton: AuthSession.isAdmin
          ? FloatingActionButton(
              onPressed: addRoom,
              tooltip: 'Thêm phòng',
              child: const Icon(Icons.add),
            )
          : null,

      body: FutureBuilder<List<Room>>(
        future: roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text('Chưa có phòng nào'),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final Room room = rooms[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.meeting_room,
                  ),
                  title: Text(room.name),
                  subtitle: Text(
                    room.description ?? '',
                  ),

                  // ADMIN và USER đều mở được thiết bị
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceScreen(
                          roomId: room.id,
                          roomName: room.name,
                        ),
                      ),
                    );
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Thông tin và tùy chọn phòng',
                    onPressed: () {
                      showRoomOptions(room);
                    },
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


import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/room_service.dart';

class EditRoomDialog extends StatefulWidget {
  final Room room;

  const EditRoomDialog({
    super.key,
    required this.room,
  });

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.room.name,
    );

    descriptionController = TextEditingController(
      text: widget.room.description ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> saveRoom() async {
    if (isSaving) return;

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

    setState(() {
      isSaving = true;
    });

    try {
      await RoomService.updateRoom(
        id: widget.room.id,
        name: name,
        description: description,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa phòng'),
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
          onPressed: isSaving
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : saveRoom,
          child: Text(isSaving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }
}

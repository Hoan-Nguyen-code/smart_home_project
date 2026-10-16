
import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/device_service.dart';
import '../services/auth_session.dart';

class DeviceScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const DeviceScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late Future<List<Device>> devicesFuture;
  final Set<int> updatingDeviceIds = {};

  @override
  void initState() {
    super.initState();
    reloadDevices();
  }

  void reloadDevices() {
    setState(() {
      devicesFuture = DeviceService.getDevicesByRoomId(widget.roomId);
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ADMIN và USER đều được bật/tắt thiết bị
  Future<void> toggleDevice(Device device, bool newStatus) async {
    if (updatingDeviceIds.contains(device.id)) return;

    setState(() {
      updatingDeviceIds.add(device.id);
    });

    try {
      await DeviceService.updateDeviceStatus(
        id: device.id,
        status: newStatus,
      );

      if (!mounted) return;

      reloadDevices();

      showMessage(
        '${device.name} đã ${newStatus ? "bật" : "tắt"}',
      );
    } catch (e) {
      showMessage(errorText(e));
    } finally {
      if (mounted) {
        setState(() {
          updatingDeviceIds.remove(device.id);
        });
      }
    }
  }

  // ADMIN thêm hoặc sửa thiết bị
  Future<void> showDeviceForm({Device? device}) async {
    if (!AuthSession.isAdmin) return;

    final isEditing = device != null;

    final nameController = TextEditingController(
      text: device?.name ?? '',
    );

    final nodeIdController = TextEditingController(
      text: device?.nodeId.toString() ?? '',
    );

    final mqttController = TextEditingController(
      text: device?.mqttChannel ?? '',
    );

    // Giữ loại thiết bị hiện tại khi sửa.
    String selectedType = device?.type ?? 'LIGHT';
    bool isSaving = false;

    try {
      final bool? saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Sửa thiết bị'
                      : 'Thêm thiết bị mới',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Tên thiết bị',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Loại thiết bị',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'LIGHT',
                            child: Text('Đèn'),
                          ),
                          DropdownMenuItem(
                            value: 'FAN',
                            child: Text('Quạt'),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedType = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nodeIdController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Node ID',
                          hintText: 'Ví dụ: 1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: mqttController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'MQTT Channel',
                          hintText: 'Ví dụ: home/living/light',
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
                        : () => Navigator.pop(
                              dialogContext,
                              false,
                            ),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name =
                                nameController.text.trim();

                            final nodeId = int.tryParse(
                              nodeIdController.text.trim(),
                            );

                            final mqttChannel =
                                mqttController.text.trim();

                            if (name.isEmpty) {
                              showMessage(
                                'Vui lòng nhập tên thiết bị',
                              );
                              return;
                            }

                            if (nodeId == null || nodeId <= 0) {
                              showMessage(
                                'Node ID phải là số nguyên dương',
                              );
                              return;
                            }

                            if (mqttChannel.isEmpty) {
                              showMessage(
                                'Vui lòng nhập MQTT Channel',
                              );
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              if (isEditing) {
                                await DeviceService.updateDevice(
                                  id: device.id,
                                  roomId: widget.roomId,
                                  nodeId: nodeId,
                                  name: name,
                                  type: selectedType,
                                  mqttChannel: mqttChannel,
                                );
                              } else {
                                await DeviceService.createDevice(
                                  roomId: widget.roomId,
                                  nodeId: nodeId,
                                  name: name,
                                  type: selectedType,
                                  status: false,
                                  mqttChannel: mqttChannel,
                                );
                              }

                              if (!dialogContext.mounted) return;

                              Navigator.pop(
                                dialogContext,
                                true,
                              );
                            } catch (e) {
                              showMessage(errorText(e));

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
                        : Text(
                            isEditing ? 'Lưu thay đổi' : 'Thêm',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted) return;

      if (saved == true) {
        reloadDevices();

        showMessage(
          isEditing
              ? 'Cập nhật thiết bị thành công!'
              : 'Thêm thiết bị thành công!',
        );
      }
    } finally {
      nameController.dispose();
      nodeIdController.dispose();
      mqttController.dispose();
    }
  }

  // ADMIN xóa thiết bị
  Future<void> deleteDevice(Device device) async {
    if (!AuthSession.isAdmin) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa thiết bị'),
          content: Text(
            'Ông có chắc muốn xóa thiết bị "${device.name}" không?',
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
      await DeviceService.deleteDevice(device.id);

      if (!mounted) return;

      reloadDevices();
      showMessage('Xóa thiết bị thành công!');
    } catch (e) {
      showMessage(errorText(e));
    }
  }

  // Menu quản lý thiết bị chỉ dành cho ADMIN
  Future<void> showDeviceOptions(Device device) async {
    if (!AuthSession.isAdmin) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                title: Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'ID: ${device.id} • Node: ${device.nodeId}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Sửa thiết bị'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDeviceForm(device: device);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Xóa thiết bị',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  deleteDevice(device);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.blue.shade100,
        actions: [
          if (AuthSession.isAdmin)
            IconButton(
              tooltip: 'Thêm thiết bị',
              onPressed: () => showDeviceForm(),
              icon: const Icon(Icons.add),
            ),
          IconButton(
            tooltip: 'Làm mới danh sách',
            onPressed: reloadDevices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Device>>(
        future: devicesFuture,
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

          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return const Center(
              child: Text('Chưa có thiết bị nào'),
            );
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];

              final isUpdating =
                  updatingDeviceIds.contains(device.id);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        secondary: Icon(
                          device.type == 'LIGHT'
                              ? Icons.lightbulb_outline
                              : Icons.air,
                        ),
                        title: Text(device.name),
                        subtitle: Text(
                          'Phòng ${device.roomId} • '
                          '${device.status ? "Đang bật" : "Đang tắt"}',
                        ),
                        value: device.status,
                        onChanged: isUpdating
                            ? null
                            : (value) {
                                toggleDevice(device, value);
                              },
                      ),
                    ),

                    // Chỉ ADMIN thấy menu sửa/xóa
                    if (AuthSession.isAdmin)
                      IconButton(
                        tooltip: 'Quản lý thiết bị',
                        icon: const Icon(Icons.more_vert),
                        onPressed: isUpdating
                            ? null
                            : () => showDeviceOptions(device),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

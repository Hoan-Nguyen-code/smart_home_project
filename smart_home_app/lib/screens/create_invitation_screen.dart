
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/home_service.dart';
import '../services/home_invitation_service.dart';

class CreateInvitationScreen extends StatefulWidget {
  const CreateInvitationScreen({super.key});

  @override
  State<CreateInvitationScreen> createState() =>
      _CreateInvitationScreenState();
}

class _CreateInvitationScreenState extends State<CreateInvitationScreen> {
  late Future<List<Map<String, dynamic>>> _homesFuture;

  int? _selectedHomeId;
  bool _isCreating = false;
  Map<String, dynamic>? _invitation;

  @override
  void initState() {
    super.initState();
    _homesFuture = HomeService.getMyHomes();
  }

  Future<void> _createInvitation() async {
    if (_selectedHomeId == null || _isCreating) return;

    setState(() {
      _isCreating = true;
      _invitation = null;
    });

    try {
      final result = await HomeInvitationService.createInvitation(
        homeId: _selectedHomeId!,
      );

      if (!mounted) return;

      setState(() {
        _invitation = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo mã mời thành công!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _copyCode() async {
    final code = _invitation?['code']?.toString();

    if (code == null || code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã mời!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo mã mời'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _homesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Không thể tải danh sách nhà:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final homes = snapshot.data ?? [];

          if (homes.isEmpty) {
            return const Center(
              child: Text('Chưa có nhà nào trong hệ thống.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.vpn_key_outlined,
                  size: 72,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tạo mã mời tham gia nhà',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn nhà mà bạn muốn mời thành viên tham gia.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                DropdownButtonFormField<int>(
                  initialValue: _selectedHomeId,
                  decoration: const InputDecoration(
                    labelText: 'Chọn nhà',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  items: homes.map((home) {
                    final id = (home['id'] as num).toInt();
                    final name = home['name'].toString();

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: _isCreating
                      ? null
                      : (value) {
                          setState(() {
                            _selectedHomeId = value;
                            _invitation = null;
                          });
                        },
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _selectedHomeId == null || _isCreating
                      ? null
                      : _createInvitation,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text(
                      _isCreating ? 'Đang tạo...' : 'Tạo mã mời',
                    ),
                  ),
                ),

                if (_invitation != null) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Mã mời vừa tạo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SelectableText(
                    _invitation!['code']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy),
                    label: const Text('Sao chép mã mời'),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Hết hạn (UTC): '
                    '${_invitation!['expiresAt'] ?? 'Không xác định'}',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Mã có hiệu lực 24 giờ và chỉ được sử dụng một lần.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

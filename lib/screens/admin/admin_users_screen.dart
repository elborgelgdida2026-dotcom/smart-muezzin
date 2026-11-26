import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';

/// Users & roles (admin only). Role changes are written to the audit log.
/// A user can never promote themself — the DB trigger blocks it.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<Map<String, dynamic>>> _users;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _users = AdminService.instance.fetchProfiles();
    setState(() {});
  }

  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final ok = await confirmDialog(
      context,
      title: 'تغيير الدور',
      message: 'سيصبح دور ${user['email']} هو «$role». '
          'يُسجَّل هذا التغيير في سجل التدقيق.',
      confirmLabel: 'تغيير الدور',
    );
    if (!ok) return;
    try {
      await AdminService.instance
          .setRole(user['id'].toString(), role);
      if (mounted) {
        showAdminSnack(context, 'تم تغيير الدور.');
        _load();
      }
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر التغيير: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين والصلاحيات')),
      body: AdminGate(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _users,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('تعذّر التحميل: ${snap.error}'));
            }
            final users = snap.data!;
            if (users.isEmpty) {
              return const Center(child: Text('لا يوجد مستخدمون بعد.'));
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                final role = (u['role'] as String?) ?? 'user';
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text((u['email'] as String? ?? '?')
                          .substring(0, 1)
                          .toUpperCase()),
                    ),
                    title: Text(u['email']?.toString() ?? '—'),
                    subtitle: Text(
                      'الدور: $role • أُنشئ: ${formatAdminDate(u['created_at']?.toString())}',
                    ),
                    trailing: DropdownButton<String>(
                      value: role,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('مستخدم')),
                        DropdownMenuItem(
                            value: 'moderator', child: Text('مشرف')),
                        DropdownMenuItem(value: 'admin', child: Text('مدير')),
                      ],
                      onChanged: (v) {
                        if (v != null && v != role) _changeRole(u, v);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

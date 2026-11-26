import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_audit_screen.dart';
import 'admin_common.dart';
import 'admin_content_screen.dart';
import 'admin_login_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

/// Admin hub: aggregate stats (counts only — no individual worship data
/// is stored in Supabase at all), role + MFA level, and navigation to
/// every admin section. Staff-only via [AdminGate].
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<Map<String, int>> _stats;
  late Future<String> _aal;
  late Future<String?> _role;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final admin = AdminService.instance;
    _stats = admin.aggregateStats();
    _aal = admin.assuranceLevel();
    _role = admin.currentRole();
    setState(() {});
  }

  Future<void> _signOut() async {
    await AdminService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminService.instance;
    final entries = <({String title, String subtitle, IconData icon, Widget page})>[
      (
        title: 'إدارة المحتوى الإسلامي',
        subtitle: 'أذكار، أحاديث، قرّاء، مؤذنون، مناسبات، مدن، ترجمات',
        icon: Icons.library_books,
        page: const AdminContentScreen(),
      ),
      (
        title: 'إدارة المستخدمين والصلاحيات',
        subtitle: 'عرض المستخدمين وتغيير الأدوار (مدير فقط)',
        icon: Icons.people,
        page: const AdminUsersScreen(),
      ),
      (
        title: 'البلاغات والمقترحات',
        subtitle: 'مراجعة بلاغات المستخدمين وتغيير حالتها',
        icon: Icons.report_problem,
        page: const AdminReportsScreen(),
      ),
      (
        title: 'الإشعارات العامة',
        subtitle: 'صياغة وجدولة إعلانات عامة وإرسالها بعد تأكيد',
        icon: Icons.notifications_active,
        page: const AdminNotificationsScreen(),
      ),
      (
        title: 'سجل التدقيق',
        subtitle: 'كل إجراءات الإدارة: من، ماذا، متى',
        icon: Icons.history,
        page: const AdminAuditScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
          ),
        ],
      ),
      body: AdminGate(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<String?>(
                future: _role,
                builder: (context, snap) {
                  return FutureBuilder<String>(
                    future: _aal,
                    builder: (context, aalSnap) {
                      final role = snap.data ?? '—';
                      final aal = aalSnap.data ?? 'unknown';
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.admin_panel_settings),
                          ),
                          title: Text(admin.currentEmail ?? '—'),
                          subtitle: Text(
                            'الدور: $role • مستوى المصادقة: $aal\n'
                            '${aal == 'aal2' ? 'المصادقة الثنائية مفعّلة لهذا الحساب.' : 'ننصح بتفعيل المصادقة الثنائية (TOTP) لحسابات الإدارة من لوحة Supabase.'}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, int>>(
                future: _stats,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Text('تعذّر تحميل الإحصائيات: ${snap.error}');
                  }
                  final s = snap.data!;
                  final cells = <(String, String)>[
                    ('المستخدمون', '${s['users']}'),
                    ('الأذكار', '${s['azkar']}'),
                    ('أذكار بانتظار المراجعة', '${s['azkarPending']}'),
                    ('الأحاديث', '${s['hadith']}'),
                    ('أحاديث بانتظار المراجعة', '${s['hadithPending']}'),
                    ('بلاغات مفتوحة', '${s['reportsOpen']}'),
                    ('كل البلاغات', '${s['reportsTotal']}'),
                    ('إشعارات غير مرسلة', '${s['notificationsPending']}'),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إحصائيات مجمّعة (أعداد فقط — لا توجد بيانات عبادات فردية في الخادم)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.4,
                        children: cells
                            .map((c) => Card(
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          c.$2,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(c.$1,
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              ...entries.map(
                (e) => Card(
                  child: ListTile(
                    leading: Icon(e.icon),
                    title: Text(e.title),
                    subtitle: Text(e.subtitle),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => e.page))
                        .then((_) => _reload()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

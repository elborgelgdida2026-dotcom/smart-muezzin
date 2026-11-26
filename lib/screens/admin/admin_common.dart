import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

/// Shared widgets for the admin panel (spec section 27).
///
/// Rule enforced everywhere: when Supabase is not configured, the panel
/// shows the setup instructions — never fake users or fake content.
/// When the signed-in account is not staff, it shows a plain denial.
class AdminSetupView extends StatelessWidget {
  const AdminSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Icon(Icons.cloud_off, size: 56, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'لوحة الإدارة غير متصلة بعد',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          'هذه اللوحة تحتاج مشروع Supabase حيًا. لا توجد بيانات وهمية هنا '
          'عن قصد — لن ترى مستخدمين أو محتوى إلا بعد الربط.',
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'خطوات الربط (التفاصيل الكاملة في supabase/README.md):\n\n'
          '1. أنشئ مشروعًا على supabase.com/dashboard\n'
          '2. شغّل في SQL Editor بالترتيب: schema.sql ثم rls.sql ثم seed.sql\n'
          '3. أنشئ حسابًا من شاشة الدخول، ثم ارفع دوره إلى admin بهذا الأمر:\n'
          '   update public.profiles set role = \'admin\'\n'
          '   where email = \'admin@example.com\';\n'
          '4. ضع في ملف .env:\n'
          '   SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co\n'
          '   SUPABASE_ANON_KEY=eyJhbGciOi...\n'
          '5. أعد تشغيل التطبيق وسجّل الدخول من جديد.',
        ),
      ],
    );
  }
}

class AdminDeniedView extends StatelessWidget {
  const AdminDeniedView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message ?? 'هذا الحساب ليس مشرفًا أو مديرًا.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'دخول لوحة الإدارة مقصور على أدوار moderator و admin. '
              'يتم رفع الدور من قاعدة البيانات فقط (انظر supabase/README.md) — '
              'لا يمكن للمستخدم رفع دوره بنفسه.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gate widget: initialises the admin backend, then shows [child] only to
/// staff, the setup view when unconfigured, and the denial otherwise.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key, required this.child});
  final Widget child;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = AdminService.instance.ensureInitialized().then(
          (_) => AdminService.instance.refreshState(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('تعذّر الاتصال بالخادم: ${snapshot.error}'),
            ),
          );
        }
        return ValueListenableBuilder<AdminState>(
          valueListenable: AdminService.instance.state,
          builder: (context, state, _) {
            switch (state) {
              case AdminState.unconfigured:
                return const AdminSetupView();
              case AdminState.signedOut:
              case AdminState.nonAdmin:
                return const AdminDeniedView();
              case AdminState.moderator:
              case AdminState.admin:
                return widget.child;
            }
          },
        );
      },
    );
  }
}

/// Small helpers shared by the admin screens.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void showAdminSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
    ),
  );
}

String formatAdminDate(String? iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final y = d.year.toString();
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}

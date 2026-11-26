import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';
import 'admin_home_screen.dart';

/// Admin sign-in (Supabase Auth, email + password).
///
/// Notes shown honestly in the UI:
/// * A new account is always created with role 'user'. Promotion to admin
///   happens only with the SQL in supabase/README.md.
/// * MFA (TOTP) is enforced in the Supabase dashboard; the panel reports
///   the account's assurance level after sign-in (see AdminHomeScreen).
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signingUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'أدخل بريدًا صحيحًا وكلمة مرور من 6 أحرف على الأقل.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final admin = AdminService.instance;
      if (_signingUp) {
        await admin.signUp(email, password, _name.text.trim());
        if (!mounted) return;
        showAdminSnack(
          context,
          'تم إنشاء الحساب بدور مستخدم عادي. لرفعه إلى مدير استخدم أمر SQL في supabase/README.md ثم سجّل الدخول.',
        );
        setState(() => _signingUp = false);
      } else {
        final isStaff = await admin.signIn(email, password);
        if (!mounted) return;
        if (isStaff) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        } else {
          setState(() => _error =
              'تم تسجيل الدخول، لكن هذا الحساب ليس مشرفًا أو مديرًا.');
        }
      }
    } on AdminNotConfigured {
      setState(() => _error =
          'Supabase غير متصل. راجع خطوات الربط في supabase/README.md.');
    } catch (e) {
      setState(() => _error = 'تعذّر تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم الإدارة')),
      body: FutureBuilder<void>(
        future: admin.ensureInitialized(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!admin.isConfigured) {
            return const AdminSetupView();
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/smart-muezzin-logo.jpg',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _signingUp ? 'إنشاء حساب إداري' : 'تسجيل دخول الإدارة',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'الدخول مقصور على أدوار moderator و admin. الحساب الجديد '
                'يُنشأ بدور مستخدم عادي، ورفعه يتم من قاعدة البيانات فقط.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_signingUp)
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الظاهر',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_signingUp) const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy
                    ? 'جارٍ...'
                    : _signingUp
                        ? 'إنشاء الحساب'
                        : 'تسجيل الدخول'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _signingUp = !_signingUp),
                child: Text(_signingUp
                    ? 'لدي حساب بالفعل — تسجيل الدخول'
                    : 'إنشاء حساب جديد'),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              const Text(
                'ملاحظة عن المصادقة الثنائية (MFA): فعّل TOTP من لوحة '
                'Supabase (Authentication → MFA) واطلبها لحسابات الإدارة. '
                'التطبيق لا يخزّن كلمات المرور — Supabase Auth هو من يفعل.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}

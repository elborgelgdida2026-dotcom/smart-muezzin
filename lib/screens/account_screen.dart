import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/user_sync_service.dart';

/// User account & cloud sync — OPTIONAL. The app works fully without
/// an account; this screen only adds an optional Supabase sign-in and
/// an explicit-consent sync toggle (settings, favourites, Tasbih,
/// worship log, Khatma plan, reading position).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _sync = UserSyncService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  bool _signUpMode = false;
  bool _signedIn = false;
  bool _enabled = false;
  String? _lastSync;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final signedIn = await _sync.isSignedIn;
    final enabled = await _sync.isEnabled;
    final last = await _sync.lastSync;
    if (mounted) {
      setState(() {
        _signedIn = signedIn;
        _enabled = enabled;
        _lastSync = last;
      });
    }
  }

  void _setMessage(String m) => setState(() => _message = m);

  Future<void> _run(Future<void> Function() fn, String okMessage) async {
    setState(() => _busy = true);
    try {
      await fn();
      _setMessage(okMessage);
      await _refresh();
    } catch (e) {
      _setMessage('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_sync.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('حسابي والمزامنة')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'الحسابات والمزامنة غير مفعّلة لأن مشروع Supabase غير موصول '
            'بعد. التطبيق يعمل كاملًا دون حساب. لربط Supabase اتبع خطوات '
            'supabase/README.md ثم أعد تشغيل التطبيق.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي والمزامنة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'الحساب اختياري تمامًا — التطبيق يعمل كاملًا دون تسجيل دخول. '
            'المزامنة لا ترفع شيئًا إلا بعد تفعيلها هنا صراحةً، ويمكنك '
            'إيقافها وحذف نسختك السحابية في أي وقت.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (!_signedIn) ...[
            if (_signUpMode)
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'الاسم (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                        () => _signUpMode
                            ? _sync.signUp(
                                _email.text.trim(),
                                _password.text,
                                _name.text.trim(),
                              )
                            : _sync.signIn(
                                _email.text.trim(), _password.text),
                        _signUpMode
                            ? 'تم إنشاء الحساب — تحقق من بريدك إن طُلب ذلك، ثم سجّل الدخول.'
                            : 'تم تسجيل الدخول.',
                      ),
              child: Text(_signUpMode ? 'إنشاء حساب' : 'تسجيل الدخول'),
            ),
            TextButton(
              onPressed: () => setState(() => _signUpMode = !_signUpMode),
              child: Text(_signUpMode
                  ? 'لدي حساب بالفعل — تسجيل الدخول'
                  : 'ليس لدي حساب — إنشاء حساب جديد'),
            ),
          ] else ...[
            ListTile(
              title: Text('مسجّل الدخول: ${_sync.currentEmail ?? ''}'),
              trailing: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => _sync.signOut(), 'تم تسجيل الخروج.'),
                child: const Text('تسجيل الخروج'),
              ),
            ),
            SwitchListTile(
              title: const Text('المزامنة السحابية'),
              subtitle: const Text(
                  'عند التفعيل تُرفع نسخة احتياطية من إعداداتك ومفضلتك '
                  'وسجل عبادتك وخطة ختمتك إلى حسابك فقط.'),
              value: _enabled,
              onChanged: (v) async {
                await _sync.setEnabled(v);
                await _refresh();
              },
            ),
            if (_lastSync != null)
              Text('آخر مزامنة: $_lastSync',
                  style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('ارفع نسختي الآن'),
              onPressed: _busy
                  ? null
                  : () => _run(
                        () => _sync.uploadNow(widget.settings),
                        'تم رفع نسختك السحابية.',
                      ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_download),
              label: const Text('استعد نسختي السحابية'),
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('استعادة النسخة السحابية؟'),
                          content: const Text(
                              'ستُستبدل بياناتك المحلية الحالية بالنسخة '
                              'السحابية. تأكد أن النسخة السحابية أحدث.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('إلغاء')),
                            TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('استعادة')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _run(
                          () async {
                            final restored = await _sync
                                .restoreFromCloud(widget.settings);
                            if (!restored) {
                              throw StateError(
                                  'لا توجد نسخة سحابية بعد، أو تعذرت الاستعادة.');
                            }
                          },
                          'تمت الاستعادة من النسخة السحابية.',
                        );
                      }
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('احذف نسختي السحابية'),
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('حذف النسخة السحابية؟'),
                          content: const Text(
                              'سيُحذف ما رُفع إلى حسابك نهائيًا، وتبقى '
                              'بياناتك المحلية على جهازك.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('إلغاء')),
                            TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('حذف')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _run(
                          () => _sync.deleteCloudCopy(),
                          'تم حذف نسختك السحابية.',
                        );
                      }
                    },
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    );
  }
}

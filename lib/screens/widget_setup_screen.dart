import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/widget_service.dart';

/// Home-screen widget setup & explanation.
///
/// HOW TO ADD IT (Android): long-press the home screen → Widgets →
/// "المؤذن الذكي" → drag "الصلاة القادمة" to the home screen.
/// The widget shows the next prayer, its time and a countdown in
/// minutes; it refreshes when the app runs and when the user taps
/// "تحديث الودجت الآن".
///
/// HONEST LIMIT — LOCK SCREEN: Android 12 and later removed
/// lock-screen widgets from the operating system, so no app can put
/// a live widget on the lock screen. On the lock screen this app can
/// only show a notification (prayer reminders from Settings →
/// Reminders). Anyone promising a lock-screen Adhan widget on modern
/// Android is not describing what the OS allows.
class WidgetSetupScreen extends StatefulWidget {
  const WidgetSetupScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<WidgetSetupScreen> createState() => _WidgetSetupScreenState();
}

class _WidgetSetupScreenState extends State<WidgetSetupScreen> {
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ودجت الشاشة الرئيسية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ودجت «الصلاة القادمة»',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'يعرض الودجت على شاشتك الرئيسية: اسم الصلاة القادمة، '
                    'وقتها، والوقت المتبقي لها بالدقائق، واسم مدينتك.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('لإضافة الودجت:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text(
            '1 — اضغط مطولًا على مساحة فارغة في الشاشة الرئيسية.\n'
            '2 — اختر «الودجت» (Widgets).\n'
            '3 — ابحث عن «المؤذن الذكي» واسحب ودجت «الصلاة القادمة» '
            'إلى الشاشة الرئيسية.',
            style: TextStyle(fontSize: 15, height: 1.8),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث الودجت الآن'),
            onPressed: () async {
              await WidgetService.updateNow(widget.settings);
              if (mounted) {
                setState(() => _message =
                    'تم تحديث بيانات الودجت. إن لم يظهر الودجت بعد، أضفه من قائمة الودجت كما في الخطوات أعلاه.');
              }
            },
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Text(
              'شاشة القفل: أندرويد 12 وما بعده ألغى ودجت شاشة القفل من '
              'نظام التشغيل نفسه، فلا يمكن لأي تطبيق وضع ودجت حي على شاشة '
              'القفل. ما يظهر على شاشة القفل هو إشعار التذكير بالصلاة فقط '
              '(من الإعدادات ← التذكيرات).',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

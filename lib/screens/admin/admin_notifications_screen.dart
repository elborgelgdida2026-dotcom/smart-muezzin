import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';

/// Draft and schedule public announcements. Sending is an explicit,
/// confirmed step. Honest scope note shown in the UI: marking a
/// notification "sent" records it in the backend; actual push delivery
/// to devices is outside this build (it needs a push provider wired to
/// the `notifications` table) — the panel never claims a push was
/// delivered when it was only recorded.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _items = AdminService.instance.fetchTable('notifications', limit: 100);
    setState(() {});
  }

  Future<void> _create() async {
    final titleAr = TextEditingController();
    final titleEn = TextEditingController();
    final bodyAr = TextEditingController();
    final bodyEn = TextEditingController();
    String audience = 'all';
    DateTime? scheduledAt;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إشعار عام جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleAr,
                  decoration: const InputDecoration(
                    labelText: 'العنوان بالعربية *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyAr,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'النص بالعربية *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleEn,
                  decoration: const InputDecoration(
                    labelText: 'العنوان بالإنجليزية (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyEn,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'النص بالإنجليزية (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: audience,
                  decoration: const InputDecoration(
                    labelText: 'الجمهور المستهدف',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الجميع')),
                    DropdownMenuItem(
                        value: 'moderators', child: Text('المشرفون')),
                    DropdownMenuItem(value: 'admins', child: Text('المديرون')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => audience = v ?? 'all'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(scheduledAt == null
                          ? 'بدون جدولة (مسودة)'
                          : 'مجدول: ${scheduledAt!.toLocal()}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          scheduledAt = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                        });
                      },
                      child: const Text('جدولة'),
                    ),
                  ],
                ),
                if (error != null)
                  Text(error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleAr.text.trim().isEmpty ||
                    bodyAr.text.trim().isEmpty) {
                  setDialogState(
                      () => error = 'العنوان والنص بالعربية إلزاميان.');
                  return;
                }
                try {
                  await AdminService.instance.createNotification(
                    titleAr: titleAr.text.trim(),
                    titleEn: titleEn.text.trim().isEmpty
                        ? null
                        : titleEn.text.trim(),
                    bodyAr: bodyAr.text.trim(),
                    bodyEn: bodyEn.text.trim().isEmpty
                        ? null
                        : bodyEn.text.trim(),
                    audience: audience,
                    scheduledAt: scheduledAt,
                  );
                  if (context.mounted) Navigator.of(context).pop(true);
                } catch (e) {
                  setDialogState(() => error = 'تعذّر الحفظ: $e');
                }
              },
              child: const Text('حفظ كمسودة'),
            ),
          ],
        ),
      ),
    );
    titleAr.dispose();
    titleEn.dispose();
    bodyAr.dispose();
    bodyEn.dispose();
    if (saved == true) {
      if (mounted) showAdminSnack(context, 'تم حفظ الإشعار كمسودة.');
      _load();
    }
  }

  Future<void> _markSent(Map<String, dynamic> n) async {
    final ok = await confirmDialog(
      context,
      title: 'تأكيد الإرسال',
      message: 'سيُسجَّل هذا الإشعار كمُرسَل في قاعدة البيانات. '
          'ملاحظة: التسليم الفعلي (push) للأجهزة يحتاج موفّر دفع مربوطًا '
          'بجدول notifications، وهو خارج هذه النسخة — لن يُدَّعى وصوله '
          'للمستخدمين قبل ربطه. هل تريد المتابعة؟',
      confirmLabel: 'تأكيد الإرسال',
    );
    if (!ok) return;
    try {
      await AdminService.instance.markNotificationSent(n['id'].toString());
      if (mounted) {
        showAdminSnack(context, 'تم تسجيل الإشعار كمُرسَل.');
        _load();
      }
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر التسجيل: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات العامة')),
      body: AdminGate(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _items,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('تعذّر التحميل: ${snap.error}'));
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const Center(
                child: Text('لا توجد إشعارات بعد. أنشئ أول إشعار من الزر +'),
              );
            }
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                final sent = n['sent_at'] != null;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(n['title_ar']?.toString() ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['body_ar']?.toString() ?? ''),
                        Text(
                          'الجمهور: ${n['target_audience']} • '
                          '${sent ? 'أُرسل: ${formatAdminDate(n['sent_at']?.toString())}' : n['scheduled_at'] != null ? 'مجدول: ${formatAdminDate(n['scheduled_at']?.toString())}' : 'مسودة'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: sent
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () => _markSent(n),
                            child: const Text('إرسال'),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: 'إشعار جديد',
        child: const Icon(Icons.add),
      ),
    );
  }
}

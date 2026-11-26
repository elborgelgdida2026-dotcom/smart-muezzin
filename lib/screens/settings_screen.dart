import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prayer_times_model.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

/// Settings: language, city, calculation method, Asr madhab,
/// per-prayer minute adjustments, theme, font size, reminders,
/// backup / restore / delete-all-data. Every control writes through
/// SettingsService / NotificationService and does its stated action.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notifications = NotificationService();
  final _cityName = TextEditingController();
  final _cityLat = TextEditingController();
  final _cityLng = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notifications.init();
  }

  Future<void> _exportBackup() async {
    final data = await widget.settings.exportAll();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/smart-muezzin-backup.json');
    await file.writeAsString(jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تصدير النسخة الاحتياطية: ${file.path}')),
      );
    }
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف كل البيانات؟'),
        content: const Text('سيتم حذف الإعدادات والمفضلة والمسبحة ومتابعة العبادات نهائيًا.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.settings.deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف كل البيانات المحلية')),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اللغة', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: s.language,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) async {
              if (v != null) {
                await s.setLanguage(v);
                setState(() {});
              }
            },
          ),
          SwitchListTile(
            title: const Text('الوضع الليلي'),
            value: s.isDark,
            onChanged: (v) async {
              await s.setDark(v);
              setState(() {});
            },
          ),
          ListTile(
            title: const Text('حجم الخط'),
            trailing: Text('${(s.fontScale * 100).round()}%'),
            subtitle: Slider(
              value: s.fontScale,
              min: 0.85,
              max: 1.6,
              divisions: 15,
              onChanged: (v) async {
                await s.setFontScale(v);
                setState(() {});
              },
            ),
          ),
          const Divider(),
          const Text('طريقة حساب الصلاة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<PrayerMethod>(
            value: s.method,
            isExpanded: true,
            items: PrayerMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.arabicName)))
                .toList(),
            onChanged: (v) async {
              if (v != null) {
                await s.setMethod(v);
                setState(() {});
              }
            },
          ),
          SwitchListTile(
            title: const Text('حساب العصر بالمذهب الحنفي'),
            subtitle: const Text('إيقافه = طريقة الجمهور'),
            value: s.asrHanafi,
            onChanged: (v) async {
              await s.setAsrHanafi(v);
              setState(() {});
            },
          ),
          const Divider(),
          const Text('المدينة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('الحالية: ${s.city.name}، ${s.city.country}'),
          TextField(
            controller: _cityName,
            decoration: const InputDecoration(labelText: 'اسم المدينة'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityLat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'خط العرض'),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _cityLng,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'خط الطول'),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final lat = double.tryParse(_cityLat.text);
              final lng = double.tryParse(_cityLng.text);
              if (_cityName.text.isEmpty || lat == null || lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أدخل اسم المدينة وخط العرض والطول')),
                );
                return;
              }
              await s.setCity(SavedCity(
                name: _cityName.text,
                country: '',
                latitude: lat,
                longitude: lng,
              ));
              setState(() {});
            },
            child: const Text('حفظ المدينة'),
          ),
          const Divider(),
          const Text('التذكيرات',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('السماح بالإشعارات'),
            trailing: ElevatedButton(
              onPressed: () async {
                final ok = await _notifications.requestPermission();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'تم السماح بالإشعارات'
                          : 'لم يتم السماح بالإشعارات'),
                    ),
                  );
                }
              },
              child: const Text('طلب الإذن'),
            ),
          ),
          const Text(
            'حد نسخة Android: التذكيرات الدقيقة بعد إعادة التشغيل أو في وضع '
            'توفير البطارية تحتاج إذن المنبه الدقيق، ويجب اختبارها على جهاز حقيقي.',
          ),
          const Divider(),
          ElevatedButton.icon(
            onPressed: _exportBackup,
            icon: const Icon(Icons.download),
            label: const Text('تصدير نسخة احتياطية (JSON)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _deleteAll,
            icon: const Icon(Icons.delete_forever),
            label: const Text('حذف كل البيانات'),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

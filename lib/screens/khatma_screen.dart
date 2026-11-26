import 'package:flutter/material.dart';
import '../services/khatma_service.dart';

/// Khatma plan: read the whole Mushaf (604 pages) in a chosen number
/// of days. Daily pages are computed from 604; progress and the daily
/// reminder are stored locally.
class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({super.key});
  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  final _service = KhatmaService();
  KhatmaPlan? _plan;
  bool _loading = true;
  int _selectedDays = 30;
  final _customController = TextEditingController();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await _service.loadPlan();
    if (mounted) {
      setState(() {
        _plan = plan;
        _loading = false;
        if (plan != null) {
          _reminderTime =
              TimeOfDay(hour: plan.reminderHour, minute: plan.reminderMinute);
        }
      });
    }
  }

  Future<void> _create() async {
    final custom = int.tryParse(_customController.text.trim());
    final plan = await _service.createPlan(
      targetDays: _selectedDays,
      customDailyPages: custom,
      reminderEnabled: true,
      reminderHour: _reminderTime.hour,
      reminderMinute: _reminderTime.minute,
    );
    setState(() => _plan = plan);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'بدأت الختمة: ${plan.pagesPerDay} صفحات يوميًا لمدة ${plan.targetDays} يومًا')),
      );
    }
  }

  Future<void> _markRead() async {
    if (_plan == null) return;
    final updated = await _service.markRead(_plan!);
    setState(() => _plan = updated);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    if (_plan != null) {
      final updated = await _service.setReminder(
        _plan!,
        enabled: _plan!.reminderEnabled,
        hour: picked.hour,
        minute: picked.minute,
      );
      setState(() => _plan = updated);
    }
  }

  Future<void> _toggleReminder(bool v) async {
    if (_plan == null) return;
    final updated = await _service.setReminder(_plan!, enabled: v);
    setState(() => _plan = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطة الختمة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? _buildCreate()
              : _buildPlan(),
    );
  }

  Widget _buildCreate() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'اختر مدة الختمة — يحسب التطبيق صفحاتك اليومية من 604 صفحات المصحف كاملة.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [7, 14, 30, 90].map((d) {
            return ChoiceChip(
              label: Text('$d يومًا (${KhatmaService.pagesPerDayFor(d)} صفحة/يوم)'),
              selected: _selectedDays == d,
              onSelected: (_) => setState(() => _selectedDays = d),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _customController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'أو عدد صفحات يومي مخصص (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('تذكير يومي بالورد'),
          subtitle: Text('الساعة ${_reminderTime.format(context)}'),
          trailing: const Icon(Icons.alarm),
          onTap: _pickReminderTime,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _create,
          child: const Text('ابدأ الختمة'),
        ),
      ],
    );
  }

  Widget _buildPlan() {
    final p = _plan!;
    final percent = (p.progress * 100).toStringAsFixed(0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  p.isComplete ? 'تقبّل الله — أتممت الختمة 🎉' : 'تقدّم الختمة',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: p.progress),
                const SizedBox(height: 8),
                Text('$percent% — قرأت ${p.pagesRead} من 604 صفحات'),
                Text('متبقٍ ${p.pagesLeft} صفحة • نحو ${p.daysLeftAtPace} يومًا بالوتيرة الحالية'),
                Text('الصفحة التالية: ${p.isComplete ? '—' : p.currentPage}'),
                Text('تنتهي الخطة: ${p.targetEndDate.year}/${p.targetEndDate.month}/${p.targetEndDate.day}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!p.isComplete)
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: Text('أنجزت ورد اليوم (${p.pagesPerDay} صفحات)'),
            onPressed: _markRead,
          ),
        if (p.isComplete)
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('ابدأ ختمة جديدة'),
            onPressed: () async {
              await _service.deletePlan();
              setState(() => _plan = null);
            },
          ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('تذكير يومي بالورد'),
          subtitle: Text('الساعة ${_reminderTime.format(context)} — اضغط لتغيير الوقت'),
          value: p.reminderEnabled,
          onChanged: _toggleReminder,
        ),
        TextButton(
          onPressed: _pickReminderTime,
          child: const Text('تغيير وقت التذكير'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('إلغاء الختمة؟'),
                content: const Text('سيُحذف تقدم الختمة الحالية نهائيًا.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('إلغاء')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('حذف الخطة')),
                ],
              ),
            );
            if (ok == true) {
              await _service.deletePlan();
              setState(() => _plan = null);
            }
          },
          child: const Text('إلغاء الخطة'),
        ),
      ],
    );
  }
}

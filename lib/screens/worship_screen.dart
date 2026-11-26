import 'package:flutter/material.dart';
import '../services/worship_service.dart';

/// Worship tracking: a local daily log of prayers, fasting, Quran
/// pages, Azkar and Tasbih — with a weekly bar chart, streaks and a
/// monthly summary. LOCAL ONLY: nothing here is uploaded anywhere.
/// The log records what the user entered; it is a reminder tool, not
/// a judgement of anyone's worship.
class WorshipScreen extends StatefulWidget {
  const WorshipScreen({super.key});
  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  final _service = WorshipService();
  WorshipDay? _today;
  int _streak = 0;
  List<({String label, int prayers})> _week = [];
  ({int daysLogged, int prayers, int fastingDays, int quranPages, int tasbih})
      _month = (daysLogged: 0, prayers: 0, fastingDays: 0, quranPages: 0, tasbih: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final now = DateTime.now();
    final today = await _service.day(now);
    final streak = await _service.streak();
    final week = await _service.lastWeek();
    final month = await _service.monthSummary(now.year, now.month);
    if (mounted) {
      setState(() {
        _today = today;
        _streak = streak;
        _week = week;
        _month = month;
        _loading = false;
      });
    }
  }

  Future<void> _togglePrayer(String key) async {
    final updated =
        await _service.togglePrayer(DateTime.now(), key);
    setState(() => _today = updated);
    _refresh();
  }

  Future<void> _editField(
    String title,
    int current,
    Future<void> Function(int) save,
  ) async {
    final controller = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () =>
                Navigator.pop(c, int.tryParse(controller.text) ?? current),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (value != null) {
      await save(value);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع العبادات')),
      body: _loading || _today == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'سجل محلي فقط — لا يُرفع لأي خادم. سجّل ما أديته لتتابع '
                  'نفسك، لا ليحكم عليك أحد.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard('سلسلة الأيام الكاملة', '$_streak يوم'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                          'صلوات اليوم', '${_today!.prayersCount} / 5'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('صلوات اليوم',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: WorshipService.prayerKeys.map((key) {
                    final done = _today!.prayers[key] ?? false;
                    return FilterChip(
                      label: Text(WorshipService.prayerNames[key]!),
                      selected: done,
                      onSelected: (_) => _togglePrayer(key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('صائم اليوم'),
                  value: _today!.fasting,
                  onChanged: (v) async {
                    await _service
                        .saveDay(_today!.copyWith(fasting: v));
                    _refresh();
                  },
                ),
                SwitchListTile(
                  title: const Text('أكملت أذكار اليوم'),
                  value: _today!.azkarDone,
                  onChanged: (v) async {
                    await _service
                        .saveDay(_today!.copyWith(azkarDone: v));
                    _refresh();
                  },
                ),
                ListTile(
                  title: const Text('صفحات القرآن المقروءة اليوم'),
                  trailing: Text('${_today!.quranPages}'),
                  onTap: () => _editField(
                    'صفحات القرآن المقروءة اليوم',
                    _today!.quranPages,
                    (v) async => _service.saveDay(
                        _today!.copyWith(quranPages: v)),
                  ),
                ),
                ListTile(
                  title: const Text('عدد التسبيح اليوم'),
                  trailing: Text('${_today!.tasbih}'),
                  onTap: () => _editField(
                    'عدد التسبيح اليوم',
                    _today!.tasbih,
                    (v) async => _service.saveDay(
                        _today!.copyWith(tasbih: v)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('الصلوات في آخر 7 أيام',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    painter: _WeekBarPainter(_week),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ملخص الشهر الحالي',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _summaryRow('أيام مسجلة', '${_month.daysLogged}'),
                _summaryRow('صلوات مسجلة', '${_month.prayers}'),
                _summaryRow('أيام صيام', '${_month.fastingDays}'),
                _summaryRow('صفحات قرآن', '${_month.quranPages}'),
                _summaryRow('تسبيح', '${_month.tasbih}'),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}

/// Simple weekly bar chart drawn with CustomPaint (no extra chart
/// dependency): one bar per day, height = prayers logged (0..5).
class _WeekBarPainter extends CustomPainter {
  _WeekBarPainter(this.week);
  final List<({String label, int prayers})> week;

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = const Color(0xFF0B7A5B);
    final emptyPaint = Paint()..color = const Color(0xFFCCCCCC);
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight - 8;
    final slot = size.width / week.length;
    final barWidth = slot * 0.5;
    for (var i = 0; i < week.length; i++) {
      final value = week[i].prayers;
      final h = chartHeight * (value / 5);
      final x = i * slot + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, chartHeight - h, barWidth, h),
          const Radius.circular(4),
        ),
        value == 0 ? emptyPaint : barPaint,
      );
      textPainter.text = TextSpan(
        text: week[i].label,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      );
      textPainter.layout(minWidth: slot, maxWidth: slot);
      textPainter.paint(canvas, Offset(i * slot, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _WeekBarPainter old) => old.week != week;
}

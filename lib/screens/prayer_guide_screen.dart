import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/prayer_guide.dart';

/// Full adult prayer & wudu guide with a follow-along checklist
/// (persisted locally). Quranic verses and duas are quoted verbatim
/// from the sources named in each item; differences between schools
/// are presented with attribution, never as a single imposed truth.
class PrayerGuideScreen extends StatefulWidget {
  const PrayerGuideScreen({super.key});
  @override
  State<PrayerGuideScreen> createState() => _PrayerGuideScreenState();
}

class _PrayerGuideScreenState extends State<PrayerGuideScreen> {
  static const _kDone = 'prayer_guide_done';
  Set<String> _done = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _done = (prefs.getStringList(_kDone) ?? []).toSet();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDone, _done.toList());
  }

  Future<void> _toggleDone(String id) async {
    setState(() {
      if (_done.contains(id)) {
        _done.remove(id);
      } else {
        _done.add(id);
      }
    });
    await _save();
  }

  Future<void> _reset() async {
    setState(() => _done.clear());
    await _save();
  }

  int get _totalCheckable => prayerGuide.fold(
        0,
        (n, s) => n + s.items.where((i) => i.checkable).length,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الصلاة والوضوء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة تعيين المتابعة',
            onPressed: _done.isEmpty ? null : _reset,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'دليل كامل للكبار: الوضوء والتيمم والغسل، والصلوات '
                      'الخمس خطوة بخطوة، والجماعة والمسافر والمريض والجمعة '
                      'والعيد والجنازة. تابعت $_totalCheckable خطوة، أنجزت '
                      '${_done.length} منها. الآيات والأدعية منقولة حرفيًا '
                      'من مصادرها المذكورة، ومواضع الخلاف بين المذاهب '
                      'مذكورة كما هي — راجع عالمًا موثوقًا للتفاصيل.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final section in prayerGuide) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      section.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      section.intro,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  for (final item in section.items) _itemCard(item),
                ],
              ],
            ),
    );
  }

  Widget _itemCard(GuideItem item) {
    final isDone = _done.contains(item.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (item.checkable)
                  Checkbox(
                    value: isDone,
                    onChanged: (_) => _toggleDone(item.id),
                  ),
              ],
            ),
            if (item.body != null) Text(item.body!),
            if (item.bullets != null) ...[
              const SizedBox(height: 6),
              for (final b in item.bullets!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(b)),
                    ],
                  ),
                ),
            ],
            if (item.quote != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.quote!,
                      style: const TextStyle(
                          fontFamily: 'Amiri', fontSize: 18, height: 1.8),
                      textDirection: TextDirection.rtl,
                    ),
                    if (item.quoteSource != null)
                      Text('المصدر: ${item.quoteSource!}',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (item.note != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'تنبيه: ${item.note!}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

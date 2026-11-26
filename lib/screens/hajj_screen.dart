import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/hajj_steps.dart';

/// Hajj & Umrah step-by-step guide with counters (Tawaf 7, Sa'i 7,
/// stoning 7 per Jamarah) and a checklist that persists locally.
/// Duas are quoted verbatim from the collections named in each step.
class HajjScreen extends StatefulWidget {
  const HajjScreen({super.key});
  @override
  State<HajjScreen> createState() => _HajjScreenState();
}

class _HajjScreenState extends State<HajjScreen> {
  static const _kDone = 'hajj_done_steps';
  static const _kCounts = 'hajj_counters';
  Set<String> _done = {};
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = (prefs.getStringList(_kDone) ?? []).toSet();
    final counts = <String, int>{};
    for (final e in prefs.getStringList(_kCounts) ?? []) {
      final parts = e.split(':');
      if (parts.length == 2) {
        counts[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    if (mounted) {
      setState(() {
        _done = done;
        _counts = counts;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDone, _done.toList());
    await prefs.setStringList(
      _kCounts,
      _counts.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
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

  Future<void> _increment(String id, int target) async {
    setState(() {
      _counts[id] = ((_counts[id] ?? 0) + 1).clamp(0, target);
    });
    await _save();
  }

  Future<void> _resetCounter(String id) async {
    setState(() => _counts[id] = 0);
    await _save();
  }

  int get _totalSteps =>
      hajjGuide.fold(0, (n, s) => n + s.steps.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دليل الحج والعمرة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'أنجزت ${_done.length} من $_totalSteps خطوة. '
                      'الأدعية منقولة حرفيًا من كتب السنة المذكورة في كل خطوة، '
                      'والمناسك تختلف بين المذاهب والظروف — راجع عالمًا موثوقًا '
                      'أو كتاب مناسك معتمدًا للتفاصيل.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final section in hajjGuide) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      section.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final step in section.steps) _stepCard(step),
                ],
              ],
            ),
    );
  }

  Widget _stepCard(HajjStep step) {
    final isDone = _done.contains(step.id);
    final count = _counts[step.id] ?? 0;
    final target = step.counterTarget ?? 0;
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
                    step.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Checkbox(
                  value: isDone,
                  onChanged: (_) => _toggleDone(step.id),
                ),
              ],
            ),
            Text(step.description),
            if (step.dua != null) ...[
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
                      step.dua!,
                      style: const TextStyle(
                          fontFamily: 'Amiri', fontSize: 18, height: 1.8),
                      textDirection: TextDirection.rtl,
                    ),
                    if (step.duaSource != null)
                      Text('المصدر: ${step.duaSource!}',
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (target > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text('$count / $target ${step.counterLabel ?? ''}'),
                    onPressed: count >= target
                        ? null
                        : () => _increment(step.id, target),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: count == 0
                        ? null
                        : () => _resetCounter(step.id),
                    child: const Text('إعادة العدّاد'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

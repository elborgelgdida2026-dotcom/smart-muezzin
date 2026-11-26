import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/azkar.dart';
import '../services/azkar_service.dart';

/// Azkar tab: categories from Hisn al-Muslim, each zikr with its source
/// and fixed repetition count, plus an interactive counter.
/// Data source: assets/data/azkar.json (bundled, verbatim).
class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});
  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  final _service = AzkarService();
  List<Map<String, dynamic>> _bundled = [];
  String _category = AzkarService.categories.first;
  List<Zikr> _items = [];
  final Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/azkar.json');
      _bundled = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _bundled = [];
    }
    _select(_category);
    if (mounted) setState(() => _loading = false);
  }

  void _select(String category) {
    setState(() {
      _category = category;
      _items = _service.loadCategory(category, _bundled);
      for (final z in _items) {
        _counts.putIfAbsent(z.id, () => 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_bundled.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'ملف الأذكار (assets/data/azkar.json) غير موجود بعد. '
            'أضف الملف من حصن المسلم بنصوصه ومصادره، ثم أعد التشغيل.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: AzkarService.categories.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c),
                  selected: c == _category,
                  onSelected: (_) => _select(c),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final z = _items[i];
              final count = _counts[z.id] ?? 0;
              final finished = count >= z.repetitions;
              return Card(
                child: ListTile(
                  title: Text(z.text,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 19)),
                  subtitle: Text('المصدر: ${z.source}\nالتكرار: ${z.repetitions}'),
                  trailing: ElevatedButton(
                    onPressed: finished
                        ? null
                        : () async {
                            setState(() => _counts[z.id] = count + 1);
                            if (count + 1 >= z.repetitions) {
                              await _service.markDone(z.id);
                            }
                          },
                    child: Text(finished ? 'تم ✓' : '${count + 1} / ${z.repetitions}'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

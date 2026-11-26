import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tasbih_service.dart';

/// Electronic Tasbih: big counter, vibration on tap, target selector,
/// today/total counts persisted locally.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});
  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final _service = TasbihService();
  String _phrase = TasbihService.defaultPhrases.first;
  int _today = 0;
  int _total = 0;
  int _target = 100;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final today = await _service.today();
    final total = await _service.total();
    final target = await _service.target();
    if (mounted) {
      setState(() {
        _today = today;
        _total = total;
        _target = target;
      });
    }
  }

  Future<void> _tap() async {
    final (today, total) = await _service.increment();
    HapticFeedback.lightImpact();
    setState(() {
      _today = today;
      _total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المسبحة الإلكترونية')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _phrase,
              isExpanded: true,
              items: TasbihService.defaultPhrases
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _phrase = v);
              },
            ),
            const SizedBox(height: 24),
            Text(_phrase,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 28),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _tap,
              child: CircleAvatar(
                radius: 90,
                child: Text('$_today',
                    style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 16),
            Text('اليوم: $_today / $_target  •  الإجمالي: $_total'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [33, 100, 500, 1000].map((t) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$t'),
                    selected: _target == t,
                    onSelected: (_) async {
                      await _service.setTarget(t);
                      _refresh();
                    },
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await _service.resetToday();
                _refresh();
              },
              child: const Text('إعادة ضبط عداد اليوم'),
            ),
          ],
        ),
      ),
    );
  }
}

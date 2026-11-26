import 'dart:async';
import 'package:flutter/material.dart';

/// Live countdown to the next prayer, ticking every second.
class CountdownWidget extends StatefulWidget {
  const CountdownWidget({super.key, required this.target, required this.label});
  final DateTime target;
  final String label;

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final d = widget.target.difference(DateTime.now());
    if (mounted) setState(() => _remaining = d.isNegative ? Duration.zero : d);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    return Column(
      children: [
        Text('الصلاة القادمة: ${widget.label}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          '${_two(h)}:${_two(m)}:${_two(s)}',
          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
          textDirection: TextDirection.ltr,
        ),
        const Text('المتبقي على الأذان'),
      ],
    );
  }
}

import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../models/prayer_times_model.dart';
import '../services/prayer_service.dart';
import '../services/settings_service.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/prayer_card.dart';

/// Home tab: live clock (seconds), Gregorian + Hijri dates, next prayer
/// with a live countdown, the six prayer times (current highlighted),
/// and shortcuts to Quran / Qibla / Azkar / Tasbih.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clock;
  DateTime _now = DateTime.now();
  late List<PrayerTimeEntry> _times;
  late ({PrayerTimeEntry entry, Duration remaining}) _next;

  @override
  void initState() {
    super.initState();
    _recompute();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          if (_next.entry.time.isBefore(_now)) _recompute();
        });
      }
    });
  }

  void _recompute() {
    final service = PrayerService(
      method: widget.settings.method,
      madhab: widget.settings.asrHanafi ? Madhab.hanafi : Madhab.shafi,
      adjustments: widget.settings.adjustments,
    );
    _times = service.timesFor(widget.settings.city, _now);
    _next = service.nextPrayer(widget.settings.city, _now);
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.fromDate(_now);
    final gregorian = DateFormat('EEEE، d MMMM yyyy', 'ar').format(_now);
    final clock = DateFormat('HH:mm:ss').format(_now);
    final city = widget.settings.city;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo + app name (user's supplied logo).
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/smart-muezzin-logo.jpg',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المؤذن الذكي',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${city.name}، ${city.country}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Text(clock,
                  style: const TextStyle(fontSize: 20),
                  textDirection: TextDirection.ltr),
            ],
          ),
          const SizedBox(height: 12),
          Text(gregorian, textAlign: TextAlign.center),
          Text(
            '${hijri.hDay} ${hijri.getMonthName()} ${hijri.hYear} هـ',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CountdownWidget(
                target: _next.entry.time,
                label: _next.entry.arabicName,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('مواقيت الصلاة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._times.map((e) => PrayerCard(entry: e)),
        ],
      ),
    );
  }
}

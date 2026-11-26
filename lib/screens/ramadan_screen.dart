import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import '../services/prayer_service.dart';
import '../services/settings_service.dart';

/// Ramadan section: Imsak/Iftar times from the same prayer calculation,
/// a countdown to Iftar, and the Iftar dua. Imsak is shown as Fajr time;
/// the UI states the local convention plainly.
class RamadanScreen extends StatelessWidget {
  const RamadanScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final service = PrayerService(
      method: settings.method,
      madhab: settings.asrHanafi ? Madhab.hanafi : Madhab.shafi,
      adjustments: settings.adjustments,
    );
    final times = service.timesFor(settings.city, now);
    final fajr = times.firstWhere((e) => e.key == 'fajr');
    final maghrib = times.firstWhere((e) => e.key == 'maghrib');
    final toIftar = maghrib.time.isAfter(now)
        ? maghrib.time.difference(now)
        : const Duration();
    return Scaffold(
      appBar: AppBar(title: const Text('رمضان')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('الإمساك (الفجر): ${_fmt(fajr.time)}'),
                    Text('الإفطار (المغرب): ${_fmt(maghrib.time)}'),
                    const SizedBox(height: 8),
                    Text(
                      'المتبقي على الإفطار: ${toIftar.inHours} س '
                      '${toIftar.inMinutes % 60} د',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('دعاء الإفطار',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text(
              'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللهُ',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 22, height: 1.8),
              textAlign: TextAlign.center,
            ),
            const Text('المصدر: سنن أبي داود (2357)، حسنه الألباني',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text(
              'تنبيه: وقت الإمساك يتبع توقيت الفجر المحلي. '
              'راجع إمساكية بلدك الرسمية عند الاختلاف.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

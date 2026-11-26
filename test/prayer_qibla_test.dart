import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_muezzin/services/prayer_service.dart';
import 'package:smart_muezzin/services/qibla_service.dart';
import 'package:smart_muezzin/models/prayer_times_model.dart';

void main() {
  test('Cairo prayer times are computed and ordered', () {
    final city = SavedCity(
      name: 'القاهرة',
      country: 'مصر',
      latitude: 30.0444,
      longitude: 31.2357,
    );
    final service = PrayerService();
    final times = service.timesFor(city, DateTime(2026, 11, 26));
    expect(times.length, 6);
    expect(times.map((e) => e.key).toList(),
        ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']);
    for (var i = 1; i < times.length; i++) {
      expect(times[i].time.isAfter(times[i - 1].time), isTrue);
    }
  });

  test('Qibla bearing from Cairo is roughly south-east', () {
    final bearing = QiblaService.bearing(30.0444, 31.2357);
    // Cairo -> Makkah is ~136 degrees (south-east).
    expect(bearing, greaterThan(120));
    expect(bearing, lessThan(150));
    final distance = QiblaService.distanceKm(30.0444, 31.2357);
    expect(distance, greaterThan(1000));
    expect(distance, lessThan(1500));
  });

  test('Hanafi Asr is later than Shafi Asr', () {
    final city = SavedCity(
      name: 'القاهرة',
      country: 'مصر',
      latitude: 30.0444,
      longitude: 31.2357,
    );
    final shafi = PrayerService(madhab: Madhab.shafi)
        .timesFor(city, DateTime(2026, 11, 26))
        .firstWhere((e) => e.key == 'asr');
    final hanafi = PrayerService(madhab: Madhab.hanafi)
        .timesFor(city, DateTime(2026, 11, 26))
        .firstWhere((e) => e.key == 'asr');
    expect(hanafi.time.isAfter(shafi.time), isTrue);
  });
}

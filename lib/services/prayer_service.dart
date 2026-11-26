import 'package:adhan_dart/adhan_dart.dart';
import '../models/prayer_times_model.dart';

/// Prayer-times calculation using the `adhan_dart` package (the
/// maintained Dart-3 fork of `adhan`).
/// Default method: Egyptian General Authority of Surveying.
/// All computation is local — it works offline once a city is saved.
class PrayerService {
  PrayerService({
    this.method = PrayerMethod.egyptian,
    this.madhab = Madhab.shafi,
    this.adjustments = const {},
  });

  final PrayerMethod method;
  final Madhab madhab;

  /// Per-prayer minute adjustments, e.g. {'fajr': 0, 'maghrib': 2}.
  final Map<String, int> adjustments;

  CalculationParameters _parameters() {
    final CalculationParameters params;
    switch (method) {
      case PrayerMethod.egyptian:
        params = CalculationMethodParameters.egyptian();
        break;
      case PrayerMethod.muslimWorldLeague:
        params = CalculationMethodParameters.muslimWorldLeague();
        break;
      case PrayerMethod.karachi:
        params = CalculationMethodParameters.karachi();
        break;
      case PrayerMethod.northAmerica:
        params = CalculationMethodParameters.northAmerica();
        break;
      case PrayerMethod.ummAlQura:
        params = CalculationMethodParameters.ummAlQura();
        break;
      case PrayerMethod.dubai:
        params = CalculationMethodParameters.dubai();
        break;
      case PrayerMethod.kuwait:
        params = CalculationMethodParameters.kuwait();
        break;
      case PrayerMethod.qatar:
        params = CalculationMethodParameters.qatar();
        break;
      case PrayerMethod.singapore:
        params = CalculationMethodParameters.singapore();
        break;
      case PrayerMethod.turkey:
        // adhan_dart names it Turkiye (Diyanet).
        params = CalculationMethodParameters.turkiye();
        break;
    }
    params.madhab = madhab;
    // High-latitude rule: use the package default (angle-based) behaviour.
    return params;
  }

  DateTime _adj(String key, DateTime t) =>
      t.add(Duration(minutes: adjustments[key] ?? 0));

  /// Compute the six times for [date] at [city].
  List<PrayerTimeEntry> timesFor(SavedCity city, DateTime date) {
    final coords = Coordinates(city.latitude, city.longitude);
    final pt = PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: coords,
      calculationParameters: _parameters(),
    );
    final current = pt.currentPrayer();
    PrayerTimeEntry entry(String key, String name, DateTime t) =>
        PrayerTimeEntry(
          key: key,
          arabicName: name,
          time: _adj(key, t),
          isCurrent: current.name == key,
        );
    return [
      entry('fajr', 'الفجر', pt.fajr),
      entry('sunrise', 'الشروق', pt.sunrise),
      entry('dhuhr', 'الظهر', pt.dhuhr),
      entry('asr', 'العصر', pt.asr),
      entry('maghrib', 'المغرب', pt.maghrib),
      entry('isha', 'العشاء', pt.isha),
    ];
  }

  /// The next prayer after [now], plus the time remaining.
  ({PrayerTimeEntry entry, Duration remaining}) nextPrayer(
      SavedCity city, DateTime now) {
    final times = timesFor(city, now)
        .where((e) => e.key != 'sunrise')
        .toList();
    for (final e in times) {
      if (e.time.isAfter(now)) return (entry: e, remaining: e.time.difference(now));
    }
    // After Isha: tomorrow's Fajr.
    final tomorrow = timesFor(city, now.add(const Duration(days: 1)))
        .firstWhere((e) => e.key == 'fajr');
    return (
      entry: tomorrow,
      remaining: tomorrow.time.difference(now),
    );
  }

  /// Last third of the night and Islamic midnight (local, approximate).
  ({DateTime midnight, DateTime lastThird}) nightPortions(
      SavedCity city, DateTime date) {
    final coords = Coordinates(city.latitude, city.longitude);
    final pt = PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: coords,
      calculationParameters: _parameters(),
    );
    final maghrib = pt.maghrib;
    final fajrNext = PrayerTimes(
      date: DateTime(date.year, date.month, date.day + 1),
      coordinates: coords,
      calculationParameters: _parameters(),
    ).fajr;
    final night = fajrNext.difference(maghrib);
    return (
      midnight: maghrib.add(Duration(milliseconds: night.inMilliseconds ~/ 2)),
      lastThird:
          maghrib.add(Duration(milliseconds: night.inMilliseconds * 2 ~/ 3)),
    );
  }
}

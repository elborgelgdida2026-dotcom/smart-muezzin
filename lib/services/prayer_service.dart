import 'package:adhan/adhan.dart';
import '../models/prayer_times_model.dart';

/// Prayer-times calculation using the `adhan` Dart package.
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
        params = CalculationMethod.egyptian().getParameters();
        break;
      case PrayerMethod.muslimWorldLeague:
        params = CalculationMethod.muslimWorldLeague().getParameters();
        break;
      case PrayerMethod.karachi:
        params = CalculationMethod.karachi().getParameters();
        break;
      case PrayerMethod.northAmerica:
        params = CalculationMethod.northAmerica().getParameters();
        break;
      case PrayerMethod.ummAlQura:
        params = CalculationMethod.ummAlQura().getParameters();
        break;
      case PrayerMethod.dubai:
        params = CalculationMethod.dubai().getParameters();
        break;
      case PrayerMethod.kuwait:
        params = CalculationMethod.kuwait().getParameters();
        break;
      case PrayerMethod.qatar:
        params = CalculationMethod.qatar().getParameters();
        break;
      case PrayerMethod.singapore:
        params = CalculationMethod.singapore().getParameters();
        break;
      case PrayerMethod.turkey:
        params = CalculationMethod.turkey().getParameters();
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
    final components = DateComponents(date.year, date.month, date.day);
    final pt = PrayerTimes(coords, components, _parameters());
    final now = DateTime.now();
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
    final components = DateComponents(date.year, date.month, date.day);
    final pt = PrayerTimes(coords, components, _parameters());
    final maghrib = pt.maghrib;
    final fajrNext = PrayerTimes(
      coords,
      DateComponents(date.year, date.month, date.day + 1),
      _parameters(),
    ).fajr;
    final night = fajrNext.difference(maghrib);
    return (
      midnight: maghrib.add(Duration(milliseconds: night.inMilliseconds ~/ 2)),
      lastThird:
          maghrib.add(Duration(milliseconds: night.inMilliseconds * 2 ~/ 3)),
    );
  }
}

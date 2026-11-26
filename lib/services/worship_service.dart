import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Worship tracking: a local daily log of prayers performed, fasting,
/// Quran pages read, Azkar completed and Tasbih counts.
///
/// LOCAL ONLY: the log never leaves the device. There is no cloud
/// sync for worship data in this build (see UserSyncService — even
/// there, sync of the worship log is opt-in and the user is told so).
/// The log is a record of what the user *entered*, not a judgement
/// of their worship — the UI says so plainly.
class WorshipDay {
  WorshipDay({
    required this.date,
    this.prayers = const {},
    this.fasting = false,
    this.quranPages = 0,
    this.azkarDone = false,
    this.tasbih = 0,
  });

  factory WorshipDay.fromJson(String date, Map<String, dynamic> j) =>
      WorshipDay(
        date: date,
        prayers: ((j['prayers'] as Map<String, dynamic>?) ?? {})
            .map((k, v) => MapEntry(k, v == true)),
        fasting: j['fasting'] == true,
        quranPages: (j['quranPages'] as num?)?.toInt() ?? 0,
        azkarDone: j['azkarDone'] == true,
        tasbih: (j['tasbih'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'prayers': prayers,
        'fasting': fasting,
        'quranPages': quranPages,
        'azkarDone': azkarDone,
        'tasbih': tasbih,
      };

  final String date; // yyyy-MM-dd
  final Map<String, bool> prayers; // fajr/dhuhr/asr/maghrib/isha
  final bool fasting;
  final int quranPages;
  final bool azkarDone;
  final int tasbih;

  int get prayersCount =>
      prayers.values.where((v) => v).length;

  bool get allFivePrayers => prayersCount == 5;

  WorshipDay copyWith({
    Map<String, bool>? prayers,
    bool? fasting,
    int? quranPages,
    bool? azkarDone,
    int? tasbih,
  }) =>
      WorshipDay(
        date: date,
        prayers: prayers ?? this.prayers,
        fasting: fasting ?? this.fasting,
        quranPages: quranPages ?? this.quranPages,
        azkarDone: azkarDone ?? this.azkarDone,
        tasbih: tasbih ?? this.tasbih,
      );
}

class WorshipService {
  static const _kLog = 'worship_log'; // {yyyy-MM-dd: WorshipDay json}

  static const List<String> prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const Map<String, String> prayerNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static String dateKey(DateTime d) =>
      d.toIso8601String().substring(0, 10);

  Future<Map<String, WorshipDay>> loadLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLog);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, WorshipDay.fromJson(k, v as Map<String, dynamic>)));
  }

  Future<WorshipDay> day(DateTime d) async {
    final log = await loadLog();
    return log[dateKey(d)] ?? WorshipDay(date: dateKey(d));
  }

  Future<void> saveDay(WorshipDay day) async {
    final prefs = await SharedPreferences.getInstance();
    final log = await loadLog();
    log[day.date] = day;
    // Keep the last 365 days only — the log is a tracker, not an archive.
    final keys = log.keys.toList()..sort();
    while (keys.length > 365) {
      log.remove(keys.removeAt(0));
    }
    await prefs.setString(
      _kLog,
      jsonEncode(log.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// Toggle one prayer for a day. Returns the updated day.
  Future<WorshipDay> togglePrayer(DateTime d, String prayerKey) async {
    final current = await day(d);
    final prayers = Map<String, bool>.from(current.prayers);
    prayers[prayerKey] = !(prayers[prayerKey] ?? false);
    final updated = current.copyWith(prayers: prayers);
    await saveDay(updated);
    return updated;
  }

  /// Consecutive days (ending today or yesterday) on which all five
  /// prayers were logged. A gap breaks the streak.
  Future<int> streak() async {
    final log = await loadLog();
    var streak = 0;
    var d = DateTime.now();
    // If today is not yet complete, start counting from yesterday.
    if (!(log[dateKey(d)]?.allFivePrayers ?? false)) {
      d = d.subtract(const Duration(days: 1));
    }
    while (log[dateKey(d)]?.allFivePrayers ?? false) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Last 7 days (oldest first) as (label, prayersCount 0..5).
  Future<List<({String label, int prayers})>> lastWeek() async {
    final log = await loadLog();
    const labels = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    final out = <({String label, int prayers})>[];
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      // DateTime.weekday: Mon=1..Sun=7; Arabic week starts Saturday.
      final label = labels[(d.weekday + 1) % 7];
      out.add((label: label, prayers: log[dateKey(d)]?.prayersCount ?? 0));
    }
    return out;
  }

  /// Monthly summary for [year]/[month]: totals across the month.
  Future<({int daysLogged, int prayers, int fastingDays, int quranPages, int tasbih})>
      monthSummary(int year, int month) async {
    final log = await loadLog();
    var days = 0;
    var prayers = 0;
    var fasting = 0;
    var pages = 0;
    var tasbih = 0;
    for (final e in log.entries) {
      final parts = e.key.split('-');
      if (parts.length != 3) continue;
      if (int.tryParse(parts[0]) != year ||
          int.tryParse(parts[1]) != month) {
        continue;
      }
      days++;
      prayers += e.value.prayersCount;
      if (e.value.fasting) fasting++;
      pages += e.value.quranPages;
      tasbih += e.value.tasbih;
    }
    return (
      daysLogged: days,
      prayers: prayers,
      fastingDays: fasting,
      quranPages: pages,
      tasbih: tasbih,
    );
  }
}

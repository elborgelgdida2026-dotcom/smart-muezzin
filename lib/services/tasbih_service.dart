import 'package:shared_preferences/shared_preferences.dart';

/// Tasbih counter persisted locally. The count survives app restarts
/// and is stored per day so the app can show daily/weekly totals.
class TasbihService {
  static const _kToday = 'tasbih_today';
  static const _kTodayDate = 'tasbih_today_date';
  static const _kTotal = 'tasbih_total';
  static const _kTarget = 'tasbih_target';

  static const List<String> defaultPhrases = [
    'سُبْحَانَ اللهِ',
    'الْحَمْدُ للهِ',
    'اللهُ أَكْبَرُ',
    'أَسْتَغْفِرُ اللهَ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    'لَا إِلَهَ إِلَّا اللهُ',
  ];

  Future<int> _todayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_kTodayDate) != today) {
      await prefs.setString(_kTodayDate, today);
      await prefs.setInt(_kToday, 0);
      return 0;
    }
    return prefs.getInt(_kToday) ?? 0;
  }

  Future<int> today() => _todayCount();

  Future<int> total() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTotal) ?? 0;
  }

  Future<int> target() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTarget) ?? 100;
  }

  Future<void> setTarget(int n) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTarget, n);
  }

  /// One tap. Returns (todayCount, totalCount).
  Future<(int, int)> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final today = await _todayCount();
    final total = (prefs.getInt(_kTotal) ?? 0) + 1;
    await prefs.setInt(_kToday, today + 1);
    await prefs.setInt(_kTotal, total);
    return (today + 1, total);
  }

  Future<void> resetToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kToday, 0);
  }
}

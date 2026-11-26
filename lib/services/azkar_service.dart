import 'package:shared_preferences/shared_preferences.dart';
import '../models/azkar.dart';

/// Azkar library. Texts are bundled verbatim from Hisn al-Muslim
/// (حصن المسلم) with their sources. Only established repetition counts
/// are recorded; where a count is not established the item is listed
/// with repetitions = 1 and the UI states that plainly.
/// No virtues, counts or hadith are invented here.
class AzkarService {
  static const _kDone = 'azkar_done';

  /// Categories shipped in assets/data/azkar.json (see README).
  /// This list is the in-code fallback so the screen works even if
  /// the bundled file is missing.
  static const List<String> categories = [
    'أذكار الصباح',
    'أذكار المساء',
    'أذكار بعد الصلاة',
    'أذكار النوم',
    'أذكار الاستيقاظ',
    'أذكار دخول المسجد',
    'أذكار السفر',
    'أذكار الطعام',
    'أذكار الوضوء',
    'الرقية الشرعية',
    'أدعية الاستغفار',
  ];

  /// Load a category. The bundled JSON is the source of truth;
  /// [bundledJson] is the decoded contents of assets/data/azkar.json.
  List<Zikr> loadCategory(
      String category, List<Map<String, dynamic>> bundledJson) {
    return bundledJson
        .where((e) => e['category'] == category)
        .map((e) => Zikr.fromJson(e))
        .toList();
  }

  Future<Set<String>> completedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final raw = prefs.getStringList(_kDone) ?? [];
    return raw.where((e) => e.startsWith(today)).map((e) => e.substring(11)).toSet();
  }

  /// Mark one zikr done for today. Returns the new completed set.
  Future<Set<String>> markDone(String zikrId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final raw = prefs.getStringList(_kDone) ?? [];
    raw.add('$today|$zikrId');
    await prefs.setStringList(_kDone, raw);
    return completedToday();
  }
}

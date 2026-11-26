import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times_model.dart';

/// Persisted settings: language, theme, font size, city, calculation
/// method, Asr madhab, per-prayer adjustments, reminders.
/// Stored locally with shared_preferences — no account is required.
class SettingsService {
  static const _kLang = 'language';
  static const _kDark = 'dark_mode';
  static const _kFontScale = 'font_scale';
  static const _kMethod = 'prayer_method';
  static const _kHanafi = 'asr_hanafi';
  static const _kCity = 'city';
  static const _kCities = 'saved_cities';
  static const _kAdjust = 'prayer_adjustments';
  static const _kReminders = 'reminders';
  static const _kLastPage = 'last_mushaf_page';

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  // When init() fails (e.g. a device where SharedPreferences cannot be
  // opened), every getter returns its default and every setter is a
  // no-op, so the app still opens and works instead of crashing on the
  // first screen. See main.dart: init failures are caught, not fatal.
  bool get _ok => _ready;

  String get language => _ok ? _prefs.getString(_kLang) ?? 'ar' : 'ar';
  Future<void> setLanguage(String v) async {
    if (!_ok) return;
    await _prefs.setString(_kLang, v);
  }

  bool get isDark => _ok ? _prefs.getBool(_kDark) ?? false : false;
  Future<void> setDark(bool v) async {
    if (!_ok) return;
    await _prefs.setBool(_kDark, v);
  }

  double get fontScale => _ok ? _prefs.getDouble(_kFontScale) ?? 1.0 : 1.0;
  Future<void> setFontScale(double v) async {
    if (!_ok) return;
    await _prefs.setDouble(_kFontScale, v.clamp(0.85, 1.6));
  }

  PrayerMethod get method => _ok
      ? PrayerMethod.fromId(_prefs.getString(_kMethod) ?? 'egyptian')
      : PrayerMethod.fromId('egyptian');
  Future<void> setMethod(PrayerMethod m) async {
    if (!_ok) return;
    await _prefs.setString(_kMethod, m.id);
  }

  bool get asrHanafi => _ok ? _prefs.getBool(_kHanafi) ?? false : false;
  Future<void> setAsrHanafi(bool v) async {
    if (!_ok) return;
    await _prefs.setBool(_kHanafi, v);
  }

  Map<String, int> get adjustments {
    if (!_ok) return {};
    final raw = _prefs.getString(_kAdjust);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> setAdjustment(String prayerKey, int minutes) async {
    if (!_ok) return;
    final m = adjustments..[prayerKey] = minutes;
    await _prefs.setString(_kAdjust, jsonEncode(m));
  }

  SavedCity get city {
    final raw = _ok ? _prefs.getString(_kCity) : null;
    if (raw != null) return SavedCity.fromJson(jsonDecode(raw));
    // Default: Cairo, Egypt.
    return SavedCity(
      name: 'القاهرة',
      country: 'مصر',
      latitude: 30.0444,
      longitude: 31.2357,
      timezone: 'Africa/Cairo',
    );
  }

  Future<void> setCity(SavedCity c) async {
    if (!_ok) return;
    await _prefs.setString(_kCity, jsonEncode(c.toJson()));
    final cities = savedCities;
    if (!cities.any((x) => x.name == c.name)) {
      cities.add(c);
      await _prefs.setString(
        _kCities,
        jsonEncode(cities.map((e) => e.toJson()).toList()),
      );
    }
  }

  List<SavedCity> get savedCities {
    final raw = _ok ? _prefs.getString(_kCities) : null;
    if (raw == null) return [city];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavedCity.fromJson(e)).toList();
  }

  /// Reminder rules: {type: {enabled: bool, minutesBefore: int, time: "HH:mm"}}
  Map<String, dynamic> get reminders {
    final raw = _ok ? _prefs.getString(_kReminders) : null;
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setReminder(String type, Map<String, dynamic> rule) async {
    if (!_ok) return;
    final m = reminders..[type] = rule;
    await _prefs.setString(_kReminders, jsonEncode(m));
  }

  int get lastMushafPage => _ok ? _prefs.getInt(_kLastPage) ?? 1 : 1;
  Future<void> setLastMushafPage(int page) async {
    if (!_ok) return;
    await _prefs.setInt(_kLastPage, page.clamp(1, 604));
  }

  /// Export everything the app stores locally (backup).
  Future<Map<String, dynamic>> exportAll() async {
    if (!_ok) return {'app': 'smart_muezzin', 'version': 1, 'data': {}};
    final keys = _prefs.getKeys();
    final out = <String, dynamic>{};
    for (final k in keys) {
      out[k] = _prefs.get(k);
    }
    return {'app': 'smart_muezzin', 'version': 1, 'data': out};
  }

  /// Restore a backup produced by [exportAll]. Returns false on bad input.
  Future<bool> importAll(Map<String, dynamic> backup) async {
    if (!_ok) return false;
    try {
      if (backup['app'] != 'smart_muezzin') return false;
      final data = backup['data'] as Map<String, dynamic>;
      for (final e in data.entries) {
        final v = e.value;
        if (v is String) await _prefs.setString(e.key, v);
        if (v is bool) await _prefs.setBool(e.key, v);
        if (v is int) await _prefs.setInt(e.key, v);
        if (v is double) await _prefs.setDouble(e.key, v);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAll() async {
    if (!_ok) return;
    await _prefs.clear();
  }
}

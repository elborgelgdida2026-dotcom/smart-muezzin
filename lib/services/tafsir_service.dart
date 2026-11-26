import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Per-ayah tafsir from a real public source: AlQuran Cloud edition
/// `ar.muyassar` (تفسير الميسر — مجمع الملك فهد لطباعة المصحف الشريف),
/// GET https://api.alquran.cloud/v1/ayah/{globalNumber}/ar.muyassar
/// (no key required).
///
/// HONEST NOTES (shown in the UI too):
/// * Tafsir is a scholarly *interpretation* of the Quran — it is not
///   the Quran text itself and must never be quoted as if it were.
/// * The text comes verbatim from the edition; it is never generated
///   or edited by this app.
/// * Results are cached locally (SharedPreferences) so a tafsir read
///   once works offline afterwards.
class TafsirService {
  TafsirService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _base = 'https://api.alquran.cloud/v1';
  static const edition = 'ar.muyassar';
  static const editionName = 'تفسير الميسر';
  static const editionSource = 'مجمع الملك فهد لطباعة المصحف الشريف';

  static const _kCache = 'tafsir_cache'; // {globalAyahNumber: text}

  /// Tafsir text for one ayah (by its global number 1..6236).
  /// Returns cached text when available; otherwise fetches it live.
  Future<String> tafsirOf(int globalAyahNumber) async {
    if (globalAyahNumber < 1 || globalAyahNumber > 6236) {
      throw ArgumentError('Ayah number must be 1..6236');
    }
    final prefs = await SharedPreferences.getInstance();
    final cache = _cache(prefs);
    final cached = cache['$globalAyahNumber'];
    if (cached != null && cached.isNotEmpty) return cached;
    final res = await _client
        .get(Uri.parse('$_base/ayah/$globalAyahNumber/$edition'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('AlQuran Cloud returned ${res.statusCode}');
    }
    final text = jsonDecode(res.body)['data']['text'] as String;
    cache['$globalAyahNumber'] = text;
    await prefs.setString(_kCache, jsonEncode(cache));
    return text;
  }

  /// Cached tafsir text without a network call, or null.
  Future<String?> cachedTafsirOf(int globalAyahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return _cache(prefs)['$globalAyahNumber'];
  }

  Map<String, String> _cache(SharedPreferences prefs) {
    final raw = prefs.getString(_kCache);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';

/// Quran text and audio from AlQuran Cloud (public API, no key required).
/// Text edition: quran-uthmani (Uthmani script, never generated or edited).
/// Audio edition used for playback: ar.alafasy.
/// Base: https://api.alquran.cloud/v1
class QuranService {
  QuranService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _base = 'https://api.alquran.cloud/v1';

  /// All 114 surahs with metadata.
  Future<List<Surah>> listSurahs() async {
    final res = await _client.get(Uri.parse('$_base/surah'));
    if (res.statusCode != 200) {
      throw Exception('AlQuran Cloud returned ${res.statusCode}');
    }
    final data = jsonDecode(res.body)['data'] as List;
    return data.map((e) => Surah.fromJson(e)).toList();
  }

  /// One surah in Uthmani text.
  Future<List<Ayah>> surahText(int number) async {
    final res = await _client.get(Uri.parse('$_base/surah/$number'));
    if (res.statusCode != 200) {
      throw Exception('AlQuran Cloud returned ${res.statusCode}');
    }
    final ayahs = jsonDecode(res.body)['data']['ayahs'] as List;
    return ayahs.map((e) => Ayah.fromJson(e)).toList();
  }

  /// Ayahs of one printed Mushaf page (1–604), Uthmani text.
  /// Endpoint: /v1/page/{page}/quran-uthmani
  Future<List<Ayah>> pageText(int page) async {
    if (page < 1 || page > 604) {
      throw ArgumentError('Mushaf page must be 1..604');
    }
    final res =
        await _client.get(Uri.parse('$_base/page/$page/quran-uthmani'));
    if (res.statusCode != 200) {
      throw Exception('AlQuran Cloud returned ${res.statusCode}');
    }
    final ayahs = jsonDecode(res.body)['data']['ayahs'] as List;
    return ayahs.map((e) => Ayah.fromJson(e)).toList();
  }

  /// Search ayahs by Arabic text (AlQuran Cloud search endpoint).
  Future<List<Ayah>> search(String query) async {
    final res = await _client.get(
      Uri.parse('$_base/search/${Uri.encodeComponent(query)}/all/quran-uthmani'),
    );
    if (res.statusCode != 200) {
      throw Exception('AlQuran Cloud returned ${res.statusCode}');
    }
    final matches = jsonDecode(res.body)['data']['matches'] as List? ?? [];
    return matches.map((e) => Ayah.fromJson(e)).toList();
  }

  /// Audio URL for one ayah with the chosen reciter edition,
  /// e.g. 'ar.alafasy', 'ar.abdulbasitmurattal', 'ar.husary'.
  /// AlQuran Cloud ayah endpoint: /v1/ayah/{globalNumber}/{edition}
  Future<String?> ayahAudio(int globalNumber, String edition) async {
    final res =
        await _client.get(Uri.parse('$_base/ayah/$globalNumber/$edition'));
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body)['data']['audio'] as String?;
  }
}

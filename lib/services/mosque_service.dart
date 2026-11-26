import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosque.dart';

/// Nearby mosques from OpenStreetMap via the Overpass API, with name
/// search via Nominatim. Data is live OSM data, attributed in-app
/// (© OpenStreetMap contributors, ODbL).
///
/// HONEST LIMIT (shown in the UI too): this screen shows name,
/// distance and directions only. It does NOT show iqama or Jumuah
/// times, because no verified source for them exists.
class MosqueService {
  MosqueService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _overpass = 'https://overpass-api.de/api/interpreter';
  static const _nominatim = 'https://nominatim.openstreetmap.org/search';
  static const _kFav = 'mosque_favorites';
  static const _kReports = 'mosque_reports';

  /// Mosques within [radiusMeters] of [lat]/[lon], sorted by distance.
  /// Queries OSM nodes and ways tagged amenity=place_of_worship +
  /// religion=muslim. A 30 s timeout is applied; Overpass can be slow.
  Future<List<Mosque>> nearby({
    required double lat,
    required double lon,
    int radiusMeters = 5000,
    int limit = 100,
  }) async {
    final query = '[out:json][timeout:25];'
        '(node(around:$radiusMeters,$lat,$lon)[amenity=place_of_worship][religion=muslim];'
        'way(around:$radiusMeters,$lat,$lon)[amenity=place_of_worship][religion=muslim];);'
        'out center $limit;';
    final res = await _client
        .get(Uri.parse(_overpass).replace(
          queryParameters: {'data': query},
        ))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Overpass API returned ${res.statusCode}');
    }
    final elements = jsonDecode(res.body)['elements'] as List;
    final mosques = elements
        .map((e) => Mosque.fromOverpass(e as Map<String, dynamic>))
        .where((m) => m.latitude != 0 && m.longitude != 0)
        .toList();
    for (final m in mosques) {
      m.distanceKm = Mosque.distanceKmBetween(lat, lon, m.latitude, m.longitude);
    }
    mosques.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return mosques;
  }

  /// Search mosques by name worldwide (Nominatim). Results carry
  /// coordinates; distance is computed from the user's position when
  /// [lat]/[lon] are given.
  Future<List<Mosque>> searchByName(
    String query, {
    double? lat,
    double? lon,
  }) async {
    final res = await _client.get(
      Uri.parse(_nominatim).replace(queryParameters: {
        'q': '$query مسجد',
        'format': 'json',
        'limit': '20',
        'addressdetails': '0',
      }),
      headers: {'User-Agent': 'SmartMuezzin/1.0 (contact: smartmuezzin.app)'},
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Nominatim returned ${res.statusCode}');
    }
    final items = jsonDecode(res.body) as List;
    final mosques = items.map((e) {
      final m = Mosque(
        id: 'nominatim/${e['place_id']}',
        name: (e['display_name'] as String).split(',').first,
        latitude: double.tryParse('${e['lat']}') ?? 0,
        longitude: double.tryParse('${e['lon']}') ?? 0,
      );
      if (lat != null && lon != null) {
        m.distanceKm =
            Mosque.distanceKmBetween(lat, lon, m.latitude, m.longitude);
      }
      return m;
    }).toList();
    if (lat != null) {
      mosques.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    }
    return mosques;
  }

  /// Google Maps directions URL for a mosque (opened with url_launcher).
  static String directionsUrl(Mosque m) =>
      'https://www.google.com/maps/dir/?api=1&destination=${m.latitude},${m.longitude}';

  Future<Set<String>> favorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kFav) ?? []).toSet();
  }

  Future<bool> toggleFavorite(String mosqueId) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = (prefs.getStringList(_kFav) ?? []).toSet();
    // NB: Set.remove/add return whether the set *changed*, not whether
    // the item is now present — compute the new state explicitly.
    final nowFav = !favs.contains(mosqueId);
    if (nowFav) {
      favs.add(mosqueId);
    } else {
      favs.remove(mosqueId);
    }
    await prefs.setStringList(_kFav, favs.toList());
    return nowFav;
  }

  /// A user report about wrong mosque data, stored locally on the
  /// device (there is no server backend in this build to send it to;
  /// the UI says so plainly).
  Future<void> reportWrongData(String mosqueId, String mosqueName, String details) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList(_kReports) ?? [];
    reports.add(jsonEncode({
      'mosqueId': mosqueId,
      'mosqueName': mosqueName,
      'details': details,
      'at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(_kReports, reports);
  }

  Future<List<Map<String, dynamic>>> reports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kReports) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Rough distance formatting for the UI.
  static String formatDistance(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).round()} م';
    return '${km.toStringAsFixed(1)} كم';
  }
}

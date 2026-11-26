import 'dart:math' as math;

/// A mosque from OpenStreetMap (Overpass API).
/// Only name + coordinates come from OSM; no prayer or iqama times are
/// stored, because no verified source for them exists (see the
/// Mosques screen disclaimer).
class Mosque {
  Mosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
  });

  factory Mosque.fromOverpass(Map<String, dynamic> e) {
    final tags = e['tags'] as Map<String, dynamic>? ?? {};
    double? lat = (e['lat'] as num?)?.toDouble();
    double? lon = (e['lon'] as num?)?.toDouble();
    final center = e['center'] as Map<String, dynamic>?;
    lat ??= (center?['lat'] as num?)?.toDouble();
    lon ??= (center?['lon'] as num?)?.toDouble();
    return Mosque(
      id: '${e['type']}/${e['id']}',
      name: (tags['name'] as String?)?.trim().isNotEmpty == true
          ? tags['name'] as String
          : 'مسجد',
      latitude: lat ?? 0,
      longitude: lon ?? 0,
    );
  }

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  double? distanceKm;

  /// Haversine distance in km between two coordinates.
  static double distanceKmBetween(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}

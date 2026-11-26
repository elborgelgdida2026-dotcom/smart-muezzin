import 'dart:math' as math;
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';

/// Qibla direction. Two paths:
/// 1. Device compass stream via flutter_qiblah (needs a real device
///    with a compass sensor; the emulator has none).
/// 2. Pure-math fallback from GPS coordinates (always available):
///    bearing to the Kaaba (21.4225 N, 39.8262 E) + distance.
class QiblaService {
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// Bearing in degrees (0 = North, clockwise) from [lat]/[lng].
  static double bearing(double lat, double lng) {
    final lat1 = lat * math.pi / 180;
    final lat2 = kaabaLat * math.pi / 180;
    final dLng = (kaabaLng - lng) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Great-circle distance to the Kaaba in kilometres.
  static double distanceKm(double lat, double lng) {
    const r = 6371.0;
    final dLat = (kaabaLat - lat) * math.pi / 180;
    final dLng = (kaabaLng - lng) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * math.pi / 180) *
            math.cos(kaabaLat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Live compass stream from the device sensor.
  Stream<QiblahDirection> compassStream() => FlutterQiblah.qiblahStream;

  /// Request the current GPS position (asks permission first).
  Future<Position> currentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    return Geolocator.getCurrentPosition();
  }
}

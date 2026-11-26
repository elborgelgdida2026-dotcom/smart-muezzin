import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import '../services/qibla_service.dart';
import '../services/settings_service.dart';

/// Qibla tab: live compass (device sensor, real device only) plus a
/// math fallback from GPS coordinates — bearing in degrees and distance
/// to the Kaaba. If the device has no compass sensor, the fallback is
/// shown and the UI says so plainly.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _service = QiblaService();
  double? _bearing;
  double? _distanceKm;
  String? _error;

  @override
  void initState() {
    super.initState();
    _computeFromSavedCity();
  }

  void _computeFromSavedCity() {
    final c = widget.settings.city;
    setState(() {
      _bearing = QiblaService.bearing(c.latitude, c.longitude);
      _distanceKm = QiblaService.distanceKm(c.latitude, c.longitude);
    });
  }

  Future<void> _useGps() async {
    try {
      final pos = await _service.currentPosition();
      setState(() {
        _bearing = QiblaService.bearing(pos.latitude, pos.longitude);
        _distanceKm =
            QiblaService.distanceKm(pos.latitude, pos.longitude);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'تعذر تحديد الموقع: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_bearing != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('اتجاه القبلة: ${_bearing!.toStringAsFixed(1)}°',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_distanceKm != null)
                      Text(
                          'المسافة إلى الكعبة: ${_distanceKm!.toStringAsFixed(0)} كم'),
                    const SizedBox(height: 16),
                    // Compass dial: needle rotated to the Qibla bearing.
                    // The live sensor stream (below) rotates the dial;
                    // this static dial shows the computed bearing.
                    Transform.rotate(
                      angle: _bearing! * math.pi / 180,
                      child: const Icon(Icons.navigation,
                          size: 120, color: Colors.green),
                    ),
                    const Text('الشمال في الأعلى — السهم يشير إلى القبلة'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _useGps,
            icon: const Icon(Icons.my_location),
            label: const Text('استخدام موقعي الحالي (GPS)'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          const Text(
            'البوصلة الحية: تحتاج جهازًا حقيقيًا به مستشعر بوصلة. '
            'في المحاكي أو الأجهزة بدون المستشعر يظهر الاتجاه المحسوب من الإحداثيات أعلاه.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: StreamBuilder<QiblahDirection>(
              stream: _service.compassStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('البوصلة غير متاحة على هذا الجهاز.');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final d = snapshot.data!;
                return Column(
                  children: [
                    Text('اتجاه الجهاز: ${d.direction.toStringAsFixed(0)}°'),
                    Text('القبلة: ${d.qiblah.toStringAsFixed(1)}°'),
                    Text('الانحراف: ${d.offset.toStringAsFixed(1)}°'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

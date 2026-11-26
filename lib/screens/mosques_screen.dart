import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mosque.dart';
import '../services/mosque_service.dart';
import '../services/settings_service.dart';

/// Nearby mosques from OpenStreetMap (Overpass API).
///
/// HONEST LIMIT (shown in the UI too): this screen shows name,
/// distance and directions only. It does NOT show iqama or Jumuah
/// times, because no verified source for them exists.
class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  final _service = MosqueService();
  List<Mosque> _mosques = [];
  Set<String> _favs = {};
  bool _loading = true;
  String? _error;
  String? _locationNote;
  double? _lat;
  double? _lon;
  bool _showMap = false;
  Mosque? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Location only after the user's consent (runtime permission).
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      double lat;
      double lon;
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 15));
        lat = pos.latitude;
        lon = pos.longitude;
        _locationNote = 'موقعك الحالي (GPS)';
      } else {
        final city = widget.settings.city;
        lat = city.latitude;
        lon = city.longitude;
        _locationNote =
            'تعذّر الوصول إلى موقعك — تُعرض المساجد حول مدينتك المحفوظة (${city.name})';
      }
      final mosques =
          await _service.nearby(lat: lat, lon: lon, radiusMeters: 5000);
      final favs = await _service.favorites();
      if (mounted) {
        setState(() {
          _lat = lat;
          _lon = lon;
          _mosques = mosques;
          _favs = favs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await _service.searchByName(query, lat: _lat, lon: _lon);
      if (mounted) {
        setState(() {
          _mosques = results;
          _locationNote = 'نتائج البحث عن "$query"';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFav(Mosque m) async {
    final nowFav = await _service.toggleFavorite(m.id);
    if (mounted) {
      setState(() {
        if (nowFav) {
          _favs.add(m.id);
        } else {
          _favs.remove(m.id);
        }
      });
    }
  }

  Future<void> _directions(Mosque m) async {
    final uri = Uri.parse(MosqueService.directionsUrl(m));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الخرائط')),
      );
    }
  }

  Future<void> _report(Mosque m) async {
    final controller = TextEditingController();
    final details = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('الإبلاغ عن بيانات خاطئة — ${m.name}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'ما الخطأ في بيانات هذا المسجد؟',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('إرسال البلاغ'),
          ),
        ],
      ),
    );
    if (details != null && details.trim().isNotEmpty) {
      await _service.reportWrongData(m.id, m.name, details.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حفظ البلاغ على جهازك. لا يوجد خادم في هذه النسخة لإرساله إليه.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساجد القريبة'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'عرض القائمة' : 'عرض الخريطة',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة التحميل',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('تعذر تحميل المساجد: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        onSubmitted: _search,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن مسجد بالاسم…',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_locationNote != null)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(_locationNote!,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'تنبيه: لا تُعرض مواعيد الإقامة أو الجمعة هنا، '
                            'لعدم وجود مصدر موثّق لها. البيانات: © مساهمو '
                            'OpenStreetMap (ODbL).',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _showMap && _lat != null
                          ? _buildMap()
                          : _buildList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildList() {
    if (_mosques.isEmpty) {
      return const Center(
        child: Text('لا توجد مساجد في النطاق الحالي. جرّب البحث بالاسم.'),
      );
    }
    return ListView.builder(
      itemCount: _mosques.length,
      itemBuilder: (context, i) {
        final m = _mosques[i];
        final selected = _selected?.id == m.id;
        return Card(
          color: selected ? Colors.amber.shade50 : null,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(m.name),
            subtitle: Text(
              'المسافة: ${MosqueService.formatDistance(m.distanceKm)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _favs.contains(m.id) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  tooltip: 'المفضلة',
                  onPressed: () => _toggleFav(m),
                ),
                IconButton(
                  icon: const Icon(Icons.directions),
                  tooltip: 'الاتجاهات',
                  onPressed: () => _directions(m),
                ),
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'الإبلاغ عن بيانات خاطئة',
                  onPressed: () => _report(m),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selected = m;
                _showMap = true;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    final center = _selected != null
        ? LatLng(_selected!.latitude, _selected!.longitude)
        : LatLng(_lat!, _lon!);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartmuezzin.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_lat!, _lon!),
              width: 40,
              height: 40,
              child: const Icon(Icons.my_location,
                  color: Colors.blue, size: 32),
            ),
            for (var i = 0; i < _mosques.length; i++)
              Marker(
                point: LatLng(
                    _mosques[i].latitude, _mosques[i].longitude),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selected = _mosques[i]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selected?.id == _mosques[i].id
                              ? Colors.amber
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.place,
                          color: Colors.teal, size: 22),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

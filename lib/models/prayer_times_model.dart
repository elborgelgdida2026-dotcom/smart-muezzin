/// Calculation methods supported by the app.
/// The `adhan` package names: egyptian, muslimWorldLeague, karachi,
/// northAmerica, ummAlQura, dubai, kuwait, qatar, singapore, turkey, etc.
/// Default for Egypt: egyptian (Egyptian General Authority of Surveying).
enum PrayerMethod {
  egyptian('egyptian', 'الهيئة المصرية العامة للمساحة'),
  muslimWorldLeague('muslimWorldLeague', 'رابطة العالم الإسلامي'),
  karachi('karachi', 'جامعة العلوم الإسلامية بكراتشي'),
  northAmerica('northAmerica', 'جمعية أمريكا الشمالية الإسلامية (ISNA)'),
  ummAlQura('ummAlQura', 'تقويم أم القرى'),
  dubai('dubai', 'الهيئة العامة للشؤون الإسلامية والأوقاف بالإمارات'),
  kuwait('kuwait', 'وزارة الأوقاف الكويتية'),
  qatar('qatar', 'قطر'),
  singapore('singapore', 'سنغافورة'),
  turkey('turkey', 'تركيا');

  const PrayerMethod(this.id, this.arabicName);
  final String id;
  final String arabicName;

  static PrayerMethod fromId(String id) =>
      PrayerMethod.values.firstWhere((m) => m.id == id,
          orElse: () => PrayerMethod.egyptian);
}

/// One prayer with its computed time and an optional per-prayer adjustment.
class PrayerTimeEntry {
  PrayerTimeEntry({
    required this.key,
    required this.arabicName,
    required this.time,
    this.isCurrent = false,
  });
  final String key; // fajr, sunrise, dhuhr, asr, maghrib, isha
  final String arabicName;
  final DateTime time;
  final bool isCurrent;
}

/// A saved city (GPS or manual).
class SavedCity {
  SavedCity({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.timezone = 'Africa/Cairo',
  });

  factory SavedCity.fromJson(Map<String, dynamic> j) => SavedCity(
        name: j['name'] as String,
        country: j['country'] as String? ?? '',
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        timezone: j['timezone'] as String? ?? 'Africa/Cairo',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
      };

  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;
}

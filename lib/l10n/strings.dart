/// App strings, Arabic first (default), English fallback.
/// Full localisation via flutter_localizations is out of scope for v1;
/// the settings screen switches `language` between 'ar' and 'en' and
/// the UI reads from this table.
class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'ar': {
      'app_name': 'المؤذن الذكي',
      'home': 'الرئيسية',
      'quran': 'القرآن الكريم',
      'qibla': 'القبلة',
      'azkar': 'الأذكار',
      'more': 'المزيد',
      'tasbih': 'المسبحة',
      'zakat': 'حاسبة الزكاة',
      'hijri': 'التقويم الهجري',
      'ramadan': 'رمضان',
      'kids': 'قسم الأطفال',
      'settings': 'الإعدادات',
      'next_prayer': 'الصلاة القادمة',
      'search_surah': 'ابحث عن سورة…',
    },
    'en': {
      'app_name': 'Smart Muezzin',
      'home': 'Home',
      'quran': 'Quran',
      'qibla': 'Qibla',
      'azkar': 'Azkar',
      'more': 'More',
      'tasbih': 'Tasbih',
      'zakat': 'Zakat Calculator',
      'hijri': 'Hijri Calendar',
      'ramadan': 'Ramadan',
      'kids': 'Kids',
      'settings': 'Settings',
      'next_prayer': 'Next prayer',
      'search_surah': 'Search a surah…',
    },
  };

  static String get(String lang, String key) =>
      values[lang]?[key] ?? values['ar']![key]!;
}

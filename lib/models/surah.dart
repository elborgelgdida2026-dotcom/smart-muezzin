/// Surah metadata from AlQuran Cloud: GET https://api.alquran.cloud/v1/surah
class Surah {
  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        number: j['number'] as int,
        name: j['name'] as String,
        englishName: j['englishName'] as String,
        englishNameTranslation: j['englishNameTranslation'] as String? ?? '',
        numberOfAyahs: j['numberOfAyahs'] as int,
        revelationType: j['revelationType'] as String? ?? '',
      );

  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
}

/// One ayah in Uthmani script, from GET /v1/surah/{n} (edition quran-uthmani).
class Ayah {
  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.surahNumber,
    this.audio,
    this.juz,
  });

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
        number: j['number'] as int,
        text: j['text'] as String,
        numberInSurah: j['numberInSurah'] as int,
        surahNumber: (j['surah'] as Map<String, dynamic>?)?['number'] as int? ?? 0,
        audio: j['audio'] as String?,
        juz: j['juz'] as int?,
      );

  final int number;
  final String text;
  final int numberInSurah;
  final int surahNumber;
  final String? audio; // ar.alafasy audio URL when using that edition
  final int? juz; // Juz number (1-30), present in AlQuran Cloud page data
}

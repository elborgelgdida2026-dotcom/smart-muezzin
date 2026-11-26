/// One hadith from the bundled local dataset (assets/data/hadith.json).
///
/// Sources (see the dataset file header for full provenance):
///  - Nawawi: full text of the 42 hadiths (fawazahmed0/hadith-api).
///  - Bukhari / Muslim: first 100 entries of each book's file —
///    explicitly a subset, never presented as the whole book.
///  - Riyad as-Salihin: hadiths 680-695, transcribed verbatim from
///    Sunnah.com (2026-11-26) — explicitly a subset.
/// No hadith text is generated or invented anywhere in this app.
class Hadith {
  Hadith({
    required this.book,
    required this.number,
    required this.arabic,
    required this.chapter,
    this.narrator,
    required this.source,
    this.grade,
  });

  factory Hadith.fromJson(Map<String, dynamic> j) => Hadith(
        book: j['book'] as String,
        number: j['number'] as int,
        arabic: j['arabic'] as String,
        chapter: j['chapter'] as String? ?? '',
        narrator: j['narrator'] as String?,
        source: j['source'] as String,
        grade: j['grade'] as String?,
      );

  final String book;
  final int number;
  final String arabic;
  final String chapter;
  final String? narrator;
  final String source;
  final String? grade;

  String get key => '$book:$number';
}

/// Metadata for one book in the bundled dataset.
class HadithBook {
  HadithBook({
    required this.id,
    required this.title,
    required this.totalInBook,
    required this.included,
    required this.note,
  });

  factory HadithBook.fromJson(Map<String, dynamic> j) => HadithBook(
        id: j['id'] as String,
        title: j['title'] as String,
        totalInBook: j['totalInBook'] as int,
        included: j['included'] as int,
        note: j['note'] as String,
      );

  final String id;
  final String title;
  final int totalInBook;
  final int included;
  final String note;
}

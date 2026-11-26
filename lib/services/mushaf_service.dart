import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import 'quran_service.dart';

/// Printed Mushaf (Madani, 604 pages) support.
///
/// Page images: real SVG pages of the Madani Mushaf from the AlFurqan
/// API — GET https://alfurqan.online/api/v1/quran-text/page/{1..604}
/// (verified HTTP 200, image/svg+xml, for pages 1, 2, 50 and 604 on
/// 2026-11-26). Pages are shown complete, never cropped.
/// Ayah data for a page comes from AlQuran Cloud
/// (QuranService.pageText) — never generated.
///
/// HONEST LIMIT (stated in the UI and in LIMITS.md): tapping directly
/// on an ayah *inside* the page image is NOT available. Precise
/// word/ayah coordinates come from the Quran Foundation API, which
/// requires paid authentication (verified: HTTP 400 without it).
/// Instead, the ayah list for the page is shown below the image and
/// tapping any ayah plays its recitation.
class MushafService {
  MushafService({QuranService? quran}) : _quran = quran ?? QuranService();
  final QuranService _quran;

  static const int totalPages = 604;

  /// Direct URL of one printed page (SVG, Madani Mushaf, KFGQPC).
  static String pageImageUrl(int page) {
    assert(page >= 1 && page <= totalPages);
    return 'https://alfurqan.online/api/v1/quran-text/page/$page';
  }

  /// Ayahs printed on one page (Uthmani text, AlQuran Cloud).
  Future<List<Ayah>> pageAyahs(int page) => _quran.pageText(page);

  /// First printed page of a surah, found by binary search over the
  /// 604 pages using the page-ayah data (a page's first ayah tells
  /// which surah and ayah-number it starts with). Results are cached
  /// locally so the search runs once per surah.
  Future<int> firstPageOfSurah(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt('mushaf_first_page_$surahNumber');
    if (cached != null) return cached;

    int lo = 1, hi = totalPages, answer = 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final ayahs = await _quran.pageText(mid);
      if (ayahs.isEmpty) {
        hi = mid - 1;
        continue;
      }
      final first = ayahs.first;
      if (first.surahNumber < surahNumber) {
        // This page starts in an earlier surah: target is later.
        lo = mid + 1;
      } else if (first.surahNumber > surahNumber) {
        // This page starts in a later surah: target is earlier.
        hi = mid - 1;
      } else if (first.numberInSurah == 1) {
        // This page starts exactly at the surah: candidate answer.
        answer = mid;
        hi = mid - 1;
      } else {
        // Page starts mid-surah: the surah began on an earlier page.
        hi = mid - 1;
      }
    }
    await prefs.setInt('mushaf_first_page_$surahNumber', answer);
    return answer;
  }

  /// Arabic-Indic digits (e.g. 2 -> ٢) for the page header,
  /// matching the user's requested "صفحة ٢ من ٦٠٤" format.
  static String arabicDigits(int n) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    return n
        .toString()
        .split('')
        .map((c) => western.contains(c) ? eastern[western.indexOf(c)] : c)
        .join();
  }
}

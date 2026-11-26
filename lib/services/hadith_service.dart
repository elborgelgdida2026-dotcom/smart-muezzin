import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hadith.dart';

/// Hadith library backed by the bundled local dataset
/// (assets/data/hadith.json) — see that file's header for provenance.
/// No hadith text is generated, fetched from an unverified source, or
/// invented. Subsets are labelled as subsets in the book metadata.
/// NOTE (honest limitation): this Flutter build does NOT include the
/// AI "brief explanation" feature. There is no on-device inference
/// here, and no verified verbatim commentary source (e.g. Fath
/// al-Bari / Sharh an-Nawawi) could be fetched programmatically
/// (sunnah.com returns 403 to programmatic fetches; its API needs a
/// key). The detail view instead lists the reference commentaries
/// for further reading. Any future AI summary must be labelled as
/// AI-generated and never presented as a quotation from a commentary.
class HadithService {
  static const _kFav = 'hadith_favorites';

  List<Hadith> _all = [];
  List<HadithBook> _books = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/hadith.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _books = (data['books'] as List)
        .map((e) => HadithBook.fromJson(e as Map<String, dynamic>))
        .toList();
    _all = (data['hadiths'] as List)
        .map((e) => Hadith.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  List<HadithBook> get books => List.unmodifiable(_books);
  List<Hadith> get all => List.unmodifiable(_all);

  List<Hadith> byBook(String bookId) =>
      _all.where((h) => h.book == bookId).toList();

  /// Chapters (topics) present in one book, in first-appearance order.
  List<String> chaptersOf(String bookId) {
    final seen = <String>[];
    for (final h in byBook(bookId)) {
      if (h.chapter.isNotEmpty && !seen.contains(h.chapter)) {
        seen.add(h.chapter);
      }
    }
    return seen;
  }

  /// Search across Arabic text, chapter, narrator and source.
  List<Hadith> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return all;
    return _all
        .where((h) =>
            h.arabic.contains(q) ||
            h.chapter.contains(q) ||
            (h.narrator ?? '').contains(q) ||
            h.source.contains(q))
        .toList();
  }

  /// Deterministic daily hadith from the Nawawi collection
  /// (day-of-year modulo 42), so every user sees the same one each day.
  Hadith? dailyHadith() {
    final nawawi = byBook('nawawi');
    if (nawawi.isEmpty) return null;
    final day = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return nawawi[day % nawawi.length];
  }

  Future<Set<String>> favorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kFav) ?? []).toSet();
  }

  Future<bool> toggleFavorite(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = (prefs.getStringList(_kFav) ?? []).toSet();
    // NB: Set.remove/add return whether the set *changed*, not whether
    // the item is now present — compute the new state explicitly.
    final nowFav = !favs.contains(key);
    if (nowFav) {
      favs.add(key);
    } else {
      favs.remove(key);
    }
    await prefs.setStringList(_kFav, favs.toList());
    return nowFav;
  }
}

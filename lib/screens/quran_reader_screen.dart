import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../services/mushaf_service.dart';
import '../services/quran_service.dart';
import '../services/settings_service.dart';
import 'mushaf_screen.dart';
import 'tafsir_screen.dart';

/// Reader: Uthmani text of one surah, with per-ayah audio playback
/// (ar.alafasy by default) and a bookmark saved locally.
/// The text comes verbatim from AlQuran Cloud — it is never generated.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen(
      {super.key, required this.surah, required this.settings});
  final Surah surah;
  final SettingsService settings;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final _service = QuranService();
  final _player = AudioPlayer();
  List<Ayah> _ayahs = [];
  bool _loading = true;
  String? _error;
  int? _playing;
  int? _bookmark;
  double _fontSize = 22;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _bookmark =
          prefs.getInt('bookmark_surah_${widget.surah.number}'));
    }
  }

  Future<void> _load() async {
    try {
      final ayahs = await _service.surahText(widget.surah.number);
      if (mounted) setState(() => _ayahs = ayahs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play(Ayah ayah) async {
    // AlQuran Cloud returns an audio URL per ayah in the ar.alafasy
    // edition; fetch it, then play. Tapping again stops playback.
    if (_playing == ayah.numberInSurah) {
      await _player.stop();
      setState(() => _playing = null);
      return;
    }
    final url = await _service.ayahAudio(ayah.number, 'ar.alafasy');
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الصوت لهذه الآية')),
        );
      }
      return;
    }
    await _player.play(UrlSource(url));
    setState(() => _playing = ayah.numberInSurah);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = null);
    });
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bookmark_surah_${widget.surah.number}';
    if (_bookmark == ayahNumber) {
      await prefs.remove(key);
      setState(() => _bookmark = null);
    } else {
      await prefs.setInt(key, ayahNumber);
      setState(() => _bookmark = ayahNumber);
    }
  }

  Future<void> _openInMushaf() async {
    // Jump to the printed-Mushaf page where this surah begins.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جارٍ تحديد صفحة السورة في المصحف…')),
    );
    try {
      final page =
          await MushafService().firstPageOfSurah(widget.surah.number);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MushafScreen(
            settings: widget.settings,
            initialPage: page,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح المصحف: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'عرضها في المصحف المطبوع',
            onPressed: _openInMushaf,
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'تكبير الخط',
            onPressed: () =>
                setState(() => _fontSize = (_fontSize + 2).clamp(18, 34)),
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'تصغير الخط',
            onPressed: () =>
                setState(() => _fontSize = (_fontSize - 2).clamp(18, 34)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ayahs.length,
                  itemBuilder: (context, i) {
                    final a = _ayahs[i];
                    final isPlaying = _playing == a.numberInSurah;
                    final isBookmarked = _bookmark == a.numberInSurah;
                    return Card(
                      child: ListTile(
                        title: Text(
                          a.text,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: _fontSize,
                            height: 1.9,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        subtitle: Text('آية ${a.numberInSurah}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isPlaying
                                  ? Icons.stop
                                  : Icons.play_arrow),
                              tooltip: 'استمع للتلاوة',
                              onPressed: () => _play(a),
                            ),
                            IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              tooltip: 'حفظ موضع القراءة',
                              onPressed: () =>
                                  _toggleBookmark(a.numberInSurah),
                            ),
                            IconButton(
                              icon: const Icon(Icons.auto_stories),
                              tooltip: 'التفسير',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TafsirScreen(
                                    surahName: widget.surah.name,
                                    ayahNumberInSurah: a.numberInSurah,
                                    globalAyahNumber: a.number,
                                    ayahText: a.text,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

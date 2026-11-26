import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/surah.dart';
import '../services/mushaf_service.dart';
import '../services/quran_service.dart';
import '../services/settings_service.dart';

/// Printed Mushaf mode: the real 604 Madani Mushaf pages as SVG
/// (AlFurqan API), shown complete, never cropped.
///
/// HONEST LIMIT (shown in the UI too): tapping directly on an ayah
/// *inside* the page image is NOT available — precise word/ayah
/// coordinates come from the Quran Foundation API, which requires
/// paid authentication (verified: HTTP 400 without it). Instead, the
/// ayah list for the page is shown below the image; tapping any ayah
/// plays its recitation.
class MushafScreen extends StatefulWidget {
  const MushafScreen({
    super.key,
    required this.settings,
    this.initialPage = 1,
  });
  final SettingsService settings;
  final int initialPage;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final _mushaf = MushafService();
  final _quran = QuranService();
  final _flipPlayer = AudioPlayer();
  final _ayahPlayer = AudioPlayer();
  late final PageController _pageController;

  int _page = 1;
  List<Ayah> _pageAyahs = [];
  List<Surah> _surahs = [];
  bool _pageLoading = true;
  String? _pageError;
  bool _soundOn = true;
  bool _showAyahs = false;
  int? _playingAyah;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, MushafService.totalPages);
    _pageController = PageController(initialPage: _page - 1);
    _loadSurahs();
    _loadPage(_page, playSound: false);
  }

  Future<void> _loadSurahs() async {
    try {
      final list = await _quran.listSurahs();
      if (mounted) setState(() => _surahs = list);
    } catch (_) {
      // Surah names are a nice-to-have; the page still works without them.
    }
  }

  String _surahName(int number) {
    for (final s in _surahs) {
      if (s.number == number) return s.name;
    }
    return 'سورة $number';
  }

  Future<void> _loadPage(int page, {bool playSound = true}) async {
    setState(() {
      _page = page;
      _pageLoading = true;
      _pageError = null;
      _playingAyah = null;
    });
    if (playSound && _soundOn) {
      // Page-turn sound: generated paper-rustle WAV bundled in the app
      // (assets/audio/page_turn.wav — synthesized, see LIMITS.md).
      _flipPlayer.play(AssetSource('audio/page_turn.wav')).catchError((_) {});
    }
    await widget.settings.setLastMushafPage(page);
    try {
      final ayahs = await _mushaf.pageAyahs(page);
      if (mounted) {
        setState(() {
          _pageAyahs = ayahs;
          _pageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pageError = e.toString();
          _pageLoading = false;
        });
      }
    }
  }

  void _goToPage(int page) {
    final target = page.clamp(1, MushafService.totalPages);
    _pageController.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _jumpToPageDialog() async {
    final controller =
        TextEditingController(text: _page.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'رقم الصفحة (1–604)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pop(int.tryParse(controller.text)),
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
    if (value != null) _goToPage(value);
  }

  Future<void> _playAyah(Ayah ayah) async {
    if (_playingAyah == ayah.numberInSurah) {
      await _ayahPlayer.stop();
      if (mounted) setState(() => _playingAyah = null);
      return;
    }
    final url = await _quran.ayahAudio(ayah.number, 'ar.alafasy');
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل صوت هذه الآية')),
        );
      }
      return;
    }
    await _ayahPlayer.play(UrlSource(url));
    if (mounted) setState(() => _playingAyah = ayah.numberInSurah);
    _ayahPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingAyah = null);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipPlayer.dispose();
    _ayahPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstAyah = _pageAyahs.isNotEmpty ? _pageAyahs.first : null;
    final surahName =
        firstAyah == null ? 'المصحف' : _surahName(firstAyah.surahNumber);
    final juz = firstAyah?.juz;
    return Scaffold(
      backgroundColor: const Color(0xFF071633),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1F4B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'إغلاق',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(surahName, style: const TextStyle(fontSize: 18)),
            Text(
              'صفحة ${MushafService.arabicDigits(_page)} من '
              '${MushafService.arabicDigits(MushafService.totalPages)}'
              '${juz != null ? ' • الجزء ${MushafService.arabicDigits(juz)}' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_soundOn ? Icons.volume_up : Icons.volume_off),
            tooltip: _soundOn ? 'كتم صوت التقليب' : 'تشغيل صوت التقليب',
            onPressed: () => setState(() => _soundOn = !_soundOn),
          ),
          IconButton(
            icon: const Icon(Icons.find_in_page),
            tooltip: 'الانتقال إلى صفحة',
            onPressed: _jumpToPageDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFFAF6EE),
              child: PageView.builder(
                controller: _pageController,
                itemCount: MushafService.totalPages,
                // Swipe right = next page (RTL Mushaf), left = previous.
                // PageView in RTL handles direction automatically.
                onPageChanged: (index) => _loadPage(index + 1),
                itemBuilder: (context, index) {
                  final page = index + 1;
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      // 3D flip: the page rotates slightly around the
                      // vertical axis as it moves, with the next page
                      // visible underneath it while turning.
                      double offset = 0;
                      try {
                        offset = (_pageController.page ?? (_page - 1)) - index;
                      } catch (_) {
                        offset = 0;
                      }
                      final angle =
                          (offset.clamp(-1.0, 1.0) * 0.35);
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: _buildPageImage(page),
                  );
                },
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('آيات هذه الصفحة'),
                  subtitle: const Text(
                    'الضغط على آية داخل صورة الصفحة غير متاح تقنيًا '
                    '(يحتاج مصادقة مدفوعة) — اضغط على أي آية هنا لتشغيل تلاوتها.',
                  ),
                  trailing: Icon(
                    _showAyahs ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () => setState(() => _showAyahs = !_showAyahs),
                ),
                if (_showAyahs)
                  SizedBox(
                    height: 220,
                    child: _pageLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _pageError != null
                            ? Center(
                                child: ElevatedButton(
                                  onPressed: () => _loadPage(_page,
                                      playSound: false),
                                  child: const Text('إعادة تحميل آيات الصفحة'),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _pageAyahs.length,
                                itemBuilder: (context, i) {
                                  final a = _pageAyahs[i];
                                  final playing =
                                      _playingAyah == a.numberInSurah;
                                  return ListTile(
                                    title: Text(
                                      a.text,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 18,
                                        height: 1.8,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    subtitle: Text(
                                      'سورة ${_surahName(a.surahNumber)} • آية ${a.numberInSurah}',
                                    ),
                                    trailing: Icon(
                                      playing
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                    ),
                                    onTap: () => _playAyah(a),
                                  );
                                },
                              ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageImage(int page) {
    // Only the current and adjacent pages are built by PageView, so
    // network SVGs load on demand. The image is shown complete
    // (BoxFit.contain) — never cropped.
    return Center(
      child: SvgPicture.network(
        MushafService.pageImageUrl(page),
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

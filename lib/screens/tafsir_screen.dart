import 'package:flutter/material.dart';
import '../services/tafsir_service.dart';

/// Per-ayah tafsir (تفسير الميسر — AlQuran Cloud edition ar.muyassar).
/// The text is quoted verbatim from the edition and cached locally.
/// The screen states plainly that tafsir is a scholarly interpretation,
/// not the Quran text itself.
class TafsirScreen extends StatefulWidget {
  const TafsirScreen({
    super.key,
    required this.surahName,
    required this.ayahNumberInSurah,
    required this.globalAyahNumber,
    required this.ayahText,
  });

  final String surahName;
  final int ayahNumberInSurah;
  final int globalAyahNumber;
  final String ayahText;

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  final _service = TafsirService();
  String? _tafsir;
  String? _error;
  bool _loading = true;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cached =
          await _service.cachedTafsirOf(widget.globalAyahNumber);
      if (cached != null) {
        if (mounted) {
          setState(() {
            _tafsir = cached;
            _fromCache = true;
            _loading = false;
          });
        }
        return;
      }
      final text = await _service.tafsirOf(widget.globalAyahNumber);
      if (mounted) {
        setState(() {
          _tafsir = text;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفسير ${widget.surahName} — آية ${widget.ayahNumberInSurah}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.ayahText,
                style: const TextStyle(
                    fontFamily: 'Amiri', fontSize: 20, height: 1.9),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'المصدر: ${TafsirService.editionName} — ${TafsirService.editionSource}. '
              'التفسير رأي علمي في معنى الآية، وليس نص القرآن نفسه، '
              'فلا يُقتبس على أنه قرآن.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Column(
              children: [
                Text('تعذر تحميل التفسير: $_error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            )
          else ...[
            if (_fromCache)
              const Text('معروض من نسخة محفوظة على جهازك.',
                  style: TextStyle(fontSize: 12)),
            Text(
              _tafsir!,
              style: const TextStyle(fontSize: 17, height: 1.9),
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
    );
  }
}

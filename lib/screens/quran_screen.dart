import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import '../services/settings_service.dart';
import 'mushaf_screen.dart';
import 'quran_reader_screen.dart';

/// Quran tab: surah index (114) from AlQuran Cloud, with search.
/// Tapping a surah opens the reader in Uthmani text with audio.
/// A header button opens the printed Mushaf at the last-read page.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key, required this.settings});
  final SettingsService settings;
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _service = QuranService();
  List<Surah> _all = [];
  List<Surah> _shown = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.listSurahs();
      if (mounted) {
        setState(() {
          _all = list;
          _shown = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _search(String q) {
    setState(() {
      _shown = q.isEmpty
          ? _all
          : _all
              .where((s) =>
                  s.name.contains(q) ||
                  s.englishName.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعذر تحميل فهرس السور: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('المصحف المطبوع (604 صفحات)'),
              subtitle: Text(
                  'آخر صفحة قرأتها: ${widget.settings.lastMushafPage}'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MushafScreen(
                    settings: widget.settings,
                    initialPage: widget.settings.lastMushafPage,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'ابحث عن سورة…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _shown.length,
            itemBuilder: (context, i) {
              final s = _shown[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${s.number}')),
                title: Text(s.name,
                    style: const TextStyle(
                        fontFamily: 'Amiri', fontSize: 20)),
                subtitle: Text(
                    '${s.englishName} • ${s.numberOfAyahs} آية • ${s.revelationType}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuranReaderScreen(
                      surah: s,
                      settings: widget.settings,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

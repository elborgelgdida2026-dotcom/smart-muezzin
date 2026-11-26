import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';

/// Hadith library: Bukhari, Muslim, Nawawi 40, Riyad as-Salihin.
/// All texts come verbatim from the bundled local dataset
/// (assets/data/hadith.json) — nothing is generated or invented.
/// Subsets are labelled as subsets in the book headers.
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});
  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen>
    with SingleTickerProviderStateMixin {
  final _service = HadithService();
  late TabController _tabs;
  List<HadithBook> _books = [];
  List<Hadith> _shown = [];
  Set<String> _favs = {};
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _chapterFilter;
  bool _favsOnly = false;

  @override
  void initState() {
    super.initState();
    // Placeholder length; recreated with the real book count in _load().
    _tabs = TabController(length: 1, vsync: this);
    _tabs.addListener(_applyFilter);
    _load();
  }

  Future<void> _load() async {
    try {
      await _service.load();
      final favs = await _service.favorites();
      if (mounted) {
        // Recreate the tab controller with the real number of books
        // (4 in the bundled dataset) so TabBar and controller agree.
        _tabs.removeListener(_applyFilter);
        _tabs.dispose();
        _tabs = TabController(
            length: _service.books.length, vsync: this);
        _tabs.addListener(_applyFilter);
        setState(() {
          _books = _service.books;
          _favs = favs;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  String get _currentBookId {
    if (_books.isEmpty) return 'nawawi';
    return _books[_tabs.index.clamp(0, _books.length - 1)].id;
  }

  void _applyFilter() {
    if (_books.isEmpty) return;
    final bookId = _currentBookId;
    var list = _query.isEmpty
        ? _service.byBook(bookId)
        : _service.search(_query).where((h) => h.book == bookId).toList();
    if (_chapterFilter != null) {
      list = list.where((h) => h.chapter == _chapterFilter).toList();
    }
    if (_favsOnly) {
      list = list.where((h) => _favs.contains(h.key)).toList();
    }
    if (mounted) setState(() => _shown = list);
  }

  Future<void> _toggleFav(Hadith h) async {
    final nowFav = await _service.toggleFavorite(h.key);
    if (mounted) {
      setState(() {
        if (nowFav) {
          _favs.add(h.key);
        } else {
          _favs.remove(h.key);
        }
      });
      _applyFilter();
    }
  }

  void _share(Hadith h) {
    final text = '${h.arabic}\n\n— ${h.source}'
        '${h.grade != null ? ' (${h.grade})' : ''}'
        '\nحديث رقم ${h.number} • تطبيق المؤذن الذكي';
    Share.share(text, subject: h.source);
  }

  void _openDetail(Hadith h) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Text(
                h.arabic,
                style: const TextStyle(
                    fontFamily: 'Amiri', fontSize: 22, height: 2.0),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              Text('المصدر: ${h.source}'),
              Text('رقم الحديث: ${h.number}'),
              if (h.chapter.isNotEmpty) Text('الباب/الموضوع: ${h.chapter}'),
              if (h.narrator != null) Text('الراوي: ${h.narrator}'),
              if (h.grade != null) Text('الدرجة: ${h.grade}'),
              const SizedBox(height: 16),
              // No AI summary is included in this Flutter build:
              // there is no on-device inference, and no verified
              // verbatim commentary source could be fetched
              // programmatically. Readers are referred to the printed
              // commentaries instead.
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'للاستزادة في الشرح، راجع: فتح الباري (شرح صحيح '
                    'البخاري)، وشرح النووي على صحيح مسلم، وشرح رياض '
                    'الصالحين للشيخ ابن عثيمين. لا يوجد شرح آلي في هذه '
                    'النسخة.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _share(h),
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _toggleFav(h),
                    icon: Icon(_favs.contains(h.key)
                        ? Icons.star
                        : Icons.star_border),
                    label: const Text('المفضلة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('مكتبة الحديث النبوي')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مكتبة الحديث النبوي')),
        body: Center(child: Text('تعذر تحميل المكتبة: $_error')),
      );
    }
    final daily = _service.dailyHadith();
    final chapters = _service.chaptersOf(_currentBookId);
    final book = _books[_tabs.index.clamp(0, _books.length - 1)];
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الحديث النبوي'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: _books.map((b) => Tab(text: b.title)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (daily != null)
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('حديث اليوم'),
                subtitle: Text(
                  daily.arabic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Amiri'),
                ),
                onTap: () => _openDetail(daily),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (q) {
                _query = q;
                _applyFilter();
              },
              decoration: const InputDecoration(
                hintText: 'ابحث في الأحاديث…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${book.title}: ${book.included} من ${book.totalInBook} — ${book.note}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                FilterChip(
                  label: const Text('المفضلة فقط'),
                  selected: _favsOnly,
                  onSelected: (v) {
                    _favsOnly = v;
                    _applyFilter();
                  },
                ),
              ],
            ),
          ),
          if (chapters.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ChoiceChip(
                    label: const Text('كل الموضوعات'),
                    selected: _chapterFilter == null,
                    onSelected: (_) {
                      _chapterFilter = null;
                      _applyFilter();
                    },
                  ),
                  const SizedBox(width: 6),
                  for (final c in chapters)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(c, overflow: TextOverflow.ellipsis),
                        selected: _chapterFilter == c,
                        onSelected: (_) {
                          _chapterFilter = c;
                          _applyFilter();
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _shown.isEmpty
                ? const Center(child: Text('لا توجد نتائج مطابقة.'))
                : ListView.builder(
                    itemCount: _shown.length,
                    itemBuilder: (context, i) {
                      final h = _shown[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            h.arabic,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 18),
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            '${h.source} • حديث ${h.number}'
                            '${h.grade != null ? ' • ${h.grade}' : ''}',
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              _favs.contains(h.key)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => _toggleFav(h),
                          ),
                          onTap: () => _openDetail(h),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

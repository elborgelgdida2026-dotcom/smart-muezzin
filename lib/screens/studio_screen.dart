import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../models/azkar.dart';
import '../services/hadith_service.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';

/// Islamic Studio: design shareable cards (Friday, Ramadan, Eid,
/// ayah, hadith, dhikr) and export them as high-quality PNG.
///
/// Religious texts are LOCKED from editing: ayahs come verbatim from
/// AlQuran Cloud, hadiths from the bundled verified dataset, and
/// dhikr from the bundled Hisn al-Muslim file. Only the personal
/// greeting line, colours, font and size are editable. The official
/// app logo is printed at the bottom of every card.
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

enum CardKind { friday, ramadan, eidFitr, eidAdha, ayah, hadith, dhikr }

class CardTemplate {
  const CardTemplate(this.name, this.background, this.accent, this.text);
  final String name;
  final Color background;
  final Color accent;
  final Color text;
}

const List<CardTemplate> kTemplates = [
  CardTemplate('كحلي وذهبي', AppTheme.navy, AppTheme.gold, Colors.white),
  CardTemplate('زمردي وذهبي', AppTheme.emerald, AppTheme.gold, Colors.white),
  CardTemplate('كحلي وزمردي', AppTheme.navyDark, AppTheme.emerald, Colors.white),
  CardTemplate('ذهبي وكحلي', Color(0xFFC9A227), AppTheme.navy, AppTheme.navy),
  CardTemplate('أبيض دافئ', AppTheme.warmWhite, AppTheme.emerald, AppTheme.ink),
];

const Map<CardKind, String> kKindTitles = {
  CardKind.friday: 'بطاقة الجمعة',
  CardKind.ramadan: 'بطاقة رمضان',
  CardKind.eidFitr: 'بطاقة عيد الفطر',
  CardKind.eidAdha: 'بطاقة عيد الأضحى',
  CardKind.ayah: 'صورة آية قرآنية',
  CardKind.hadith: 'بطاقة حديث',
  CardKind.dhikr: 'بطاقة ذكر ودعاء',
};

/// Fixed greetings only — no religious quotation is invented here.
const Map<CardKind, String> kGreetingTexts = {
  CardKind.friday: 'جمعة مباركة',
  CardKind.ramadan: 'رمضان كريم',
  CardKind.eidFitr: 'عيد فطر مبارك',
  CardKind.eidAdha: 'عيد أضحى مبارك',
  CardKind.ayah: '',
  CardKind.hadith: '',
  CardKind.dhikr: '',
};

class _StudioScreenState extends State<StudioScreen> {
  final _boundaryKey = GlobalKey();
  final _personalController = TextEditingController();
  final _quran = QuranService();
  final _hadith = HadithService();

  CardKind _kind = CardKind.friday;
  int _templateIndex = 0;
  String _fontFamily = 'Amiri';
  double _fontSize = 30;

  // Locked religious text (never user-editable):
  String _lockedText = '';
  String _lockedSource = '';
  bool _lockedLoading = false;

  // Pickers
  int _pickedSurah = 2;
  int _pickedAyah = 255; // Ayat al-Kursi (2:255) — famous, verifiable
  String _pickedHadithKey = 'nawawi:1';
  String _pickedZikrId = '';

  List<Zikr> _zikrs = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLockedText();
  }

  @override
  void dispose() {
    _personalController.dispose();
    super.dispose();
  }

  Future<void> _loadZikrs() async {
    if (_zikrs.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/data/azkar.json');
    final list = jsonDecode(raw) as List;
    setState(() {
      _zikrs = list
          .map((e) => Zikr.fromJson(e as Map<String, dynamic>))
          .toList();
      _pickedZikrId = _zikrs.isNotEmpty ? _zikrs.first.id : '';
    });
  }

  Future<void> _loadLockedText() async {
    setState(() => _lockedLoading = true);
    try {
      if (_kind == CardKind.ayah) {
        final ayahs = await _quran.surahText(_pickedSurah);
        final ayah = ayahs.firstWhere(
          (a) => a.numberInSurah == _pickedAyah,
          orElse: () => ayahs.first,
        );
        if (mounted) {
          setState(() {
            _lockedText = ayah.text;
            _lockedSource = 'سورة ${_surahName(_pickedSurah)} — آية ${ayah.numberInSurah}';
          });
        }
      } else if (_kind == CardKind.hadith) {
        await _hadith.load();
        final parts = _pickedHadithKey.split(':');
        final found = _hadith.all.firstWhere(
          (h) => h.book == parts[0] && h.number == int.parse(parts[1]),
          orElse: () => _hadith.all.first,
        );
        if (mounted) {
          setState(() {
            _lockedText = found.arabic;
            _lockedSource = '${found.source} — حديث ${found.number}';
          });
        }
      } else if (_kind == CardKind.dhikr) {
        await _loadZikrs();
        final z = _zikrs.firstWhere(
          (e) => e.id == _pickedZikrId,
          orElse: () => _zikrs.first,
        );
        if (mounted) {
          setState(() {
            _lockedText = z.text;
            _lockedSource = z.source;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lockedText = kGreetingTexts[_kind] ?? '';
            _lockedSource = 'المؤذن الذكي';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lockedText = 'تعذر تحميل النص — تحقق من الإنترنت وأعد المحاولة.';
          _lockedSource = '';
        });
      }
    } finally {
      if (mounted) setState(() => _lockedLoading = false);
    }
  }

  String _surahName(int number) {
    // Surah names are resolved from the Quran index when possible;
    // this small fallback covers the picker defaults only.
    const names = {1: 'الفاتحة', 2: 'البقرة', 3: 'آل عمران', 36: 'يس', 67: 'الملك', 112: 'الإخلاص'};
    return names[number] ?? 'سورة $number';
  }

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    final bytes = await _capturePng();
    if (bytes == null) {
      _snack('تعذر تصدير البطاقة.');
    } else {
      try {
        await Gal.putImageBytes(bytes, album: 'المؤذن الذكي');
        _snack('تم حفظ البطاقة في معرض الصور.');
      } catch (e) {
        _snack('تعذر الحفظ في المعرض: $e');
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _shareCard() async {
    setState(() => _busy = true);
    final bytes = await _capturePng();
    if (bytes == null) {
      _snack('تعذر تصدير البطاقة.');
    } else {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'muezzin-card.png', mimeType: 'image/png')],
        text: 'بطاقة من تطبيق المؤذن الذكي',
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = kTemplates[_templateIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('الاستوديو الإسلامي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'النصوص الدينية مقفلة ولا تُعدَّل: الآيات من المصحف، '
            'والأحاديث من المكتبة الموثقة، والأذكار من حصن المسلم. '
            'يمكنك تغيير الألوان والخط والحجم وسطر التهنئة فقط.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CardKind.values.map((k) {
              return ChoiceChip(
                label: Text(kKindTitles[k]!),
                selected: _kind == k,
                onSelected: (_) {
                  setState(() => _kind = k);
                  _loadLockedText();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_kind == CardKind.ayah) _ayahPicker(),
          if (_kind == CardKind.hadith) _hadithPicker(),
          if (_kind == CardKind.dhikr) _dhikrPicker(),
          const SizedBox(height: 12),
          const Text('القالب (الألوان):'),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < kTemplates.length; i++)
                ChoiceChip(
                  label: Text(kTemplates[i].name),
                  selected: _templateIndex == i,
                  onSelected: (_) => setState(() => _templateIndex = i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('الخط:'),
          Wrap(
            spacing: 8,
            children: [
              for (final f in ['Amiri', 'Cairo', 'serif'])
                ChoiceChip(
                  label: Text(f == 'serif' ? 'خط النظام' : f),
                  selected: _fontFamily == f,
                  onSelected: (_) => setState(() => _fontFamily = f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('حجم الخط:'),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 20,
                  max: 44,
                  divisions: 12,
                  label: _fontSize.round().toString(),
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
            ],
          ),
          TextField(
            controller: _personalController,
            decoration: const InputDecoration(
              labelText: 'سطر تهنئة شخصي (اختياري)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // ---- Card preview (this is what gets exported) ----
          AspectRatio(
            aspectRatio: 1,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                decoration: BoxDecoration(
                  color: template.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: template.accent, width: 4),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mosque, color: template.accent, size: 40),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: _lockedLoading
                            ? CircularProgressIndicator(
                                color: template.accent)
                            : SingleChildScrollView(
                                child: Text(
                                  _lockedText.isEmpty
                                      ? kGreetingTexts[_kind] ?? ''
                                      : _lockedText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: _fontFamily == 'serif'
                                        ? null
                                        : _fontFamily,
                                    fontSize: _fontSize,
                                    color: template.text,
                                    height: 1.9,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_lockedSource.isNotEmpty)
                      Text(
                        _lockedSource,
                        style: TextStyle(
                            color: template.accent, fontSize: 14),
                      ),
                    if (_personalController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _personalController.text,
                        style: TextStyle(
                            color: template.text, fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/smart-muezzin-logo.jpg',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المؤذن الذكي',
                          style: TextStyle(
                            color: template.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _saveToGallery,
                  icon: const Icon(Icons.download),
                  label: const Text('حفظ PNG في المعرض'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _shareCard,
                  icon: const Icon(Icons.share),
                  label: const Text('مشاركة البطاقة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ayahPicker() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _pickedSurah,
            decoration: const InputDecoration(
                labelText: 'السورة', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 1, child: Text('الفاتحة')),
              DropdownMenuItem(value: 2, child: Text('البقرة')),
              DropdownMenuItem(value: 3, child: Text('آل عمران')),
              DropdownMenuItem(value: 36, child: Text('يس')),
              DropdownMenuItem(value: 67, child: Text('الملك')),
              DropdownMenuItem(value: 112, child: Text('الإخلاص')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _pickedSurah = v;
                _pickedAyah = 1;
              });
              _loadLockedText();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: _pickedAyah.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'رقم الآية', border: OutlineInputBorder()),
            onFieldSubmitted: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) {
                setState(() => _pickedAyah = n);
                _loadLockedText();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _hadithPicker() {
    return FutureBuilder<void>(
      future: _hadith.load(),
      builder: (context, snapshot) {
        final items = _hadith.all;
        if (items.isEmpty) {
          return const Text('جارٍ تحميل مكتبة الحديث…');
        }
        return DropdownButtonFormField<String>(
          initialValue: _pickedHadithKey,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'اختر الحديث', border: OutlineInputBorder()),
          items: items
              .map((h) => DropdownMenuItem(
                    value: h.key,
                    child: Text(
                      '${h.source} ${h.number}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _pickedHadithKey = v);
            _loadLockedText();
          },
        );
      },
    );
  }

  Widget _dhikrPicker() {
    return FutureBuilder<void>(
      future: _loadZikrs(),
      builder: (context, snapshot) {
        if (_zikrs.isEmpty) {
          return const Text('جارٍ تحميل الأذكار…');
        }
        return DropdownButtonFormField<String>(
          initialValue: _pickedZikrId,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'اختر الذكر', border: OutlineInputBorder()),
          items: _zikrs
              .map((z) => DropdownMenuItem(
                    value: z.id,
                    child: Text(
                      z.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _pickedZikrId = v);
            _loadLockedText();
          },
        );
      },
    );
  }
}

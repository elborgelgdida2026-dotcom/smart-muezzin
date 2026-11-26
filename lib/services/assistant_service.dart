import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hijri/hijri_calendar.dart';
import '../models/azkar.dart';
import '../services/azkar_service.dart';
import '../services/hadith_service.dart';
import '../services/prayer_service.dart';
import '../services/quran_service.dart';
import '../services/settings_service.dart';

/// «رفيق المسلم» — a LOCAL knowledge-based assistant. It is NOT a
/// live large language model and it never generates text of its own.
///
/// HONEST CONTRACT (shown in the UI as a disclaimer):
/// * Every answer comes from the app's own verified datasets only:
///   Quran text/search (AlQuran Cloud), the bundled Hadith dataset,
///   Hisn al-Muslim Azkar, locally computed prayer times, the Hijri
///   calendar, and a small set of fixed, sourced general rulings
///   (Zakat nisab, wudu steps, fasting days).
/// * It NEVER fabricates a Quran verse, a hadith, or a fatwa.
/// * If a question is outside those verified sources, it says so
///   plainly and points the user to a scholar or a printed source —
///   it does not guess.
class AssistantAnswer {
  AssistantAnswer({
    required this.text,
    this.sources = const [],
    this.suggestion = '',
  });

  final String text;
  final List<String> sources;
  final String suggestion; // e.g. 'افتح دليل الحج والعمرة' — UI hint only
}

class AssistantService {
  AssistantService({required this.settings});
  final SettingsService settings;

  final _quran = QuranService();
  final _hadith = HadithService();

  static const _fallback =
      'لا أعرف إجابة موثقة لهذا السؤال من المصادر المتاحة داخل التطبيق. '
      'أنا مساعد محلي أجيب فقط من القرآن الكريم والأحاديث الموثقة والأذكار '
      'ومواقيت الصلاة والتقويم الهجري — ولا أختلق آيات أو أحاديث أو فتاوى. '
      'للسؤال عن أحكام فقهية خاصة، راجع عالمًا موثوقًا أو كتاب فقه معتمدًا.';

  Future<AssistantAnswer> ask(String question) async {
    final q = question.trim();
    if (q.isEmpty) {
      return AssistantAnswer(
        text: 'اكتب سؤالك، وسأجيبك فقط مما هو موثق داخل التطبيق.',
      );
    }
    final lower = q;

    if (_containsAny(lower, ['السلام', 'مرحبا', 'أهلا', 'اهلا', 'صباح', 'مساء'])) {
      return AssistantAnswer(
        text: 'وعليكم السلام ورحمة الله وبركاته. أنا «رفيق المسلم»، مساعد '
            'محلي داخل التطبيق. أستطيع أن: أبحث لك في القرآن الكريم، أو في '
            'الأحاديث الموثقة، أو أعرض أذكار الصباح والمساء، أو أخبرك بموعد '
            'الصلاة القادمة والتاريخ الهجري، أو أشرح أحكامًا عامة موثقة مثل '
            'الزكاة والوضوء. جرّب مثلًا: «ما موعد صلاة العصر؟» أو '
            '«ابحث عن آية الصبر» أو «أذكار الصباح».',
      );
    }

    if (_containsAny(lower, ['موعد', 'متى', 'وقت']) &&
        _containsAny(lower, ['صلاة', 'الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'])) {
      final service = PrayerService(
        method: settings.method,
        madhab: settings.asrHanafi ? Madhab.hanafi : Madhab.shafi,
      );
      final now = DateTime.now();
      final next = service.nextPrayer(settings.city, now);
      final times = service.timesFor(settings.city, now);
      final lines = times
          .map((e) =>
              '${e.arabicName}: ${_hhmm(e.time)}')
          .join('\n');
      return AssistantAnswer(
        text: 'مواقيت الصلاة اليوم في ${settings.city.name}:\n$lines\n\n'
            'الصلاة القادمة: ${next.entry.arabicName} الساعة '
            '${_hhmm(next.entry.time)} (متبقٍ '
            '${next.remaining.inHours} س و${next.remaining.inMinutes % 60} د).',
        sources: ['حساب محلي بحزمة adhan_dart — الطريقة: ${settings.method.arabicName}'],
      );
    }

    if (_containsAny(lower, ['هجري', 'التاريخ'])) {
      final h = HijriCalendar.fromDate(DateTime.now());
      return AssistantAnswer(
        text: 'التاريخ الهجري اليوم: ${h.hDay} ${h.getLongMonthName()} ${h.hYear} هـ.',
        sources: ['التقويم الهجري — حساب تحويلي تقريبي، وقد يختلف يومًا عن الرؤية الرسمية'],
      );
    }

    if (lower.contains('زكاة')) {
      return AssistantAnswer(
        text: 'الزكاة المفروضة على المال: نصاب الذهب 85 جرامًا، ونصاب الفضة '
            '595 جرامًا، فإذا بلغ المال النصاب وحال عليه الحول (سنة هجرية '
            'كاملة) وجب إخراج 2.5% منه. لحساب المبلغ بدقة استخدم حاسبة الزكاة '
            'في التطبيق (المزيد ← حاسبة الزكاة). وللحالات الخاصة (زكاة '
            'التجارة والزروع والأنعام) راجع عالمًا موثوقًا.',
        sources: ['أحكام عامة متفق عليها — للتفاصيل راجع حاسبة الزكاة في التطبيق'],
      );
    }

    if (_containsAny(lower, ['وضوء', 'الوضوء'])) {
      return AssistantAnswer(
        text: 'خطوات الوضوء: النية، ثم التسمية، ثم غسل الكفين، ثم المضمضة '
            'والاستنشاق، ثم غسل الوجه، ثم غسل اليدين إلى المرفقين، ثم مسح '
            'الرأس، ثم مسح الأذنين، ثم غسل القدمين إلى الكعبين — والسنة '
            'غسل كل عضو ثلاث مرات. ودليل أركانه قوله تعالى: ﴿يَا أَيُّهَا '
            'الَّذِينَ آمَنُوا إِذَا قُمْتُمْ إِلَى الصَّلَاةِ فَاغْسِلُوا '
            'وُجُوهَكُمْ وَأَيْدِيَكُمْ إِلَى الْمَرَافِقِ وَامْسَحُوا '
            'بِرُءُوسِكُمْ وَأَرْجُلَكُمْ إِلَى الْكَعْبَيْنِ﴾ [المائدة: 6].',
        sources: ['سورة المائدة، آية 6 — ودليل الصلاة والوضوء في قسم الأطفال'],
      );
    }

    if (_containsAny(lower, ['صيام', 'صوم', 'الصيام'])) {
      return AssistantAnswer(
        text: 'الصيام المفروض: صيام شهر رمضان. ومن صيام التطوع الثابت: صيام '
            'الاثنين والخميس، والأيام البيض (13 و14 و15 من كل شهر هجري)، '
            'ويوم عرفة لغير الحاج، ويوم عاشوراء. تذكيرات الصيام في التطبيق '
            'من الإعدادات ← التذكيرات.',
        sources: ['أحكام عامة ثابتة في السنة'],
      );
    }

    if (_containsAny(lower, ['حج', 'عمرة', 'الحج', 'العمرة'])) {
      return AssistantAnswer(
        text: 'دليل الحج والعمرة الكامل موجود في التطبيق: من المزيد ← '
            '«دليل الحج والعمرة»، فيه خطوات العمرة (الإحرام، الطواف 7 '
            'أشواط بعدّاد، السعي 7 أشواط بعدّاد، الحلق/التقصير) وخطوات الحج '
            'يومًا بيوم (عرفة، مزدلفة، منى، رمي الجمرات بعدّاد) مع الأدعية '
            'الموثقة في كل خطوة وقائمة تحقق تحفظ تقدمك.',
        sources: ['دليل الحج والعمرة داخل التطبيق'],
        suggestion: 'افتح دليل الحج والعمرة',
      );
    }

    if (_containsAny(lower, ['تفسير'])) {
      return AssistantAnswer(
        text: 'التفسير متاح لكل آية من داخل قارئ القرآن: افتح أي سورة، '
            'واضغط زر «التفسير» بجانب الآية، فيظهر تفسير الميسر (مجمع '
            'الملك فهد) مع التنبيه أن التفسير رأي علمي وليس نص القرآن نفسه.',
        sources: ['تفسير الميسر — AlQuran Cloud'],
        suggestion: 'افتح القرآن الكريم',
      );
    }

    if (_containsAny(lower, ['ختمة', 'الختمة'])) {
      return AssistantAnswer(
        text: 'خطة الختمة موجودة في التطبيق: من المزيد ← «خطة الختمة»، '
            'اختر مدة الختمة (7 أو 14 أو 30 أو 90 يومًا) أو عدد صفحات '
            'يومي مخصص، ويحسب لك التطبيق الصفحات اليومية من 604 صفحات '
            'ويتابع تقدمك ويذكرك بوردك اليومي.',
        sources: ['خطة الختمة داخل التطبيق'],
        suggestion: 'افتح خطة الختمة',
      );
    }

    // Quran search: "ابحث عن آية ..." or any question mentioning آية/سورة
    if (_containsAny(lower, ['آية', 'سورة', 'ابحث في القرآن', 'القرآن'])) {
      final query = _stripIntent(lower, [
        'ابحث', 'عن', 'آية', 'سورة', 'في', 'القرآن', 'الكريم', '؟', '?',
      ]);
      if (query.isEmpty) {
        return AssistantAnswer(
          text: 'اكتب كلمة من الآية التي تبحث عنها، مثلًا: «ابحث عن آية الصبر».',
        );
      }
      try {
        final results = await _quran.search(query);
        if (results.isEmpty) {
          return AssistantAnswer(
            text: 'لم أجد آية تحتوي على «$query» في المصحف.',
            sources: ['بحث AlQuran Cloud — النص العثماني'],
          );
        }
        final shown = results.take(3).toList();
        final lines = shown
            .map((a) =>
                '﴿${a.text}﴾ — سورة ${a.surahNumber}، آية ${a.numberInSurah}')
            .join('\n\n');
        return AssistantAnswer(
          text: 'وجدت ${results.length} نتيجة لـ«$query» (أعرض أول 3):\n\n$lines',
          sources: ['بحث AlQuran Cloud — النص العثماني'],
        );
      } catch (_) {
        return AssistantAnswer(
          text: 'تعذر البحث في القرآن الآن (تحقق من الإنترنت وحاول مجددًا).',
        );
      }
    }

    // Hadith search
    if (_containsAny(lower, ['حديث', 'الحديث'])) {
      final query = _stripIntent(lower, [
        'ابحث', 'عن', 'حديث', 'الحديث', '؟', '?',
      ]);
      await _hadith.load();
      final results =
          query.isEmpty ? _hadith.all.take(3).toList() : _hadith.search(query);
      if (results.isEmpty) {
        return AssistantAnswer(
          text: 'لم أجد حديثًا مطابقًا في المكتبة المضمّنة (258 حديثًا). '
              'المكتبة تحتوي النووي كاملًا وأول 100 من البخاري ومسلم — '
              'جرّب كلمة أخرى.',
          sources: ['مكتبة الحديث داخل التطبيق'],
        );
      }
      final lines = results
          .take(3)
          .map((h) => '«${h.arabic}» — ${h.source} رقم ${h.number}')
          .join('\n\n');
      return AssistantAnswer(
        text: 'من مكتبة الحديث:\n\n$lines',
        sources: ['مكتبة الحديث داخل التطبيق — نصوص حرفية موثقة'],
      );
    }

    // Azkar by category
    if (_containsAny(lower, ['أذكار', 'اذكار', 'دعاء', 'الأذكار'])) {
      String? category;
      for (final c in AzkarService.categories) {
        if (lower.contains(c.replaceFirst('أذكار ', '')) ||
            lower.contains(c)) {
          category = c;
          break;
        }
      }
      category ??= 'أذكار الصباح';
      final raw = await rootBundle.loadString('assets/data/azkar.json');
      final data = jsonDecode(raw) as List;
      final items = data
          .where((e) => (e as Map)['category'] == category)
          .map((e) => Zikr.fromJson(e as Map<String, dynamic>))
          .toList();
      if (items.isEmpty) {
        return AssistantAnswer(
          text: 'لا توجد أذكار «$category» في المكتبة المضمّنة بعد.',
          sources: ['أذكار حصن المسلم — assets/data/azkar.json'],
        );
      }
      final first = items.first;
      return AssistantAnswer(
        text: 'من $category (${items.length} ذكرًا في المكتبة):\n\n'
            '«${first.text}»\nالمصدر: ${first.source} — التكرار: ${first.repetitions}\n\n'
            'لعرض كل الأذكار افتح: الأذكار ← $category.',
        sources: ['حصن المسلم — ${first.source}'],
        suggestion: 'افتح الأذكار',
      );
    }

    return AssistantAnswer(text: _fallback);
  }

  bool _containsAny(String text, List<String> words) =>
      words.any((w) => text.contains(w));

  String _stripIntent(String text, List<String> words) {
    var out = text;
    for (final w in words) {
      out = out.replaceAll(w, ' ');
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

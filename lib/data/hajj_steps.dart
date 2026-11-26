/// Step-by-step Hajj & Umrah guide (Tamattu' — the most common form).
///
/// SOURCE HONESTY: the duas below are quoted verbatim from the
/// well-known collections named in each step's `duaSource`. No dua
/// is invented. Rites differ between schools and personal
/// circumstances — the guide says plainly to confirm details with a
/// trusted scholar or an official Hajj guidebook. Counters (Tawaf 7,
/// Sa'i 7, stoning 7 per Jamarah) follow the established rites.
class HajjStep {
  const HajjStep({
    required this.id,
    required this.title,
    required this.description,
    this.dua,
    this.duaSource,
    this.counterTarget,
    this.counterLabel,
  });

  final String id;
  final String title;
  final String description;
  final String? dua;
  final String? duaSource;
  final int? counterTarget;
  final String? counterLabel;
}

class HajjSection {
  const HajjSection({
    required this.id,
    required this.title,
    required this.steps,
  });

  final String id;
  final String title;
  final List<HajjStep> steps;
}

const List<HajjSection> hajjGuide = [
  HajjSection(
    id: 'umrah',
    title: 'العمرة',
    steps: [
      HajjStep(
        id: 'umrah_ihram',
        title: '1 — الإحرام من الميقات',
        description:
            'الاغتسال والتطيب، ولبس ملابس الإحرام، ثم النية: «لبيك اللهم عمرة». '
            'ومن الميقات تبدأ التلبية وتستمر حتى استلام الحجر الأسود.',
        dua: 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، '
            'إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
        duaSource: 'متفق عليه (صحيح البخاري ومسلم)',
      ),
      HajjStep(
        id: 'umrah_tawaf',
        title: '2 — الطواف حول الكعبة (7 أشواط)',
        description:
            'ابدأ من الحجر الأسود، واجعل الكعبة عن يسارك، وطُف سبعة أشواط. '
            'اضغط زر العدّاد بعد كل شوط. بين الركن اليماني والحجر الأسود '
            'ادعُ بالدعاء أدناه.',
        dua: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً '
            'وَقِنَا عَذَابَ النَّارِ',
        duaSource: 'رواه أبو داود (حسنه الألباني) — وعند استلام الحجر: «الله أكبر» (متفق عليه)',
        counterTarget: 7,
        counterLabel: 'شوط',
      ),
      HajjStep(
        id: 'umrah_prayer',
        title: '3 — ركعتان خلف مقام إبراهيم',
        description:
            'صلِّ ركعتين خلف المقام إن تيسر، وإلا في أي موضع من المسجد. '
            'يُستحب قراءة ﴿قُلْ يَا أَيُّهَا الْكَافِرُونَ﴾ في الأولى '
            'و﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾ في الثانية، ثم اشرب من ماء زمزم.',
      ),
      HajjStep(
        id: 'umrah_sai',
        title: '4 — السعي بين الصفا والمروة (7 أشواط)',
        description:
            'اصعد الصفا واقرأ الآية، ثم ادعُ بالدعاء أدناه ثلاث مرات. '
            'الشوط من الصفا إلى المروة شوط واحد، والعودة شوط آخر، '
            'حتى تكمل سبعة أشواط تنتهي عند المروة.',
        dua: 'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ — '
            'أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ. '
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
            'وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا إِلَهَ إِلَّا '
            'اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ '
            'الْأَحْزَابَ وَحْدَهُ',
        duaSource: 'رواه مسلم',
        counterTarget: 7,
        counterLabel: 'شوط',
      ),
      HajjStep(
        id: 'umrah_halq',
        title: '5 — الحلق أو التقصير',
        description:
            'للحلق أجر أعظم، والتقصير مجزئ. للمرأة تقصير قدر أنملة من '
            'أطراف شعرها. وبهذا تتم العمرة ويحلّ المحرم من إحرامه.',
      ),
    ],
  ),
  HajjSection(
    id: 'hajj',
    title: 'الحج (تمتع)',
    steps: [
      HajjStep(
        id: 'hajj_ihram',
        title: '1 — يوم التروية (8 ذو الحجة): الإحرام والمبيت بمنى',
        description:
            'أحرم بالحج من مكانك بمكة: «لبيك اللهم حجًا»، ثم توجه إلى منى '
            'وصلِّ الظهر والعصر والمغرب والعشاء والفجر قصرًا من غير جمع، '
            'وبات فيها.',
        dua: 'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، '
            'إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
        duaSource: 'متفق عليه (صحيح البخاري ومسلم)',
      ),
      HajjStep(
        id: 'hajj_arafat',
        title: '2 — يوم عرفة (9 ذو الحجة): الوقوف بعرفة',
        description:
            'الوقوف بعرفة هو ركن الحج الأعظم: من زوال الشمس إلى غروبها. '
            'أكثر من الدعاء والذكر — خير الدعاء دعاء يوم عرفة. '
            'صلِّ الظهر والعصر جمع تقديم وقصرًا، ثم أفض بعد الغروب إلى مزدلفة.',
        dua: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
            'وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        duaSource: 'رواه الترمذي (حسن) — «خير الدعاء دعاء يوم عرفة»',
      ),
      HajjStep(
        id: 'hajj_muzdalifah',
        title: '3 — مزدلفة: المبيت وجمع الحصى',
        description:
            'صلِّ المغرب والعشاء جمعًا وقصرًا في مزدلفة، وبِت فيها، وصلِّ '
            'الفجر في أول وقتها، ثم اجمع سبعين حصاة (أو على الأقل 49) '
            'لرمي الجمرات، ثم توجه إلى منى بعد طلوع الشمس.',
      ),
      HajjStep(
        id: 'hajj_day10',
        title: '4 — يوم النحر (10 ذو الحجة): رمي جمرة العقبة',
        description:
            'ارمِ جمرة العقبة بسبع حصيات متعاقبات، مكبِّرًا مع كل حصاة، '
            'ثم اذبح الهدي (للمتمتع والقارن)، ثم احلق أو قصِّر، ثم طُف '
            'طواف الإفاضة واسعَ سعي الحج إن لم تكن سعيت مع طواف القدوم.',
        dua: 'اللهُ أَكْبَرُ — مع كل حصاة',
        duaSource: 'رواه البخاري ومسلم',
        counterTarget: 7,
        counterLabel: 'حصاة',
      ),
      HajjStep(
        id: 'hajj_tashreeq',
        title: '5 — أيام التشريق (11 و12 و13): رمي الجمرات الثلاث',
        description:
            'في كل يوم من أيام التشريق ارمِ الجمرات الثلاث بالترتيب: '
            'الصغرى ثم الوسطى ثم الكبرى (العقبة)، سبع حصيات لكل جمرة، '
            'مكبِّرًا مع كل حصاة. من تعجّل في يومين فلا إثم عليه، '
            'ومن تأخر فلا إثم عليه.',
        dua: 'اللهُ أَكْبَرُ — مع كل حصاة',
        duaSource: 'رواه البخاري ومسلم',
        counterTarget: 21,
        counterLabel: 'حصاة (7 لكل جمرة)',
      ),
      HajjStep(
        id: 'hajj_farewell',
        title: '6 — طواف الوداع',
        description:
            'قبل مغادرة مكة طُف بالبيت سبعة أشواط طواف الوداع، وهو واجب '
            'على الحاج والمعتمر من غير أهل مكة. والحائض والنفساء معذورتان منه.',
        counterTarget: 7,
        counterLabel: 'شوط',
      ),
    ],
  ),
];

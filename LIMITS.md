# حدود المشروع — LIMITS.md (بصراحة كاملة)

هذا المشروع **هيكل Flutter حقيقي وشغال**، وليس تطبيقًا مكتملًا بكل
الأقسام الـ 34 من المواصفة الأصلية. ما يلي هو ما يفعله وما لا يفعله،
حتى لا يُدَّعى اكتمال شيء لم يُنفَّذ ويُختبر.

## ما يفعله فعلًا (v1.0.0)

- مواقيت الصلاة بحزمة `adhan` محليًا (دون إنترنت بعد حفظ المدينة)،
  الطريقة الافتراضية: الهيئة المصرية العامة للمساحة، مع باقي الطرق،
  ومذهب العصر، وتعديل الدقائق لكل صلاة.
- GPS / اختيار مدينة يدويًا وحفظ أكثر من مدينة.
- القرآن الكريم من AlQuran Cloud: فهرس 114 سورة، نص عثماني، بحث،
  تلاوة صوتية (ar.alafasy)، حفظ موضع القراءة محليًا.
- أذكار حصن المسلم (15 ذكرًا موثقًا في `assets/data/azkar.json`)
  مع عدادات تفاعلية. المكتبة الكاملة تحتاج إكمال الملف بنفس الصيغة.
- مسبحة محفوظة، حاسبة زكاة، تقويم هجري ومحوّل، رمضان، قسم أطفال،
  إعدادات (لغة/وضع ليلي/حجم خط/تذكيرات/نسخ احتياطي JSON).
- قبلة: اتجاه ومسافة محسوبان من الإحداثيات + بوصلة الجهاز الحية
  (تحتاج جهازًا حقيقيًا به مستشعر بوصلة).
- **إذاعات القرآن الكريم (منقولة من PWA):** 8 محطات بث مباشر
  (القاهرة، السعودية، العفاسي، السديس، المنشاوي، عبد الباسط،
  الحصري، الغامدي) مع تشغيل/إيقاف، صوت، مفضلة محفوظة، مؤقت إيقاف
  15–90 دقيقة، وإعادة اتصال تلقائية عند انقطاع البث (روابط بديلة
  مضمّنة لكل محطة). المصادر موثقة في `lib/models/radio_station.dart`.
- **الاستوديو الإسلامي (منقول من PWA):** بطاقات الجمعة/رمضان/العيد/
  الآية/الحديث/الذكر بـ 5 قوالب و3 خطوط، وتصدير PNG إلى المعرض أو
  المشاركة. النصوص الدينية مقفلة من التعديل (آيات من AlQuran Cloud،
  أحاديث من `assets/data/hadith.json`، أذكار من `assets/data/azkar.json`).
- **المساجد القريبة (منقول من PWA):** بيانات حقيقية من
  OpenStreetMap/Overpass + Nominatim، مع خريطة (flutter_map)،
  ترتيب حسب المسافة، اتجاهات عبر Google Maps، مفضلة، والإبلاغ عن
  بيانات خاطئة (يُحفظ محليًا). **لا تُعرض مواعيد الإقامة أو الجمعة
  لعدم وجود مصدر موثوق لها** — وهذا مذكور داخل التطبيق نفسه.
- **مكتبة الحديث النبوي (منقولة من PWA):** 258 حديثًا بنصوص حرفية
  موثقة في `assets/data/hadith.json`: النووي 40 كاملًا، وأول 100 من
  البخاري (من أصل 7,589)، وأول 100 من مسلم، و16 من رياض الصالحين
  (منقولة حرفيًا من sunnah.com). كل كتاب يعرض صراحةً «المضمّن من
  الأصل» حتى لا يُفهم أنه كامل. لا يوجد تلخيص/شرح آلي في هذه النسخة
  — الشرح يُحال إلى كتب الشروح المطبوعة المذكورة في التطبيق.
- **المصحف المطبوع 604 صفحة (منقول من PWA):** صفحات المصحف المدني
  كاملة (SVG من AlFurqan API)، تُعرض دون اقتصاص، مع شريط كحلي
  (اسم السورة فوق، ورقم الصفحة والجزء تحتها، وزر ×)، وتقليب
  ثلاثي الأبعاد بالسحب، وآيات الصفحة أسفلها مع تلاوة عند الضغط،
  وزر «عرضها في المصحف المطبوع» من أي سورة، وحفظ آخر صفحة.
  **قيود صريحة:** (1) الضغط مباشرة على آية داخل صورة الصفحة
  **غير متاح** — إحداثيات الآيات الدقيقة من Quran Foundation API
  تتطلب مصادقة مدفوعة (تم التحقق: HTTP 400 بدونها)؛ التطبيق يذكر
  هذا صراحة ويستخدم قائمة الآيات أسفل الصفحة كبديل. (2) صوت تقليب
  الصفحات **مولّد صناعيًا** (ضجيج مصفّى + طرقة خفيفة،
  `assets/audio/page_turn.wav`) وليس تسجيلًا حقيقيًا لصفحات —
  لم يُعثر على تسجيل ملكية عامة قابل للتحقق.
- **خطة الختمة:** 7/14/30/90 يومًا أو صفحات يومية مخصصة، صفحات يومية
  محسوبة من 604، تقدم ونسبة إنجاز وأيام متبقية، وتذكير يومي بالورد —
  كلها محفوظة محليًا.
- **دليل الحج والعمرة:** خطوات العمرة والحج (تمتع) مع أدعية منقولة
  حرفيًا من كتب السنة المذكورة في كل خطوة، وعدّادات الطواف والسعي
  ورمي الجمرات، وقائمة تحقق محفوظة محليًا.
- **رفيق المسلم:** مساعد محلي — ليس نموذج ذكاء اصطناعي حيًا — يجيب
  فقط من مصادر موثقة داخل التطبيق (القرآن والأحاديث والأذكار ومواقيت
  الصلاة والتقويم الهجري وأحكام عامة موثقة)، ولا يختلق آيات أو أحاديث
  أو فتاوى؛ وعند غياب مصدر موثق يقول ذلك ويرشد إلى عالم موثوق.
- **تتبع العبادات:** سجل يومي محلي للصلوات والصيام وصفحات القرآن
  والأذكار والتسبيح، مع رسم بياني أسبوعي وسلسلة أيام وملخص شهري —
  محلي فقط، لا يُرفع لأي خادم.
- **التفسير:** تفسير الميسر (مجمع الملك فهد) لكل آية من AlQuran Cloud،
  مع تنبيه أن التفسير رأي علمي وليس نص القرآن، ومحفوظ محليًا بعد قراءته.
- **ودجت الشاشة الرئيسية:** ودجت أندرويد أصلي «الصلاة القادمة»
  (الاسم والوقت والعد التنازلي بالدقائق) عبر حزمة `home_widget` +
  `NextPrayerWidgetProvider`. **قيد صريح:** ودجت شاشة القفل غير متاح
  — أندرويد 12+ ألغى ودجت شاشة القفل من نظام التشغيل نفسه؛ على شاشة
  القفل يظهر إشعار التذكير فقط. الودجت يحتاج اختبارًا على جهاز حقيقي
  (يُحدَّث عند تشغيل التطبيق وبالضغط على «تحديث الودجت»).
- **دليل الصلاة والوضوء الكامل للكبار:** 9 أقسام و54 عنصرًا في
  `lib/data/prayer_guide.dart` مع شاشة متابعة (`prayer_guide_screen.dart`):
  الوضوء خطوة بخطوة بدليله من سورة المائدة (الآية 6)، ونواقضه
  وأخطاؤه الشائعة، والتيمم والغسل (الواجب والسنة)، والصلوات الخمس
  (عدد الركعات والشروط والأركان والواجبات والمبطلات)، وكيف تصلي
  خطوة بخطوة مع الفاتحة والتشهد والصلاة الإبراهيمية منقولة حرفيًا
  بمصادرها (13 نصًا موثقًا)، وسجود السهو، والجماعة والإمامة،
  وصلاة المسافر (القصر والجمع) والمريض والجمعة والعيد والجنازة.
  مواضع الخلاف بين المذاهب (رفع اليدين، وضع اليدين، البسملة،
  قنوت الفجر، عدد تكبيرات العيد، مسافة القصر) مذكورة كما هي دون
  فرض قول واحد. وضع المتابعة (checklist) محفوظ محليًا.
- **الخطوط مضمّنة الآن:** Cairo (خط متغير 200–1000 من Google Fonts)
  وAmiri (عادي + عريض) في `fonts/`، موثقة ومُتحقق منها في
  `fonts/README.md`، ومعلنة في `pubspec.yaml`؛ وخط Cairo هو خط
  الواجهة الافتراضي في `lib/theme/app_theme.dart`. المجلد `fonts/`
  لم يعد مستثنًى من Git (أُزيل من `.gitignore`) حتى يصل للبناء
  على GitHub Actions.
- **الحسابات والمزامنة السحابية (اختياري):** تسجيل دخول Supabase
  للمستخدم العادي، ومزامنة النسخة الاحتياطية إلى جدول `user_sync`
  (صف واحد لكل مستخدم، وRLS يمنع غير صاحبه من قراءته) بعد تفعيل صريح
  من المستخدم، مع حذف النسخة السحابية. التطبيق يعمل كاملًا دون حساب.
  **لم تُختبَر ضد مشروع Supabase حي** (لا يوجد مشروع على جهاز البناء)
  — نفّذ `supabase/user_sync.sql` على مشروع حقيقي أولًا.

## ما لا يفعله بعد — ويحتاج عملًا إضافيًا حقيقيًا

1. **الأذان في الخلفية بعد إغلاق التطبيق أو إعادة تشغيل الجهاز:**
   الكود يجدول تذكيرات محلية (`flutter_local_notifications`)، لكن
   التسليم الموثوق بعد إعادة التشغيل وفي وضع Doze يحتاج إذن المنبه
   الدقيق (exact alarm) وإعدادات البطارية، **ويجب اختباره على جهاز
   حقيقي**. لا ندّعي تجاوز الوضع الصامت أو قيود النظام.
2. **لوحة تحكم الإدارة:** موجودة الآن ككود Flutter كامل + ملفات
   Supabase (`supabase/schema.sql` و`rls.sql` و`seed.sql` و`README.md`):
   دخول بمصادقة Supabase، أدوار (user/moderator/admin)، مراجعة المحتوى
   الديني قبل النشر، إدارة القرّاء والمؤذنين والمناسبات والمدن،
   جدولة الإشعارات، مراجعة البلاغات، سجل تدقيق غير قابل للتعديل،
   وإحصائيات مجمّعة فقط (لا تُخزَّن بيانات عبادات فردية في الخادم).
   **لكنها تتطلب مشروع Supabase حيًا لتعمل، ولم تُختبَر ضد مشروع حي**
   (لا يوجد مشروع على جهاز البناء) — نفّذ خطوات `supabase/README.md`
   على مشروع حقيقي أولًا. بدون إعداد Supabase تظهر شاشة إعدادات
   فقط، بلا بيانات وهمية. الإرسال الفعلي (push) للإشعارات يحتاج
   موفّر دفع مربوطًا بجدول notifications وهو خارج هذه النسخة —
   اللوحة تسجّل الإرسال ولا تدّعي وصوله قبل ربطه.
3. **التلاوات المرخّصة:** التشغيل الحالي يستخدم روابط AlQuran Cloud
   العامة (ar.alafasy). تلاوات القراء الآخرين يجب أن تأتي من مصادر
   مرخّصة قانونيًا؛ لا تُضمَّن ملفات صوتية مسروقة.
4. **الخطوط:** مضمّنة الآن في `fonts/` (Cairo المتغير + Amiri،
   OFL، انظر `fonts/README.md`) — لم تعد تحتاج تحميلًا يدويًا.
5. **الاختبار:** الكود مُراجَع يدويًا وفُحصت ملفات Dart بالتحقق
   النحوي، لكن `flutter analyze` و`flutter test` لم تُشغَّلا هنا
   (لا يوجد Flutter SDK على جهاز البناء) — سير العمل في GitHub
   يشغّلهما تلقائيًا عند كل دفع، وأي خطأ سيظهر هناك قبل البناء.

## ما لم يُبنَ بعد من المواصفة الأصلية (34 قسمًا) — فحص 2026-11-26

بعد تنفيذ دليل الصلاة/الوضوء الكامل للكبار وتضمين الخطوط، **لا
يوجد قسم غائب من الأقسام الـ 34 في حزمة Flutter**. الباقي قيود
جزئية مذكورة في الجدول: مكتبة الأذكار 15 ذكرًا فقط، ومكتبة الحديث
مجموعات فرعية معلنة، والأذان بعد الإغلاق/إعادة التشغيل يحتاج
اختبار جهاز حقيقي، ولوحة الإدارة تحتاج مشروع Supabase حيًا،
والدفع (push) خارج النطاق، وودجت شاشة القفل مستحيل في أندرويد 12+.

## ما لم يُبنَ محليًا

- **لم يُبنَ أي ملف APK أو AAB على هذا الجهاز.** لا يوجد ملف
  `.apk` في هذا المشروع، ولم يُنشأ ملف وهمي. الـ APK/AAB الحقيقيان
  يُبنيان فقط عبر GitHub Actions (انظر README.md).

---

# LIMITS.md — English (summary)

This is a real, working Flutter shell (v1.0.0), not the full 34-section
spec. It does: local prayer times (adhan package, Egyptian method
default), GPS/manual cities, Quran via AlQuran Cloud (Uthmani text,
search, audio, bookmarks), Hisn al-Muslim Azkar (15 verified items;
full library needs completing `assets/data/azkar.json`), Tasbih,
Zakat, Hijri calendar, Ramadan, kids, settings, backup JSON, Qibla
(math + live compass on a real device).

It does NOT yet do: reliable background Adhan after reboot/Doze
(needs exact-alarm permission + real-device testing; never claims to
bypass silent mode), licensed reciter audio beyond the public
AlQuran Cloud streams. Fonts are now bundled (`fonts/`: Cairo
variable + Amiri, OFL — see `fonts/README.md`); the full adult
prayer/wudu guide is now implemented (`lib/data/prayer_guide.dart`,
9 sections, 54 items, verbatim texts with sources, differences
between schools stated as such).

New in this version: Khatma plan; Hajj/Umrah step-by-step guide;
local knowledge-based assistant «رفيق المسلم» (not a live LLM, never
fabricates verses/hadith/fatwas); worship tracking (local only);
per-ayah tafsir (Tafsir al-Muyassar via AlQuran Cloud); home-screen
widget (Android 12+ removed lock-screen widgets from the OS, so no
lock-screen widget is possible); optional user accounts & cloud sync
via Supabase (`user_sync` table, explicit consent, no-account default
preserved) — **not tested against a live Supabase project**.

The Admin Panel (spec section 27) is now present as Flutter code +
Supabase backend files (`supabase/schema.sql`, `rls.sql`, `seed.sql`,
`README.md`): Supabase Auth login, roles, religious-content review
before publishing, reciter/muezzin/event/city management, notification
scheduling, report review, an immutable audit log, and aggregate-only
stats. **It requires a live Supabase project to function and was NOT
tested against one** (none exists on the build machine) — follow
`supabase/README.md` on a real project first. Without Supabase
configured it shows a setup screen, never fake data. Actual push
delivery of notifications needs a push provider wired to the
`notifications` table and is outside this build — the panel records a
send, it does not claim delivery.

Ported from the PWA in this version: Quran radio (8 live stations),
Islamic Studio (card designer, locked religious texts, PNG export),
nearby mosques (OpenStreetMap/Overpass — no iqama/Jumuah times, for
lack of a verified source), Hadith library (258 verified hadiths;
Bukhari/Muslim/Riyad are labelled subsets, Nawawi 40 is complete),
and the 604-page printed Mushaf (AlFurqan SVG; direct tap-on-ayah
inside the page image is NOT available — Quran Foundation API needs
paid auth; the page-turn sound is synthesized, not a recording).

**Sections of the original 34-section spec NOT in this Flutter
build (verified by code search 2026-11-26):** none — all 34 sections
are now present. Remaining partial items: the Azkar library (15
items only), the Hadith library (labelled subsets), background Adhan
after reboot (needs real-device testing), the Admin Panel (needs a
live Supabase project), push delivery (out of scope), and the
lock-screen widget (not possible on Android 12+ — the OS removed
lock-screen widgets); the home-screen widget needs real-device testing.

**No APK/AAB was built locally.** No fake `.apk` file exists in this
project. Real APK/AAB are built only by GitHub Actions.

# المؤذن الذكي – Smart Muezzin (Flutter)

تطبيق إسلامي متكامل: مواقيت الصلاة والأذان، القرآن الكريم، القبلة،
الأذكار، المسبحة، حاسبة الزكاة، التقويم الهجري، رمضان، قسم الأطفال.

> **ملاحظة صريحة:** لا يوجد ملف APK مبني محليًا في هذا المستودع،
> لأن جهاز البناء الحالي لا يحتوي على Flutter/Android SDK.
> الـ APK والـ AAB الحقيقيان يُبنيان على GitHub Actions (انظر الخطوات أدناه).

## ما فيه

- 5 تبويبات سفلية: الرئيسية، القرآن الكريم، القبلة، الأذكار، المزيد
- مواقيت الصلاة بحزمة `adhan` — الطريقة الافتراضية: الهيئة المصرية
  العامة للمساحة، مع كل طرق الحساب، ومذهب العصر (شافعي/حنفي)،
  وتعديل كل صلاة بالدقائق، وحساب محلي يعمل دون إنترنت
- GPS أو اختيار مدينة يدويًا، وحفظ أكثر من مدينة
- القرآن من AlQuran Cloud (نص عثماني، فهرس 114 سورة، بحث،
  تلاوة صوتية، حفظ موضع القراءة محليًا)
- أذكار حصن المسلم بنصوصها ومصادرها مع عدادات تفاعلية
  (`assets/data/azkar.json`)
- **إذاعات القرآن الكريم**: 8 محطات بث مباشر موثقة (القاهرة،
  السعودية، العفاسي، السديس، المنشاوي، عبد الباسط، الحصري،
  الغامدي) مع إيقاف/تشغيل، مستوى صوت، مفضلة، مؤقت إيقاف 15–90 دقيقة
- **الاستوديو الإسلامي**: تصميم بطاقات (جمعة/رمضان/عيد/آية/حديث/
  ذكر) بـ 5 قوالب و3 خطوط، والنصوص الدينية مقفلة من التعديل،
  وتصدير PNG إلى المعرض أو مشاركتها، مع الشعار الرسمي أسفل كل بطاقة
- **المساجد القريبة**: بيانات حقيقية من OpenStreetMap/Overpass مع
  خريطة ودبابيس مرقّمة، ترتيب حسب المسافة، اتجاهات، مفضلة،
  والإبلاغ عن بيانات خاطئة — ولا تُعرض مواعيد الإقامة/الجمعة
  لعدم وجود مصدر موثوق لها
- **مكتبة الحديث النبوي**: 258 حديثًا بنصوص حرفية موثقة
  (النووي 40 كاملًا، أول 100 من البخاري، أول 100 من مسلم،
  16 من رياض الصالحين) في `assets/data/hadith.json` مع بحث
  وتصنيف وحديث اليوم ومفضلة ومشاركة — بلا تلخيص آلي مختلق
- **المصحف المطبوع**: صفحات المصحف المدني الـ 604 كاملة (SVG من
  AlFurqan) مع تقليب ثلاثي الأبعاد وصوت تقليب وآيات الصفحة
  بالتلاوة، وزر «عرضها في المصحف المطبوع» من أي سورة
- **لوحة تحكم الإدارة (Supabase)**: دخول من المزيد بعد تسجيل دخول
  مشرف/مدير، مع إدارة المستخدمين والأدوار، ومراجعة المحتوى الديني
  (الأذكار والأحاديث لا تظهر للعامة حتى تُعتمد مع مصدر موثق)،
  وإدارة القرّاء والمؤذنين والمناسبات والمدن والترجمات، وجدولة
  الإشعارات العامة، ومراجعة البلاغات، وسجل تدقيق غير قابل للتعديل.
  بدون مشروع Supabase حي تظهر شاشة إعدادات فقط — بلا بيانات وهمية.
  التفاصيل الكاملة في `supabase/README.md`
- **دليل الصلاة والوضوء (كامل للكبار)**: الوضوء خطوة بخطوة بدليله
  من سورة المائدة، ونواقضه وأخطاؤه الشائعة، والتيمم والغسل،
  والصلوات الخمس (عدد الركعات والشروط والأركان والواجبات
  والمبطلات)، وكيف تصلي خطوة بخطوة مع الفاتحة والتشهد والصلاة
  الإبراهيمية حرفيًا بمصادرها، وسجود السهو، والجماعة والإمامة،
  وصلاة المسافر والمريض والجمعة والعيد والجنازة — مع وضع
  متابعة (checklist) محفوظ محليًا، ومواضع الخلاف بين المذاهب
  مذكورة كما هي دون فرض قول واحد
- **الخطوط مضمّنة**: Cairo (خط متغير، OFL) وAmiri في `fonts/`
  (انظر `fonts/README.md` للمصادر والتحقق) — خط Cairo هو خط
  الواجهة الافتراضي، وAmiri للنصوص القرآنية والأدعية
- **خطة الختمة**: اختر 7 أو 14 أو 30 أو 90 يومًا أو عدد صفحات يومي
  مخصص، يحسب التطبيق صفحاتك اليومية من 604، ويتابع تقدمك ونسبة
  الإنجاز والأيام المتبقية، مع تذكير يومي بالورد
- **دليل الحج والعمرة**: خطوات العمرة والحج (تمتع) مع أدعية موثقة
  من كتب السنة في كل خطوة، وعدّادات للطواف (7) والسعي (7) ورمي
  الجمرات (7 لكل جمرة)، وقائمة تحقق محفوظة محليًا
- **رفيق المسلم**: مساعد محلي (ليس نموذج ذكاء اصطناعي حيًا) يجيب
  فقط من مصادر موثقة داخل التطبيق — القرآن والأحاديث والأذكار
  ومواقيت الصلاة والتقويم الهجري — ولا يختلق آيات أو أحاديث أو فتاوى
- **تتبع العبادات**: سجل يومي محلي للصلوات والصيام وصفحات القرآن
  والأذكار والتسبيح، مع رسم بياني أسبوعي وسلسلة أيام وملخص شهري —
  محلي فقط، بلا رفع لأي خادم
- **التفسير**: زر «التفسير» بجانب كل آية في قارئ القرآن يعرض تفسير
  الميسر (مجمع الملك فهد) من AlQuran Cloud مع تنبيه أن التفسير رأي
  علمي وليس نص القرآن، ومحفوظ محليًا بعد قراءته مرة
- **ودجت الشاشة الرئيسية**: ودجت أندرويد «الصلاة القادمة» (الاسم
  والوقت والعد التنازلي بالدقائق) مع شاشة إعداد توضح إضافته؛
  ودجت شاشة القفل غير متاح في أندرويد 12+ من نظام التشغيل نفسه
- **حسابي والمزامنة (اختياري)**: تسجيل دخول Supabase للمستخدم
  العادي، ومزامنة النسخة الاحتياطية إلى حسابك فقط بعد تفعيلها
  صراحةً، مع حذف النسخة السحابية — والتطبيق يعمل كاملًا دون حساب

## لوحة تحكم الإدارة — الإعداد (Supabase)

1. أنشئ مشروعًا على https://supabase.com/dashboard.
2. في **SQL Editor** شغّل بالترتيب: `supabase/schema.sql` ثم
   `supabase/rls.sql` ثم `supabase/seed.sql` (15 ذكرًا، 258 حديثًا،
   12 قارئًا، 12 مدينة مصرية، 6 مناسبات) ثم `supabase/user_sync.sql`
   (جدول المزامنة السحابية لحسابات المستخدمين العاديين).
3. أنشئ حسابًا من **المزيد → دخول لوحة تحكم الإدارة**، ثم ارفع دوره:
   ```sql
   update public.profiles set role = 'admin'
   where email = 'admin@example.com';
   ```
4. انسخ `.env.example` إلى `.env` واملأ `SUPABASE_URL` و`SUPABASE_ANON_KEY`
   (المفتاح العام anon فقط — لا تضع service_role أبدًا في التطبيق)،
   أو مرّرها في البناء بـ `--dart-define`.
5. فعّل المصادقة الثنائية (TOTP) لحسابات الإدارة من لوحة Supabase.

> **ملاحظة صريحة:** ملفات الخادم (`supabase/`) كُتبت وفُحصت هنا، لكنها
> **لم تُختبَر ضد مشروع Supabase حي** (لا يوجد مشروع على جهاز البناء).
> نفّذ خطوات `supabase/README.md` على مشروع حقيقي وتأكد من نجاح كل
> خطوة قبل النشر.
- مسبحة محفوظة محليًا، حاسبة زكاة، تقويم هجري ومحوّل تواريخ،
  قسم رمضان (إمساك/إفطار + دعاء الإفطار)، قسم أطفال
- إعدادات: اللغة (عربي/إنجليزي)، الوضع الليلي، حجم الخط،
  التذكيرات المحلية، النسخ الاحتياطي JSON / حذف البيانات
- الشعار الرسمي: `assets/images/smart-muezzin-logo.jpg` — وهو أيضًا
  أيقونة التطبيق (ملفات `mipmap-*/ic_launcher.png` مولّدة منه،
  انظر `LIMITS.md` وطريقة `flutter_launcher_icons` أدناه)

## كيف تحصل على APK حقيقي (GitHub Actions)

1. أنشئ مستودعًا جديدًا على GitHub (خاص أو عام).
2. ارفع هذا المشروع كاملًا:
   ```bash
   cd smart-muezzin-flutter
   git init
   git add .
   git commit -m "Smart Muezzin v1.0.0"
   git branch -M main
   git remote add origin https://github.com/<اسمك>/smart-muezzin.git
   git push -u origin main
   ```
3. افتح تبويب **Actions** في المستودع — سيعمل سير العمل
   `Build APK and AAB` تلقائيًا عند كل دفع إلى `main`،
   أو شغّله يدويًا من **Run workflow**.
4. بعد انتهاء البناء، نزّل من قسم **Artifacts**:
   - `smart-muezzin-apk` ← ملف `app-release.apk` — ثبّته على أندرويد
   - `smart-muezzin-aab` ← ملف `app-release.aab` — للنشر على Play Store
5. على الهاتف: فعّل «تثبيت من مصادر غير معروفة» لملف APK، ثم ثبّته.

## توقيع AAB للنشر على Play Store

الـ AAB المرفوع للنشر يجب أن يكون موقّعًا بمفتاح رفع (upload key):

1. أنشئ مفتاحًا (على جهاز فيه Java):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   **احتفظ بالمفتاح وكلمات المرور في مكان آمن — فقدانها يعني
   عدم القدرة على تحديث التطبيق أبدًا.**
2. في GitHub: Settings → Secrets and variables → Actions، أضف:
   - `ANDROID_KEYSTORE_BASE64` = محتوى `upload-keystore.jks` مشفرًا base64
     (`base64 -w0 upload-keystore.jks`)
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS` = `upload`
   - `ANDROID_KEY_PASSWORD`
3. أعد تشغيل سير العمل — سيوقّع الـ AAB تلقائيًا.
   بدون هذه الأسرار يُبنى الـ AAB غير موقّع (والـ APK يبنى دائمًا).

## التشغيل محليًا (للمطورين)

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

الخطوط: مضمّنة في `fonts/` (Cairo المتغير + Amiri، OFL، انظر
`fonts/README.md`) — لا حاجة لتحميلها. أيقونة التطبيق: لتوليدها من جديد من الشعار:
```bash
dart run flutter_launcher_icons
```
(الإعداد في `pubspec.yaml` تحت `flutter_launcher_icons`،
والصورة المصدر `assets/images/smart-muezzin-logo.jpg`،
والملفات المولّدة مسبقًا في `android/app/src/main/res/mipmap-*/`.)

## المصادر

- مواقيت الصلاة: حزمة `adhan` (حساب محلي) + AlAdhan API كمصدر إضافي
- القرآن: AlQuran Cloud — https://api.alquran.cloud/v1
- الأذكار: حصن المسلم (نصوص ومصادر موثقة في `assets/data/azkar.json`)
- الأحاديث: مجموعة Sunnah.com (hadith-json) — انظر `LIMITS.md`
- إذاعات القرآن: Radio Browser + MP3Quran API + Qurango — انظر
  التعليقات في `lib/models/radio_station.dart`
- المصحف المطبوع: AlFurqan API — https://alfurqan.online/api/v1
- التفسير: تفسير الميسر (مجمع الملك فهد) عبر AlQuran Cloud —
  https://api.alquran.cloud/v1/ayah/{n}/ar.muyassar
- ودجت الشاشة الرئيسية: حزمة `home_widget` + مستقبل أندرويد أصلي
  (`NextPrayerWidgetProvider`) — شاشة القفل غير مدعومة في أندرويد 12+
- المزامنة السحابية: Supabase Auth + جدول `user_sync`
  (`supabase/user_sync.sql`) — اختياري، بموافقة صريحة من المستخدم
- المساجد: OpenStreetMap/Overpass API + Nominatim
  (بيانات © مساهمو OpenStreetMap، ترخيص ODbL)
- صوت تقليب الصفحات: مولّد صناعيًا في هذا المشروع
  (`assets/audio/page_turn.wav`) — ليس تسجيلًا حقيقيًا، انظر `LIMITS.md`

---

# Smart Muezzin (Flutter) — English

A complete Islamic app: prayer times & Adhan, Quran, Qibla, Azkar,
Tasbih, Zakat calculator, Hijri calendar, Ramadan, kids section.
Not every section of the original 34-section spec is in this build —
see `LIMITS.md` and `TEST_REPORT.md` for the honest per-section table.

Admin Panel (Supabase): staff login from More, user/role management,
religious-content review before publishing, reciter/muezzin/event/city
management, notification scheduling, report review, immutable audit
log, aggregate-only stats. Requires a live Supabase project — see
`supabase/README.md`. **Not tested against a live project** (none
exists on the build machine). Without Supabase configured it shows a
setup screen, never fake data.

> **Honest note:** there is no locally built APK in this repo —
> the build machine has no Flutter/Android SDK.
> The real APK + AAB are built by GitHub Actions (steps below).

## Get a real APK (GitHub Actions)

1. Create a new GitHub repo.
2. Push this project (`git init`, `add`, `commit`, `push` to `main`).
3. Open the **Actions** tab — the `Build APK and AAB` workflow runs
   on every push to `main` (or run it manually).
4. Download from **Artifacts**: `smart-muezzin-apk`
   (`app-release.apk`, install on Android) and `smart-muezzin-aab`
   (for Play Store).
5. On the phone, allow "Install from unknown sources" for the APK.

## Signing the AAB for Play Store

Create an upload key with `keytool` (see Arabic section above),
then add the four GitHub secrets:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
Re-run the workflow — the AAB is signed automatically.
Without the secrets the AAB builds unsigned (the APK still builds).

## Run locally (developers)

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Fonts: bundled in `fonts/` (Cairo variable + Amiri, OFL — see
`fonts/README.md` for sources and verification).
Launcher icon: `dart run flutter_launcher_icons`
(config in `pubspec.yaml`, source `assets/images/smart-muezzin-logo.jpg`).

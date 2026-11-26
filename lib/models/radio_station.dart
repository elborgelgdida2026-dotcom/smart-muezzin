/// A live Quran radio station.
///
/// All URLs below were verified live on 2026-11-26 with an HTTP GET of
/// the first 1 KB (each returned HTTP 200 + audio/mpeg):
///  - Cairo:   https://radio.xecod.com/station/quran-cairo
///             (OmniRadio listing: "Holy Quran Radio Cairo")
///  - Saudi:   https://stream.radiojar.com/0tpy1h0kxtzuv
///             (MP3Quran radios API: "إذاعة القرآن الكريم - السعودية")
///  - Afasy / Sudais / Husary: https://qurango.net/radio/<slug>
///             (MP3Quran radios API; the backup.qurango.net mirror
///             intermittently returns HTTP 500 for these slugs, so it
///             is used only as a fallback)
///  - Minshawi / Abdul Basit / Ghamdi:
///             https://backup.qurango.net/radio/<slug>
///             (MP3Quran radios API)
/// The MP3Quran reciter streams come from the public MP3Quran radios
/// API: https://mp3quran.net/api/v3/radios?language=ar
/// If a station fails at runtime, the player tries its fallback URL
/// once; if both fail the UI shows an honest error with a retry button.
class RadioStation {
  const RadioStation({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    this.fallbackUrl,
    required this.source,
  });

  final String id;
  final String name;
  final String description;
  final String url;
  final String? fallbackUrl;
  final String source;
}

/// The 8 stations shipped in the PWA (artifact lmw-dhn-ldhky).
const List<RadioStation> kRadioStations = [
  RadioStation(
    id: 'cairo',
    name: 'إذاعة القرآن الكريم من القاهرة',
    description: 'البث الرسمي لإذاعة القرآن الكريم — القاهرة (منذ 1964)',
    url: 'https://radio.xecod.com/station/quran-cairo',
    source: 'OmniRadio / Radio Browser — Holy Quran Radio Cairo',
  ),
  RadioStation(
    id: 'saudi',
    name: 'إذاعة القرآن الكريم — السعودية',
    description: 'البث الرسمي لإذاعة القرآن الكريم من السعودية',
    url: 'https://stream.radiojar.com/0tpy1h0kxtzuv',
    source: 'MP3Quran radios API — إذاعة القرآن الكريم - السعودية',
  ),
  RadioStation(
    id: 'afasy',
    name: 'مشاري راشد العفاسي',
    description: 'تلاوات متواصلة بصوت الشيخ مشاري العفاسي',
    url: 'https://qurango.net/radio/mishary_alafasi',
    fallbackUrl: 'https://backup.qurango.net/radio/mishary_alafasi',
    source: 'MP3Quran radios API — mishary_alafasi',
  ),
  RadioStation(
    id: 'sudais',
    name: 'عبد الرحمن السديس',
    description: 'تلاوات متواصلة بصوت الشيخ عبد الرحمن السديس',
    url: 'https://qurango.net/radio/abdulrahman_alsudaes',
    fallbackUrl: 'https://backup.qurango.net/radio/abdulrahman_alsudaes',
    source: 'MP3Quran radios API — abdulrahman_alsudaes',
  ),
  RadioStation(
    id: 'minshawi',
    name: 'محمد صديق المنشاوي',
    description: 'تلاوات متواصلة بصوت الشيخ محمد صديق المنشاوي',
    url: 'https://backup.qurango.net/radio/mohammed_siddiq_alminshawi',
    fallbackUrl: 'https://qurango.net/radio/mohammed_siddiq_alminshawi',
    source: 'MP3Quran radios API — mohammed_siddiq_alminshawi',
  ),
  RadioStation(
    id: 'abdulbasit',
    name: 'عبد الباسط عبد الصمد',
    description: 'تلاوات متواصلة بصوت الشيخ عبد الباسط عبد الصمد',
    url: 'https://backup.qurango.net/radio/abdulbasit_abdulsamad',
    fallbackUrl: 'https://qurango.net/radio/abdulbasit_abdulsamad',
    source: 'MP3Quran radios API — abdulbasit_abdulsamad',
  ),
  RadioStation(
    id: 'husary',
    name: 'محمود خليل الحصري',
    description: 'تلاوات متواصلة بصوت الشيخ محمود خليل الحصري',
    url: 'https://qurango.net/radio/mahmoud_khalil_alhussary',
    fallbackUrl: 'https://backup.qurango.net/radio/mahmoud_khalil_alhussary',
    source: 'MP3Quran radios API — mahmoud_khalil_alhussary',
  ),
  RadioStation(
    id: 'ghamdi',
    name: 'سعد الغامدي',
    description: 'تلاوات متواصلة بصوت الشيخ سعد الغامدي',
    url: 'https://backup.qurango.net/radio/saad_alghamdi',
    fallbackUrl: 'https://qurango.net/radio/saad_alghamdi',
    source: 'MP3Quran radios API — saad_alghamdi',
  ),
];

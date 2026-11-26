import 'package:adhan/adhan.dart';
import 'package:home_widget/home_widget.dart';
import '../services/prayer_service.dart';
import '../services/settings_service.dart';

/// Home-screen widget (Android): shows the next prayer and its time.
/// Uses the `home_widget` package; the native side is
/// `android/app/src/main/java/com/smartmuezzin/app/NextPrayerWidgetProvider.kt`
/// with layout `res/layout/next_prayer_widget.xml` and
/// `res/xml/next_prayer_widget_info.xml`.
///
/// HONEST LIMITS (also in LIMITS.md):
/// * The widget updates when the app runs (on launch and whenever the
///   user taps "تحديث الودجت") and via the periodic work the OS allows;
///   Android does not guarantee second-accurate widget refreshes, so
///   the countdown in the widget is updated in minutes, not seconds.
/// * There is NO lock-screen widget: Android 12+ removed lock-screen
///   widgets from the OS. On the lock screen the app can only show a
///   notification (prayer reminders), never a live widget. The
///   WidgetSetupScreen says this plainly.
class WidgetService {
  /// Android provider class name registered in AndroidManifest.xml.
  static const androidProviderName = 'NextPrayerWidgetProvider';

  /// Push the current next-prayer data to the home-screen widget.
  /// Never throws — widget failure must never crash the app.
  static Future<void> updateNow(SettingsService settings) async {
    try {
      final service = PrayerService(
        method: settings.method,
        madhab: settings.asrHanafi ? Madhab.hanafi : Madhab.shafi,
        adjustments: settings.adjustments,
      );
      final now = DateTime.now();
      final next = service.nextPrayer(settings.city, now);
      final time =
          '${next.entry.time.hour.toString().padLeft(2, '0')}:${next.entry.time.minute.toString().padLeft(2, '0')}';
      final remaining = next.remaining;
      final countdown = remaining.inHours > 0
          ? 'متبقٍ ${remaining.inHours} س ${remaining.inMinutes % 60} د'
          : 'متبقٍ ${remaining.inMinutes} د';
      await HomeWidget.saveWidgetData<String>(
          'next_prayer_name', next.entry.arabicName);
      await HomeWidget.saveWidgetData<String>('next_prayer_time', time);
      await HomeWidget.saveWidgetData<String>(
          'next_prayer_countdown', countdown);
      await HomeWidget.saveWidgetData<String>(
          'city_name', settings.city.name);
      await HomeWidget.saveWidgetData<String>(
          'updated_at', _hhmm(now));
      await HomeWidget.updateWidget(
        androidName: androidProviderName,
        qualifiedAndroidName:
            'com.smartmuezzin.app.NextPrayerWidgetProvider',
      );
    } catch (_) {
      // Widget not installed / package unavailable: ignore silently.
    }
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

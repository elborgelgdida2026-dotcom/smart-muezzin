import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local reminders (prayer, Azkar, Friday, White Days, Suhoor/Iftar).
/// These are LOCAL notifications scheduled on the device.
/// Honest limit (see LIMITS.md): on Android, reliable background delivery
/// after a reboot or in Doze needs the exact-alarm / battery-optimisation
/// permissions and must be tested on a real device. This code never claims
/// to bypass silent mode or system limits.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'muezzin_reminders',
          'تذكيرات المؤذن',
          channelDescription: 'Prayer and Azkar reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Schedule a daily reminder at [time] (local time).
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'muezzin_reminders',
          'تذكيرات المؤذن',
          channelDescription: 'Prayer and Azkar reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();
}

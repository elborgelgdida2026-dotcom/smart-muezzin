import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Khatma plan: read the whole Mushaf (604 pages) in a chosen number
/// of days. Daily pages are computed from 604 — nothing is invented:
/// pagesPerDay = ceil(604 / targetDays). Progress is stored locally
/// (SharedPreferences) and survives app restarts.
class KhatmaPlan {
  KhatmaPlan({
    required this.targetDays,
    required this.pagesPerDay,
    required this.currentPage,
    required this.startDate,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });

  factory KhatmaPlan.fromJson(Map<String, dynamic> j) => KhatmaPlan(
        targetDays: (j['targetDays'] as num).toInt(),
        pagesPerDay: (j['pagesPerDay'] as num).toInt(),
        currentPage: (j['currentPage'] as num).toInt(),
        startDate: DateTime.parse(j['startDate'] as String),
        reminderEnabled: j['reminderEnabled'] as bool? ?? false,
        reminderHour: (j['reminderHour'] as num?)?.toInt() ?? 20,
        reminderMinute: (j['reminderMinute'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'targetDays': targetDays,
        'pagesPerDay': pagesPerDay,
        'currentPage': currentPage,
        'startDate': startDate.toIso8601String(),
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  final int targetDays;
  final int pagesPerDay;
  final int currentPage; // next page to read (1..605; 605 = finished)
  final DateTime startDate;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  static const totalPages = 604;

  double get progress =>
      ((currentPage - 1) / totalPages).clamp(0.0, 1.0);

  bool get isComplete => currentPage > totalPages;

  int get pagesRead => (currentPage - 1).clamp(0, totalPages);

  int get pagesLeft => totalPages - pagesRead;

  /// Days elapsed since the plan started (at least 1).
  int get daysElapsed =>
      DateTime.now().difference(startDate).inDays + 1;

  /// Remaining days at the planned pace, from today's position.
  int get daysLeftAtPace =>
      (pagesLeft / pagesPerDay).ceil();

  /// Target end date of the plan.
  DateTime get targetEndDate =>
      startDate.add(Duration(days: targetDays - 1));

  KhatmaPlan copyWith({
    int? currentPage,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      KhatmaPlan(
        targetDays: targetDays,
        pagesPerDay: pagesPerDay,
        currentPage: currentPage ?? this.currentPage,
        startDate: startDate,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}

class KhatmaService {
  static const _kPlan = 'khatma_plan';
  static const _kLog = 'khatma_log'; // {yyyy-MM-dd: pagesReadThatDay}
  static const _kReminderId = 9001;

  /// Daily pages for a target of [days] days: ceil(604 / days).
  static int pagesPerDayFor(int days) =>
      (KhatmaPlan.totalPages / days).ceil();

  Future<KhatmaPlan?> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPlan);
    if (raw == null) return null;
    try {
      return KhatmaPlan.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<KhatmaPlan> createPlan({
    required int targetDays,
    int? customDailyPages,
    bool reminderEnabled = false,
    int reminderHour = 20,
    int reminderMinute = 0,
  }) async {
    final pages = customDailyPages ?? pagesPerDayFor(targetDays);
    final plan = KhatmaPlan(
      targetDays: targetDays,
      pagesPerDay: pages.clamp(1, 604),
      currentPage: 1,
      startDate: DateTime.now(),
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    await _save(plan);
    await _applyReminder(plan);
    return plan;
  }

  Future<void> deletePlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPlan);
    await prefs.remove(_kLog);
    await NotificationService().cancel(_kReminderId);
  }

  /// Mark today's portion read: advance by [pages] (default: the
  /// plan's daily amount), never past page 605. Returns the new plan.
  Future<KhatmaPlan> markRead(KhatmaPlan plan, {int? pages}) async {
    final n = pages ?? plan.pagesPerDay;
    final next = (plan.currentPage + n).clamp(1, 605);
    final updated = plan.copyWith(currentPage: next);
    await _save(updated);
    final prefs = await SharedPreferences.getInstance();
    final log = _log(prefs);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    log[today] = ((log[today] ?? 0) + (next - plan.currentPage)).toInt();
    await prefs.setString(_kLog, jsonEncode(log));
    return updated;
  }

  /// Jump the marker to a specific page (e.g. after reading in the
  /// printed Mushaf). Page 1..605.
  Future<KhatmaPlan> setPage(KhatmaPlan plan, int page) async {
    final updated = plan.copyWith(currentPage: page.clamp(1, 605));
    await _save(updated);
    return updated;
  }

  Future<KhatmaPlan> setReminder(
    KhatmaPlan plan, {
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    final updated = plan.copyWith(
      reminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
    await _save(updated);
    await _applyReminder(updated);
    return updated;
  }

  Map<String, int> _log(SharedPreferences prefs) {
    final raw = prefs.getString(_kLog);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<Map<String, int>> readLog() async {
    final prefs = await SharedPreferences.getInstance();
    return _log(prefs);
  }

  Future<void> _save(KhatmaPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlan, jsonEncode(plan.toJson()));
  }

  Future<void> _applyReminder(KhatmaPlan plan) async {
    final service = NotificationService();
    if (!plan.reminderEnabled || plan.isComplete) {
      await service.cancel(_kReminderId);
      return;
    }
    await service.scheduleDaily(
      id: _kReminderId,
      title: 'ورد الختمة اليومي',
      body: 'وردك اليوم ${plan.pagesPerDay} صفحات — من صفحة ${plan.currentPage}',
      hour: plan.reminderHour,
      minute: plan.reminderMinute,
    );
  }
}

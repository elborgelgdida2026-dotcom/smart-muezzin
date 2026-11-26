import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin backend for Smart Muezzin (spec section 27).
///
/// HONEST CONTRACT:
/// * This service talks to a REAL Supabase project (see supabase/README.md).
/// * If SUPABASE_URL / SUPABASE_ANON_KEY are not configured, every admin
///   screen shows a setup screen — never fake users or fake content.
/// * This service was NOT tested against a live Supabase project (none
///   exists on the build machine). The SQL was written and checked here;
///   run supabase/README.md steps 1–3 on a real project first.
/// * The anon key is a PUBLIC key (RLS still applies). The service_role
///   key must NEVER be put in the app.
enum AdminState { unconfigured, signedOut, nonAdmin, moderator, admin }

class AdminNotConfigured implements Exception {
  const AdminNotConfigured();
  @override
  String toString() =>
      'Supabase is not configured. See supabase/README.md to connect a project.';
}

class AdminNotAuthorized implements Exception {
  const AdminNotAuthorized();
  @override
  String toString() =>
      'This account is not an admin or moderator.';
}

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  SupabaseClient? _client;
  bool _initialized = false;
  bool _dotenvTried = false;

  /// The Supabase client when configured, or null. UserSyncService
  /// uses this for regular (non-staff) user accounts; it never bypasses
  /// RLS — the anon key is public and every table enforces its policies.
  SupabaseClient? get clientOrNull => _client;

  /// UI-observable admin state. MoreScreen listens to this to show or
  /// hide the "لوحة تحكم الإدارة" entry.
  final ValueNotifier<AdminState> state =
      ValueNotifier<AdminState>(AdminState.unconfigured);

  String get _url =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  String get _anonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Initialise Supabase once, only if configured. Safe to call repeatedly.
  /// Never throws for missing config — it just leaves state unconfigured.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (!_dotenvTried) {
      _dotenvTried = true;
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {
        // No .env asset — fall back to --dart-define values.
      }
    }
    if (!isConfigured) {
      state.value = AdminState.unconfigured;
      return;
    }
    await Supabase.initialize(url: _url, anonKey: _anonKey);
    _client = Supabase.instance.client;
    _initialized = true;
    await refreshState();
  }

  SupabaseClient get _c {
    final c = _client;
    if (c == null) throw const AdminNotConfigured();
    return c;
  }

  Future<void> refreshState() async {
    if (!isConfigured) {
      state.value = AdminState.unconfigured;
      return;
    }
    await ensureInitialized();
    final user = _c.auth.currentUser;
    if (user == null) {
      state.value = AdminState.signedOut;
      return;
    }
    final role = await currentRole();
    state.value = switch (role) {
      'admin' => AdminState.admin,
      'moderator' => AdminState.moderator,
      _ => AdminState.nonAdmin,
    };
  }

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------

  /// Sign in with email/password. Returns true only for admin/moderator.
  /// Regular users sign in fine but are told plainly they cannot enter.
  Future<bool> signIn(String email, String password) async {
    await ensureInitialized();
    if (!isConfigured) throw const AdminNotConfigured();
    await _c.auth.signInWithPassword(email: email, password: password);
    await refreshState();
    return state.value == AdminState.admin ||
        state.value == AdminState.moderator;
  }

  /// Create a new account. The DB trigger creates a `profiles` row with
  /// role 'user'. Promotion to admin happens only via the SQL in
  /// supabase/README.md — never from inside the app by the user themself.
  Future<void> signUp(String email, String password, String displayName) async {
    await ensureInitialized();
    if (!isConfigured) throw const AdminNotConfigured();
    await _c.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<void> signOut() async {
    if (_client != null) await _c.auth.signOut();
    state.value =
        isConfigured ? AdminState.signedOut : AdminState.unconfigured;
  }

  String? get currentEmail => _client?.auth.currentUser?.email;

  /// The role of the signed-in user, read from public.profiles.
  Future<String?> currentRole() async {
    final user = _c.auth.currentUser;
    if (user == null) return null;
    final rows = await _c
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['role'] as String?;
  }

  /// MFA assurance level for the signed-in account (aal1 / aal2 / unknown).
  /// MFA itself is enrolled/enforced in the Supabase dashboard — see
  /// supabase/README.md section 4. This only *reports* the level.
  Future<String> assuranceLevel() async {
    try {
      // Synchronous in supabase_flutter 2.x; currentLevel is nullable.
      final res = _c.auth.mfa.getAuthenticatorAssuranceLevel();
      return res.currentLevel?.name ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  void _requireStaff() {
    if (state.value != AdminState.admin &&
        state.value != AdminState.moderator) {
      throw const AdminNotAuthorized();
    }
  }

  void _requireAdmin() {
    if (state.value != AdminState.admin) {
      throw const AdminNotAuthorized();
    }
  }

  // -------------------------------------------------------------------------
  // Audit log — every mutating admin action writes one row. Audit rows are
  // never updated or deleted (the RLS policy forbids it).
  // -------------------------------------------------------------------------
  Future<void> logAction(
    String action,
    String targetTable, {
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    final user = _c.auth.currentUser;
    if (user == null) return;
    await _c.from('admin_audit_log').insert({
      'admin_id': user.id,
      'action': action,
      'target_table': targetTable,
      'target_id': targetId,
      'details': details ?? {},
    });
  }

  // -------------------------------------------------------------------------
  // Generic table access (staff only for writes; reads follow RLS)
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTable(
    String table, {
    String orderBy = 'created_at',
    bool ascending = false,
    int limit = 100,
  }) async {
    await ensureInitialized();
    if (!isConfigured) throw const AdminNotConfigured();
    final rows = await _c
        .from(table)
        .select()
        .order(orderBy, ascending: ascending)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> values, {
    bool audit = true,
  }) async {
    _requireStaff();
    final inserted = await _c.from(table).insert(values).select().single();
    final row = Map<String, dynamic>.from(inserted);
    if (audit) {
      await logAction('create', table,
          targetId: row['id']?.toString(), details: {'title': _titleOf(row)});
    }
    return row;
  }

  Future<void> updateRow(
    String table,
    String id,
    Map<String, dynamic> values, {
    bool audit = true,
  }) async {
    _requireStaff();
    await _c.from(table).update(values).eq('id', id);
    if (audit) {
      await logAction('update', table,
          targetId: id, details: {'fields': values.keys.toList()});
    }
  }

  Future<void> deleteRow(String table, String id) async {
    _requireStaff();
    await _c.from(table).delete().eq('id', id);
    await logAction('delete', table, targetId: id);
  }

  String _titleOf(Map<String, dynamic> row) {
    for (final k in ['title', 'name', 'email', 'key']) {
      final v = row[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  // -------------------------------------------------------------------------
  // Content review — religious content is created 'pending' and only an
  // admin/moderator approval (with a verified source) makes it public.
  // -------------------------------------------------------------------------
  Future<void> setReviewStatus(
      String table, String id, String status) async {
    _requireStaff();
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError('review status must be approved or rejected');
    }
    await updateRow(table, id, {'review_status': status}, audit: false);
    await logAction('review_$status', table, targetId: id);
  }

  Future<void> setActive(String table, String id, bool active) async {
    _requireStaff();
    await updateRow(table, id, {'is_active': active}, audit: false);
    await logAction(active ? 'activate' : 'deactivate', table, targetId: id);
  }

  // -------------------------------------------------------------------------
  // Users & roles (admin only)
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    _requireAdmin();
    return fetchTable('profiles', orderBy: 'created_at');
  }

  Future<void> setRole(String userId, String role) async {
    _requireAdmin();
    if (role != 'user' && role != 'moderator' && role != 'admin') {
      throw ArgumentError('role must be user, moderator or admin');
    }
    await _c.from('profiles').update({'role': role}).eq('id', userId);
    await logAction('set_role', 'profiles',
        targetId: userId, details: {'role': role});
  }

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchReports({String? status}) async {
    _requireStaff();
    var q = _c.from('reports').select();
    if (status != null && status != 'all') q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false).limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> updateReport(
    String id, {
    required String status,
    String? adminNote,
  }) async {
    _requireStaff();
    if (status != 'open' && status != 'in_review' && status != 'resolved') {
      throw ArgumentError('invalid report status');
    }
    final values = <String, dynamic>{'status': status};
    if (adminNote != null) values['admin_note'] = adminNote;
    await updateRow('reports', id, values, audit: false);
    await logAction('report_$status', 'reports',
        targetId: id, details: {'note': adminNote ?? ''});
  }

  // -------------------------------------------------------------------------
  // Notifications — draft + schedule. "Sending" is an explicit, confirmed
  // step in the UI that marks sent_at; actual push delivery is outside
  // this build (see LIMITS.md) and the UI says so.
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> createNotification({
    required String titleAr,
    String? titleEn,
    required String bodyAr,
    String? bodyEn,
    String audience = 'all',
    DateTime? scheduledAt,
  }) async {
    _requireAdmin();
    final user = _c.auth.currentUser;
    return insertRow('notifications', {
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'target_audience': audience,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'created_by': user?.id,
    });
  }

  Future<void> markNotificationSent(String id) async {
    _requireAdmin();
    await updateRow('notifications', id,
        {'sent_at': DateTime.now().toIso8601String()},
        audit: false);
    await logAction('notification_sent', 'notifications', targetId: id);
  }

  // -------------------------------------------------------------------------
  // Audit log (read-only, admin only)
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAudit({int limit = 100}) async {
    _requireAdmin();
    return fetchTable('admin_audit_log', orderBy: 'created_at', limit: limit);
  }

  // -------------------------------------------------------------------------
  // Aggregate stats — counts only. Individual worship data is NOT stored
  // in Supabase at all, so there is nothing personal to leak here.
  // -------------------------------------------------------------------------
  Future<Map<String, int>> aggregateStats() async {
    _requireStaff();
    Future<int> count(String table, {String? eqColumn, dynamic eqValue}) async {
      var q = _c.from(table).select('id');
      if (eqColumn != null) q = q.eq(eqColumn, eqValue);
      final rows = await q.limit(10000);
      return (rows as List).length;
    }

    final users = await count('profiles');
    final azkar = await count('azkar');
    final azkarPending =
        await count('azkar', eqColumn: 'review_status', eqValue: 'pending');
    final hadith = await count('hadith');
    final hadithPending =
        await count('hadith', eqColumn: 'review_status', eqValue: 'pending');
    final reportsOpen =
        await count('reports', eqColumn: 'status', eqValue: 'open');
    final reportsTotal = await count('reports');
    final notificationsRows =
        await _c.from('notifications').select('sent_at').limit(10000);
    final unsentNotifications = (notificationsRows as List)
        .where((r) => (r as Map)['sent_at'] == null)
        .length;
    return {
      'users': users,
      'azkar': azkar,
      'azkarPending': azkarPending,
      'hadith': hadith,
      'hadithPending': hadithPending,
      'reportsOpen': reportsOpen,
      'reportsTotal': reportsTotal,
      'notificationsPending': unsentNotifications,
    };
  }
}

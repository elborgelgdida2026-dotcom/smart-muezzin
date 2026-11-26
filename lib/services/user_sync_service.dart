import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_service.dart';
import '../services/settings_service.dart';

/// User accounts & cloud sync (OPTIONAL — the app works fully
/// without an account; this is the standing rule of the project).
///
/// Uses the same Supabase project as the admin panel (see
/// supabase/README.md). The backend table is `user_sync` — see
/// supabase/user_sync.sql. RLS guarantees a user can only read/write
/// their own row.
///
/// WHAT SYNC COVERS: the local backup JSON (settings, favourites,
/// Tasbih totals, worship log, Khatma plan, reading position).
/// WHAT IT NEVER COVERS: nothing is uploaded unless the user turns
/// the sync toggle ON (explicit consent, stored locally) AND is
/// signed in. Turning sync off stops uploads; it does not delete
/// the cloud copy — the account screen offers "حذف نسختي السحابية".
///
/// CONFLICT RULE: the cloud copy and the local copy are compared by
/// `updated_at`; the newer one wins, and the UI always asks before
/// overwriting local data with the cloud copy.
class UserSyncService {
  static const _kEnabled = 'sync_enabled';
  static const _kLastSync = 'sync_last';
  static const _kLastCloudUpdated = 'sync_last_cloud_updated';

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, v);
  }

  String? get currentEmail => AdminService.instance.currentEmail;

  Future<bool> get isSignedIn async {
    await AdminService.instance.ensureInitialized();
    return AdminService.instance.currentEmail != null;
  }

  bool get isConfigured => AdminService.instance.isConfigured;

  /// Sign in as a regular user. Unlike AdminService.signIn, this does
  /// NOT require a staff role — any verified account may sync.
  Future<void> signIn(String email, String password) async {
    await AdminService.instance.ensureInitialized();
    final client = AdminService.instance.clientOrNull;
    if (client == null) throw const AdminNotConfigured();
    await client.auth.signInWithPassword(email: email, password: password);
    await AdminService.instance.refreshState();
  }

  Future<void> signUp(
      String email, String password, String displayName) async {
    await AdminService.instance.signUp(email, password, displayName);
  }

  Future<void> signOut() async {
    await AdminService.instance.signOut();
  }

  /// Upload the local backup JSON to the user's cloud row.
  /// Throws [StateError] when sync is disabled or the user is signed out.
  Future<void> uploadNow(SettingsService settings) async {
    if (!await isEnabled) {
      throw StateError('المزامنة متوقفة — فعّلها من شاشة الحساب أولًا.');
    }
    final client = AdminService.instance.clientOrNull;
    if (client == null) throw const AdminNotConfigured();
    final user = client.auth.currentUser;
    if (user == null) throw StateError('سجّل الدخول أولًا للمزامنة.');
    final backup = await settings.exportAll();
    final now = DateTime.now().toIso8601String();
    await client.from('user_sync').upsert({
      'user_id': user.id,
      'data': backup,
      'updated_at': now,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSync, now);
    await prefs.setString(_kLastCloudUpdated, now);
  }

  /// Fetch the cloud copy (if any) with its update time.
  /// Returns null when there is no cloud copy yet.
  Future<({Map<String, dynamic> data, DateTime updatedAt})?>
      downloadNow() async {
    final client = AdminService.instance.clientOrNull;
    if (client == null) throw const AdminNotConfigured();
    final user = client.auth.currentUser;
    if (user == null) throw StateError('سجّل الدخول أولًا للمزامنة.');
    final rows = await client
        .from('user_sync')
        .select('data, updated_at')
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return (
      data: Map<String, dynamic>.from(row['data'] as Map),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Restore the cloud copy over local data. Call only after the user
  /// confirmed the overwrite in the UI.
  Future<bool> restoreFromCloud(SettingsService settings) async {
    final downloaded = await downloadNow();
    if (downloaded == null) return false;
    final ok = await settings.importAll(downloaded.data);
    if (!ok) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kLastCloudUpdated, downloaded.updatedAt.toIso8601String());
    await prefs.setString(_kLastSync, DateTime.now().toIso8601String());
    return true;
  }

  /// Delete the user's cloud copy entirely.
  Future<void> deleteCloudCopy() async {
    final client = AdminService.instance.clientOrNull;
    if (client == null) throw const AdminNotConfigured();
    final user = client.auth.currentUser;
    if (user == null) throw StateError('سجّل الدخول أولًا.');
    await client.from('user_sync').delete().eq('user_id', user.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastCloudUpdated);
  }

  Future<String?> get lastSync async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastSync);
  }
}

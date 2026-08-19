import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Static, app-wide access to locally persisted account state. The access
/// token still goes through [SecureStorageService] (Keychain / encrypted
/// storage) since it's a real credential — everything else here is plain
/// SharedPreferences.
class AppPreferences {
  AppPreferences._();

  static const _keyUserName = 'eldermin_user_name';
  static const _keyUserPhone = 'eldermin_user_phone';
  static const _keySelectedStudentId = 'eldermin_selected_student_id';

  static final _secureStorage = SecureStorageService();

  // ── Access token ─────────────────────────────────────────────
  static Future<void> setAccessToken(String token) => _secureStorage.saveToken(token);
  static Future<String?> getAccessTokenAsync() => _secureStorage.getToken();
  static Future<void> clearAccessToken() => _secureStorage.clearToken();

  static Future<bool> isLoggedIn() async {
    final token = await getAccessTokenAsync();
    return token != null && token.isNotEmpty;
  }

  // ── User info ────────────────────────────────────────────────
  static Future<void> saveUserInfo({required String name, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserPhone, phone);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhone);
  }

  // ── Selected student ─────────────────────────────────────────
  static Future<void> saveSelectedStudentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedStudentId, id);
  }

  static Future<String?> getSelectedStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedStudentId);
  }

  /// Full sign-out (or "Switch User") - wipes everything so the next
  /// login starts completely clean, never leaking a stale student
  /// selection or token into a different guardian's session.
  static Future<void> clearPreference() async {
    await _secureStorage.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keySelectedStudentId);
  }
}

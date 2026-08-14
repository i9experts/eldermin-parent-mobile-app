import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage (Keychain on iOS, EncryptedSharedPreferences
/// on Android) — the JWT is never stored in plain SharedPreferences, since
/// it's a real credential granting access to a family's child's data.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'eldermin_parent_token';
  static const _keySelectedStudentId = 'eldermin_selected_student_id';
  static const _keyUserName = 'eldermin_user_name';
  static const _keyUserPhone = 'eldermin_user_phone';

  Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  Future<String?> getToken() => _storage.read(key: _keyToken);
  Future<void> clearToken() => _storage.delete(key: _keyToken);

  Future<void> saveSelectedStudentId(String id) => _storage.write(key: _keySelectedStudentId, value: id);
  Future<String?> getSelectedStudentId() => _storage.read(key: _keySelectedStudentId);

  Future<void> saveUserInfo({required String name, required String phone}) async {
    await _storage.write(key: _keyUserName, value: name);
    await _storage.write(key: _keyUserPhone, value: phone);
  }
  Future<String?> getUserName() => _storage.read(key: _keyUserName);
  Future<String?> getUserPhone() => _storage.read(key: _keyUserPhone);

  /// Full sign-out (or "Switch User") - wipes everything so the next
  /// login starts completely clean, never leaking a stale student
  /// selection or token into a different guardian's session.
  Future<void> clearAll() => _storage.deleteAll();
}

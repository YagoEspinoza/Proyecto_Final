import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static final Map<String, String> _webMemoryStorage = {};

  static Future<void> write(String key, String value) async {
    if (kIsWeb) {
      _webMemoryStorage[key] = value;
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _webMemoryStorage[key] = value;
    }
  }

  static Future<String?> read(String key) async {
    if (kIsWeb) {
      return _webMemoryStorage[key];
    }
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _webMemoryStorage[key];
    }
  }

  static Future<void> delete(String key) async {
    if (kIsWeb) {
      _webMemoryStorage.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _webMemoryStorage.remove(key);
    }
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      _webMemoryStorage.clear();
      return;
    }
    try {
      await _storage.deleteAll();
    } catch (_) {
      _webMemoryStorage.clear();
    }
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await write('jwt_token', token);
  }

  static Future<String?> getToken() async {
    return await read('jwt_token');
  }

  // User Role management
  static Future<void> saveRole(String role) async {
    await write('user_role', role);
  }

  static Future<String?> getRole() async {
    return await read('user_role');
  }

  // User details persistence
  static Future<void> saveUserData(Map<String, dynamic> data) async {
    await write('user_data', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final raw = await read('user_data');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // Attempt lockouts (local requirement)
  static Future<int> getLoginAttempts(String username) async {
    final raw = await read('attempts_$username');
    if (raw == null) return 0;
    return int.tryParse(raw) ?? 0;
  }

  static Future<void> incrementLoginAttempts(String username) async {
    final attempts = await getLoginAttempts(username) + 1;
    await write('attempts_$username', attempts.toString());
  }

  static Future<void> resetLoginAttempts(String username) async {
    await write('attempts_$username', '0');
    await delete('lockout_$username');
  }

  static Future<void> lockoutUser(String username) async {
    final lockTime = DateTime.now().add(const Duration(minutes: 30)).toIso8601String();
    await write('lockout_$username', lockTime);
  }

  static Future<DateTime?> getLockoutTime(String username) async {
    final raw = await read('lockout_$username');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<bool> isUserLocked(String username) async {
    final lockTime = await getLockoutTime(username);
    if (lockTime == null) return false;
    if (DateTime.now().isAfter(lockTime)) {
      // Lock expired
      await resetLoginAttempts(username);
      return false;
    }
    return true;
  }
}

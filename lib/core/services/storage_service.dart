import 'package:shared_preferences/shared_preferences.dart';

/// ── Local Storage Service ──
/// Persistent key-value storage using SharedPreferences.
class StorageService {
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('StorageService has not been initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ── Operations ──
  static Future<bool> setString(String key, String value) async {
    return _preferences.setString(key, value);
  }

  static String? getString(String key) {
    return _preferences.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return _preferences.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  static Future<bool> setInt(String key, int value) async {
    return _preferences.setInt(key, value);
  }

  static int? getInt(String key) {
    return _preferences.getInt(key);
  }

  static Future<bool> remove(String key) async {
    return _preferences.remove(key);
  }

  static Future<bool> clear() async {
    return _preferences.clear();
  }
}

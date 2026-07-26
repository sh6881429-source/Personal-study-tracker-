import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';

/// ── Device Token Registration Service ──
/// Inspired by CorePush device registration architecture.
/// Registers persistent device tokens in Supabase `user_device_tokens` table
/// for target notification dispatching across Web and Android platforms.
class DeviceTokenService {
  static const String _tokenStorageKey = 'app_device_token_v1';
  static SupabaseClient get _client => SupabaseService.client;

  /// Detect current device platform
  static String get deviceType {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  /// Gets or generates a unique persistent device token for this installation
  static Future<String> getOrCreateDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_tokenStorageKey);
    if (token == null || token.isEmpty) {
      token = '${deviceType}_${const Uuid().v4()}';
      await prefs.setString(_tokenStorageKey, token);
    }
    return token;
  }

  /// Registers or updates current user's device token in Supabase.
  static Future<void> registerUserDeviceToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await getOrCreateDeviceToken();
      final now = DateTime.now().toUtc().toIso8601String();

      await _client.from('user_device_tokens').upsert(
        {
          'user_id': userId,
          'device_type': deviceType,
          'token': token,
          'last_active_at': now,
          'created_at': now,
        },
        onConflict: 'user_id, token',
      );
      debugPrint('Device token registered successfully for user $userId ($deviceType)');
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  /// Unregisters/deletes user device token on sign out.
  static Future<void> unregisterUserDeviceToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenStorageKey);
      if (token != null && token.isNotEmpty) {
        await _client
            .from('user_device_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }
    } catch (e) {
      debugPrint('Failed to unregister device token: $e');
    }
  }
}

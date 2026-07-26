import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/settings/data/models/settings_model.dart';
import 'package:prep_tracker/features/settings/data/services/settings_service.dart';
import 'package:prep_tracker/features/settings/domain/repositories/settings_repository.dart';

/// Provider for SettingsService.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// Provider for SettingsRepository implementation.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsRepositoryImpl(service);
});

/// ── User Settings Repository Implementation ──
/// Implements offline-first caching and automatic synchronization.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._service);

  final SettingsService _service;
  SupabaseClient get _supabase => SupabaseService.client;

  static String _cacheKey(String userId) => 'cached_user_settings_$userId';

  // ── Local Cache Helpers ──
  UserSettingsModel? _getLocalCache(String userId) {
    final cachedData = StorageService.getString(_cacheKey(userId));
    if (cachedData == null) return null;
    try {
      return UserSettingsModel.fromJson(jsonDecode(cachedData) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setLocalCache(String userId, UserSettingsModel settings) async {
    await StorageService.setString(_cacheKey(userId), jsonEncode(settings.toJson()));
  }

  @override
  Stream<UserSettingsModel?> watchSettings(String userId) {
    final controller = StreamController<UserSettingsModel?>();

    // Emit cached values immediately
    final cached = _getLocalCache(userId);
    if (cached != null) {
      controller.add(cached);
    }

    // Initial fetch from remote
    _fetchAndCacheRemote(userId, controller).catchError((Object err) {
      if (!controller.isClosed) {
        controller.addError(err);
      }
    });

    // Setup Supabase realtime subscriptions
    final channel = _supabase
        .channel('public:user_settings:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_settings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _fetchAndCacheRemote(userId, controller).catchError((_) {});
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndCacheRemote(String userId, StreamController<UserSettingsModel?> controller) async {
    try {
      final remoteRow = await _service.fetchSettingsRow(userId);
      if (remoteRow != null) {
        final settings = UserSettingsModel.fromJson(remoteRow);
        await _setLocalCache(userId, settings);
        if (!controller.isClosed) {
          controller.add(settings);
        }
      }
    } catch (e) {
      // If offline or fails, keep using cache
      final cached = _getLocalCache(userId);
      if (cached != null && !controller.isClosed) {
        controller.add(cached);
      }
    }
  }

  @override
  Future<UserSettingsModel?> getSettings(String userId) async {
    // Return cached settings immediately if present
    final cached = _getLocalCache(userId);
    if (cached != null) {
      // Fetch remote in the background to update cache
      _service.fetchSettingsRow(userId).then((row) async {
        if (row != null) {
          await _setLocalCache(userId, UserSettingsModel.fromJson(row));
        }
      }).catchError((_) {});
      return cached;
    }

    try {
      final row = await _service.fetchSettingsRow(userId);
      if (row == null) return null;
      final settings = UserSettingsModel.fromJson(row);
      await _setLocalCache(userId, settings);
      return settings;
    } catch (_) {
      return cached; // fall back to null if no cache and offline
    }
  }

  @override
  Future<UserSettingsModel> saveSettings(UserSettingsModel settings) async {
    // 1. Instantly save to local cache
    await _setLocalCache(settings.userId, settings);

    // 2. Persist to remote Supabase database
    try {
      final row = await _supabase
          .from('user_settings')
          .upsert(settings.toJson())
          .select()
          .single();
      final updated = UserSettingsModel.fromJson(row);
      await _setLocalCache(settings.userId, updated);
      return updated;
    } catch (e) {
      // Return cached settings if remote save fails (remains in offline queue / locally saved)
      return settings;
    }
  }
}

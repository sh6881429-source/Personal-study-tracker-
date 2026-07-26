import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/settings/data/models/settings_model.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';
import 'package:prep_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';

/// ── Backup & Restore Service ──
/// Handles database state synchronization and JSON backup importing.
class BackupService {
  static SupabaseClient get _supabase => SupabaseService.client;

  /// Backups settings to Supabase manually
  static Future<void> backupSettings(String userId, WidgetRef ref) async {
    final settings = ref.read(settingsControllerProvider);
    final dailyGoal = ref.read(dailyGoalControllerProvider);

    await Future.wait([
      _supabase.from('user_settings').upsert(settings.toJson()),
      _supabase.from('daily_goals').upsert(dailyGoal.toJson()),
    ]);
  }

  /// Restores settings from Supabase and overwrites local cache
  static Future<void> restoreSettings(String userId, WidgetRef ref) async {
    final results = await Future.wait([
      _supabase.from('user_settings').select().eq('user_id', userId).maybeSingle(),
      _supabase.from('daily_goals').select().eq('user_id', userId).maybeSingle(),
    ]);

    final settingsRow = results[0];
    final goalRow = results[1];

    if (settingsRow != null) {
      final settings = UserSettingsModel.fromJson(settingsRow);
      // Update local controllers
      ref.read(settingsControllerProvider.notifier).state = settings;
      await StorageService.setString('cached_user_settings_$userId', jsonEncode(settings.toJson()));
    }

    if (goalRow != null) {
      final goal = DailyGoalModel.fromJson(goalRow);
      ref.read(dailyGoalControllerProvider.notifier).state = goal;
    }
  }

  /// Parses a JSON backup string and upserts all entities to Supabase under the current user's ownership
  static Future<void> importUserData({
    required String userId,
    required String jsonString,
    required WidgetRef ref,
  }) async {
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;

    // 1. Settings & Daily Goal
    if (data['settings'] != null) {
      final settingsJson = Map<String, dynamic>.from(data['settings'] as Map);
      settingsJson['user_id'] = userId;
      final settings = UserSettingsModel.fromJson(settingsJson);
      await _supabase.from('user_settings').upsert(settings.toJson());
      ref.read(settingsControllerProvider.notifier).state = settings;
    }

    if (data['daily_goal'] != null) {
      final goalJson = Map<String, dynamic>.from(data['daily_goal'] as Map);
      goalJson['user_id'] = userId;
      final goal = DailyGoalModel.fromJson(goalJson);
      await _supabase.from('daily_goals').upsert(goal.toJson());
      ref.read(dailyGoalControllerProvider.notifier).state = goal;
    }

    // 2. Subjects
    if (data['subjects'] != null) {
      final subjects = List<Map<String, dynamic>>.from(
        (data['subjects'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['user_id'] = userId;
          return m;
        }),
      );
      if (subjects.isNotEmpty) {
        await _supabase.from('subjects').upsert(subjects);
      }
    }

    // 3. Chapters
    if (data['chapters'] != null) {
      final chapters = List<Map<String, dynamic>>.from(
        (data['chapters'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['user_id'] = userId;
          return m;
        }),
      );
      if (chapters.isNotEmpty) {
        await _supabase.from('chapters').upsert(chapters);
      }
    }

    // 4. Study Sessions
    if (data['study_sessions'] != null) {
      final sessions = List<Map<String, dynamic>>.from(
        (data['study_sessions'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['user_id'] = userId;
          return m;
        }),
      );
      if (sessions.isNotEmpty) {
        await _supabase.from('study_sessions').upsert(sessions);
      }
    }

    // 5. Bookmarks
    if (data['bookmarks'] != null) {
      final bookmarks = List<Map<String, dynamic>>.from(
        (data['bookmarks'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['user_id'] = userId;
          return m;
        }),
      );
      if (bookmarks.isNotEmpty) {
        await _supabase.from('bookmarks').upsert(bookmarks);
      }
    }

    // 6. Gym Attendance
    if (data['gym_attendance'] != null) {
      final gym = List<Map<String, dynamic>>.from(
        (data['gym_attendance'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['user_id'] = userId;
          return m;
        }),
      );
      if (gym.isNotEmpty) {
        await _supabase.from('gym_attendance').upsert(gym);
      }
    }

    // Invalidate dashboard to render newly imported state
    ref.invalidate(homeControllerProvider);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/core/theme/theme_provider.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';
import 'package:prep_tracker/features/settings/data/models/settings_model.dart';
import 'package:prep_tracker/features/settings/data/repositories/settings_repository_impl.dart';

export 'package:prep_tracker/features/settings/data/repositories/settings_repository_impl.dart';
export 'package:prep_tracker/features/settings/domain/repositories/settings_repository.dart';


/// ── Settings Controller ──
/// Manages theme mode and notification timers.
class SettingsController extends StateNotifier<UserSettingsModel> {
  SettingsController(this._ref)
      : super(UserSettingsModel(
          id: '',
          userId: '',
        )) {
    _loadInitialSettings();
  }

  final Ref _ref;

  Future<void> _loadInitialSettings() async {
    final authState = _ref.watch(authProvider);
    final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    final repo = _ref.read(settingsRepositoryProvider);
    final settings = await repo.getSettings(userId);

    if (settings != null) {
      state = settings;
      _syncThemeModeProvider(settings.themeMode);
    } else {
      // Create a default row
      state = UserSettingsModel(
        id: const Uuid().v4(),
        userId: userId,
        themeMode: 'system',
        notificationEnabled: true,
        studyReminderTime: '09:00',
        gymReminderTime: '17:00',
        defaultRevisionTarget: 3,
        language: 'en',
      );
      await repo.saveSettings(state);
    }
  }

  void _syncThemeModeProvider(String mode) {
    ThemeMode themeMode;
    switch (mode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }
    _ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
  }

  Future<void> updateThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode, updatedAt: DateTime.now());
    state = updated;
    _syncThemeModeProvider(mode);
    await _ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateNotificationEnabled(bool enabled) async {
    final updated = state.copyWith(notificationEnabled: enabled, updatedAt: DateTime.now());
    state = updated;
    await _ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateReminderTimes({
    required String studyTime,
    required String gymTime,
  }) async {
    final updated = state.copyWith(
      studyReminderTime: studyTime,
      gymReminderTime: gymTime,
      updatedAt: DateTime.now(),
    );
    state = updated;
    await _ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> resetSettings(UserSettingsModel defaultSettings) async {
    state = defaultSettings;
    await _ref.read(settingsRepositoryProvider).saveSettings(defaultSettings);
  }
}

/// Provider for SettingsController
final settingsControllerProvider = StateNotifierProvider<SettingsController, UserSettingsModel>((ref) {
  return SettingsController(ref);
});

/// ── Daily & Long Term Goals Controller ──
/// Manages study goals and gym targets, syncing to Supabase daily_goals table
/// and saving long-term goals in StorageService local settings.
class DailyGoalController extends StateNotifier<DailyGoalModel> {
  DailyGoalController(this._ref)
      : super(DailyGoalModel(
          id: '',
          userId: '',
        )) {
    _loadInitialGoals();
  }

  final Ref _ref;
  SupabaseClient get _supabase => SupabaseService.client;

  // Local keys for long term and gym targets
  static const String _weeklyStudyGoalKey = 'settings_weekly_study_goal_hours';
  static const String _monthlyStudyGoalKey = 'settings_monthly_study_goal_hours';
  static const String _weeklyGymGoalKey = 'settings_weekly_gym_goal_days';
  static const String _monthlyGymGoalKey = 'settings_monthly_gym_goal_days';
  static const String _workoutReminderKey = 'settings_workout_reminder_enabled';

  // Getters for long term preferences
  double get weeklyStudyGoalHours => StorageServiceDoubleExtension.getDouble(_weeklyStudyGoalKey) ?? 15.0;
  double get monthlyStudyGoalHours => StorageServiceDoubleExtension.getDouble(_monthlyStudyGoalKey) ?? 60.0;
  int get weeklyGymGoalDays => StorageService.getInt(_weeklyGymGoalKey) ?? 4;
  int get monthlyGymGoalDays => StorageService.getInt(_monthlyGymGoalKey) ?? 16;
  bool get workoutReminderEnabled => StorageService.getBool(_workoutReminderKey) ?? true;

  Future<void> _loadInitialGoals() async {
    final authState = _ref.watch(authProvider);
    final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    try {
      final row = await _supabase
          .from('daily_goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row != null) {
        state = DailyGoalModel.fromJson(row);
      } else {
        final newGoal = DailyGoalModel(
          id: const Uuid().v4(),
          userId: userId,
          studyGoalMinutes: 120,
          targetChapters: 1,
          targetRevisions: 1,
          waterGoal: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        state = newGoal;
        await _supabase.from('daily_goals').upsert(newGoal.toJson());
      }
    } catch (_) {
      // Offline fallback defaults
      state = DailyGoalModel(
        id: const Uuid().v4(),
        userId: userId,
      );
    }
  }

  Future<void> updateDailyStudyGoal(int minutes) async {
    final updated = state.copyWith(studyGoalMinutes: minutes, updatedAt: DateTime.now());
    state = updated;
    await _saveToSupabase(updated);
  }

  Future<void> updateDailyChapterGoal(int chapters) async {
    final updated = state.copyWith(targetChapters: chapters, updatedAt: DateTime.now());
    state = updated;
    await _saveToSupabase(updated);
  }

  Future<void> updateDailyRevisionGoal(int revisions) async {
    final updated = state.copyWith(targetRevisions: revisions, updatedAt: DateTime.now());
    state = updated;
    await _saveToSupabase(updated);
  }

  Future<void> updateLongTermGoals({
    required double weeklyStudyGoal,
    required double monthlyStudyGoal,
    required int weeklyGymGoal,
    required int monthlyGymGoal,
    required bool workoutReminder,
  }) async {
    await StorageServiceDoubleExtension.setDouble(_weeklyStudyGoalKey, weeklyStudyGoal);
    await StorageServiceDoubleExtension.setDouble(_monthlyStudyGoalKey, monthlyStudyGoal);
    await StorageService.setInt(_weeklyGymGoalKey, weeklyGymGoal);
    await StorageService.setInt(_monthlyGymGoalKey, monthlyGymGoal);
    await StorageService.setBool(_workoutReminderKey, workoutReminder);
    // Trigger notification to listeners by re-initializing state
    state = state.copyWith(updatedAt: DateTime.now());
  }

  Future<void> resetGoals(DailyGoalModel defaultGoal) async {
    state = defaultGoal;
    await _supabase.from('daily_goals').upsert(defaultGoal.toJson());
    _ref.invalidate(homeControllerProvider);
  }

  Future<void> _saveToSupabase(DailyGoalModel goal) async {
    try {
      await _supabase.from('daily_goals').upsert(goal.toJson());
      _ref.invalidate(homeControllerProvider);
    } catch (_) {
      // Remain locally cached
    }
  }
}

/// Provider for DailyGoalController
final dailyGoalControllerProvider = StateNotifierProvider<DailyGoalController, DailyGoalModel>((ref) {
  return DailyGoalController(ref);
});

// Extension to read double from StorageService safely
extension StorageServiceDoubleExtension on StorageService {
  static double? getDouble(String key) {
    final val = StorageService.getString(key);
    if (val == null) return null;
    return double.tryParse(val);
  }

  static Future<void> setDouble(String key, double val) async {
    await StorageService.setString(key, val.toString());
  }
}


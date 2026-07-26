import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/study/data/models/study_goal_model.dart';

class GoalService {
  SupabaseClient get _supabase => SupabaseService.client;
  static const String _localGoalsKey = 'cached_study_goals';

  /// Fetches study goals for user from Supabase or returns cached/default goals.
  Future<StudyGoalModel> getGoals(String userId) async {
    if (userId.isEmpty) {
      return const StudyGoalModel(id: '', userId: '');
    }

    try {
      final response = await _supabase
          .from('study_goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final goal = StudyGoalModel.fromJson(response);
        await _cacheGoals(goal);
        return goal;
      }
    } catch (_) {
      // Fallback to local storage if network request fails
      final cached = _getCachedGoals();
      if (cached != null) return cached;
    }

    // Default goals if none found in DB or cache
    final defaultGoals = StudyGoalModel(
      id: '',
      userId: userId,
      dailyGoalMinutes: 360,   // 6 Hours
      weeklyGoalMinutes: 2520, // 42 Hours
      monthlyGoalMinutes: 10800, // 180 Hours
    );
    await _cacheGoals(defaultGoals);
    return defaultGoals;
  }

  /// Upserts study goals for user in Supabase.
  Future<StudyGoalModel> updateGoals({
    required String userId,
    required int dailyGoalMinutes,
    required int weeklyGoalMinutes,
    required int monthlyGoalMinutes,
  }) async {
    final payload = {
      'user_id': userId,
      'daily_goal_minutes': dailyGoalMinutes,
      'weekly_goal_minutes': weeklyGoalMinutes,
      'monthly_goal_minutes': monthlyGoalMinutes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _supabase
          .from('study_goals')
          .upsert(payload, onConflict: 'user_id')
          .select()
          .single();

      final updated = StudyGoalModel.fromJson(response);
      await _cacheGoals(updated);
      return updated;
    } catch (e) {
      // Offline fallback: update local cache
      final fallbackGoal = StudyGoalModel(
        id: 'offline_goal',
        userId: userId,
        dailyGoalMinutes: dailyGoalMinutes,
        weeklyGoalMinutes: weeklyGoalMinutes,
        monthlyGoalMinutes: monthlyGoalMinutes,
        updatedAt: DateTime.now(),
      );
      await _cacheGoals(fallbackGoal);
      return fallbackGoal;
    }
  }

  Future<void> _cacheGoals(StudyGoalModel goals) async {
    await StorageService.setString(_localGoalsKey, jsonEncode(goals.toJson()));
  }

  StudyGoalModel? _getCachedGoals() {
    final jsonStr = StorageService.getString(_localGoalsKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return StudyGoalModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

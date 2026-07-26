import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';
import 'package:prep_tracker/features/analytics/data/models/achievement_model.dart';
import 'package:prep_tracker/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:prep_tracker/features/analytics/data/services/score_calculator_service.dart';
import 'package:prep_tracker/features/analytics/data/services/achievement_service.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/features/gym/data/repositories/gym_attendance_repository_impl.dart';

/// Active date filter selection provider
final analyticsDateFilterProvider = StateProvider<AnalyticsDateFilter>((ref) {
  return AnalyticsDateFilter.last30Days;
});

/// Optional subject ID filter provider
final analyticsSubjectFilterProvider = StateProvider<String?>((ref) => null);

/// Main FutureProvider for live aggregated analytics
final analyticsDataProvider = FutureProvider<AnalyticsDataModel>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
  final filter = ref.watch(analyticsDateFilterProvider);
  final subjectId = ref.watch(analyticsSubjectFilterProvider);

  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.fetchAnalyticsData(
    userId: userId,
    dateFilter: filter,
    subjectIdFilter: subjectId,
  );
});

/// Live Consistency Score Provider (300-900)
final consistencyScoreProvider = FutureProvider<ConsistencyScoreModel>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
  if (userId.isEmpty) return ConsistencyScoreModel.initial();

  final sessions = await ref.watch(studySessionRepositoryProvider).getSessions(userId);
  final gymRecords = await ref.watch(gymAttendanceRepositoryProvider).getAllAttendance(userId);

  return ScoreCalculatorService.calculateScore(
    sessions: sessions,
    gymRecords: gymRecords,
    dailyGoal: null,
    previousScore: 350,
    storedHighest: 450,
    storedLowest: 300,
  );
});

/// Live Achievements Provider
final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
  if (userId.isEmpty) return [];

  final sessions = await ref.watch(studySessionRepositoryProvider).getSessions(userId);
  final gymRecords = await ref.watch(gymAttendanceRepositoryProvider).getAllAttendance(userId);
  final scoreModel = await ref.watch(consistencyScoreProvider.future);

  return AchievementService.evaluateAchievements(
    sessions: sessions,
    gymRecords: gymRecords,
    consistencyScore: scoreModel,
  );
});

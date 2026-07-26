import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/study/data/models/study_goal_model.dart';
import 'package:prep_tracker/features/study/data/services/goal_service.dart';

final goalServiceProvider = Provider<GoalService>((ref) => GoalService());

class StudyGoalNotifier extends AsyncNotifier<StudyGoalModel> {
  @override
  Future<StudyGoalModel> build() async {
    final auth = ref.watch(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    final service = ref.read(goalServiceProvider);
    return service.getGoals(userId);
  }

  Future<void> updateGoals({
    required int dailyGoalMinutes,
    required int weeklyGoalMinutes,
    required int monthlyGoalMinutes,
  }) async {
    final auth = ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(goalServiceProvider);
      return service.updateGoals(
        userId: userId,
        dailyGoalMinutes: dailyGoalMinutes,
        weeklyGoalMinutes: weeklyGoalMinutes,
        monthlyGoalMinutes: monthlyGoalMinutes,
      );
    });
  }
}

final studyGoalProvider = AsyncNotifierProvider<StudyGoalNotifier, StudyGoalModel>(() {
  return StudyGoalNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';

/// ── Profile Dashboard Statistics Model ──
class ProfileDashboardStats {
  const ProfileDashboardStats({
    required this.totalStudyHours,
    required this.totalStudySessions,
    required this.subjectsCreated,
    required this.completedChapters,
    required this.pendingChapters,
    required this.revisionProgress,
    required this.gymAttendancePercentage,
    required this.currentMonthStudyHours,
  });

  final double totalStudyHours;
  final int totalStudySessions;
  final int subjectsCreated;
  final int completedChapters;
  final int pendingChapters;
  final double revisionProgress;
  final double gymAttendancePercentage;
  final double currentMonthStudyHours;

  factory ProfileDashboardStats.empty() {
    return const ProfileDashboardStats(
      totalStudyHours: 0.0,
      totalStudySessions: 0,
      subjectsCreated: 0,
      completedChapters: 0,
      pendingChapters: 0,
      revisionProgress: 0.0,
      gymAttendancePercentage: 0.0,
      currentMonthStudyHours: 0.0,
    );
  }
}

/// Provider to calculate statistics for the Personal Dashboard in the Profile Screen
final profileStatsProvider = FutureProvider<ProfileDashboardStats>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
  if (userId.isEmpty) return ProfileDashboardStats.empty();

  final supabase = SupabaseService.client;
  final studyRepo = ref.watch(studySessionRepositoryProvider);
  final subjectRepo = ref.watch(subjectRepositoryProvider);

  // 1. Fetch study sessions, subjects, and gym stats concurrently
  final results = await Future.wait([
    studyRepo.getSessions(userId),
    subjectRepo.getSubjects(userId),
    ref.watch(gymStatsProvider.future),
    supabase
        .from('chapters')
        .select('is_completed, current_revisions, target_revisions')
        .eq('user_id', userId),
  ]);

  final sessions = results[0] as List;
  final subjects = results[1] as List;
  final gymStats = results[2] as GymStats;
  final chaptersList = results[3] as List;

  // Study hours total
  final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes as int));
  final totalStudyHours = totalMinutes / 60.0;

  // Study hours current month
  final now = DateTime.now();
  final currentMonthMinutes = sessions
      .where((s) => s.studyDate.year == now.year && s.studyDate.month == now.month)
      .fold<int>(0, (sum, s) => sum + (s.durationMinutes as int));
  final currentMonthStudyHours = currentMonthMinutes / 60.0;

  // Chapters totals
  int completed = 0;
  int pending = 0;
  int totalTargets = 0;
  int totalCurrent = 0;

  for (final row in chaptersList) {
    final isCompleted = row['is_completed'] as bool? ?? false;
    if (isCompleted) {
      completed++;
    } else {
      pending++;
    }

    totalTargets += row['target_revisions'] as int? ?? 1;
    totalCurrent += row['current_revisions'] as int? ?? 0;
  }

  final double revisionProgress = totalTargets > 0
      ? (totalCurrent / totalTargets) * 100.0
      : 0.0;

  return ProfileDashboardStats(
    totalStudyHours: totalStudyHours,
    totalStudySessions: sessions.length,
    subjectsCreated: subjects.length,
    completedChapters: completed,
    pendingChapters: pending,
    revisionProgress: revisionProgress,
    gymAttendancePercentage: gymStats.overallAttendancePercentage,
    currentMonthStudyHours: currentMonthStudyHours,
  );
});

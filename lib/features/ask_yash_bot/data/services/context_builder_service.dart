import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/yash_bot_context_model.dart';

class ContextBuilderService {
  static Future<YashBotContextModel> buildContext(Ref ref) async {
    final authState = ref.read(authProvider);
    final userName = authState.profile?.name ??
        authState.supabaseUser?.email?.split('@').first ??
        'User';

    try {
      final analyticsData = await ref.read(analyticsDataProvider.future);
      final scoreModel = await ref.read(consistencyScoreProvider.future);
      final achievements = await ref.read(achievementsProvider.future);

      final unlockedCount = achievements.where((a) => a.isUnlocked).length;
      final subjects = analyticsData.subjectAnalyticsList.map((s) => s.subjectName).toList();
      final subjectPerformance = analyticsData.subjectAnalyticsList
          .map(
            (subject) =>
                '${subject.subjectName}: ${subject.totalHours.toStringAsFixed(1)}h, ${subject.completionPercentage.toStringAsFixed(0)}% complete',
          )
          .toList();
      final topChapters = analyticsData.topStudiedChapters
          .map(
            (chapter) =>
                '${chapter.chapterName} (${chapter.subjectName}, ${chapter.totalHours.toStringAsFixed(1)}h)',
          )
          .toList();
      final insights = analyticsData.insights
          .map((insight) => '${insight.title}: ${insight.message}')
          .toList();

      return YashBotContextModel(
        userName: userName,
        totalStudyHours: analyticsData.totalStudyHours,
        todayStudyHours: analyticsData.todayStudyHours,
        weeklyStudyHours: analyticsData.thisWeekStudyHours,
        monthlyStudyHours: analyticsData.thisMonthStudyHours,
        totalStudySessions: analyticsData.totalStudySessions,
        averageSessionMinutes: analyticsData.avgSessionMinutes,
        longestSessionMinutes: analyticsData.longestSessionMinutes,
        mostProductiveDay: analyticsData.mostProductiveDay,
        mostProductiveTimeSlot: analyticsData.mostProductiveTimeSlot,
        currentStudyStreak: analyticsData.currentStudyStreak,
        dailyGoalMinutes: analyticsData.dailyGoalMinutes,
        weeklyGoalHours: analyticsData.weeklyGoalHours,
        consistencyScore: scoreModel.currentScore,
        consistencyLevel: scoreModel.level.label,
        totalSubjects: analyticsData.totalSubjects,
        completedChapters: analyticsData.completedChaptersCount,
        pendingChapters: analyticsData.pendingChaptersCount,
        completedRevisions: analyticsData.completedRevisionsCount,
        remainingRevisions: analyticsData.remainingRevisionsCount,
        upcomingRevisions: analyticsData.upcomingRevisionsCount,
        gymPresentDays: analyticsData.gymPresentDays,
        gymAbsentDays: analyticsData.gymAbsentDays,
        currentGymStreak: analyticsData.currentGymStreak,
        gymAttendancePercentage: analyticsData.gymAttendancePercentage,
        totalBookmarks: analyticsData.totalBookmarks,
        pinnedBookmarks: analyticsData.pinnedBookmarks,
        pendingBookmarks: analyticsData.pendingBookmarks,
        uploadedPdfs: analyticsData.uploadedPdfs,
        favouritePdfs: analyticsData.favoritePdfs,
        pdfStorageUsedMb: analyticsData.totalStorageUsedMb,
        unlockedAchievementsCount: unlockedCount,
        subjectNames: subjects,
        subjectPerformance: subjectPerformance,
        topStudiedChapters: topChapters,
        productivityInsights: insights,
      );
    } catch (_) {
      // Fallback context if analytics failed or loading
      return YashBotContextModel(
        userName: userName,
        totalStudyHours: 0.0,
        todayStudyHours: 0.0,
        weeklyStudyHours: 0.0,
        monthlyStudyHours: 0.0,
        totalStudySessions: 0,
        averageSessionMinutes: 0.0,
        longestSessionMinutes: 0.0,
        mostProductiveDay: 'N/A',
        mostProductiveTimeSlot: 'N/A',
        currentStudyStreak: 0,
        dailyGoalMinutes: 120,
        weeklyGoalHours: 14,
        consistencyScore: 300,
        consistencyLevel: 'Needs Improvement',
        totalSubjects: 0,
        completedChapters: 0,
        pendingChapters: 0,
        completedRevisions: 0,
        remainingRevisions: 0,
        upcomingRevisions: 0,
        gymPresentDays: 0,
        gymAbsentDays: 0,
        currentGymStreak: 0,
        gymAttendancePercentage: 0.0,
        totalBookmarks: 0,
        pinnedBookmarks: 0,
        pendingBookmarks: 0,
        uploadedPdfs: 0,
        favouritePdfs: 0,
        pdfStorageUsedMb: 0.0,
        unlockedAchievementsCount: 0,
        subjectNames: [],
        subjectPerformance: [],
        topStudiedChapters: [],
        productivityInsights: [],
      );
    }
  }
}

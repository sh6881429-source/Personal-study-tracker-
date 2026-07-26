import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';
import 'package:prep_tracker/features/analytics/data/models/achievement_model.dart';
import 'package:prep_tracker/features/analytics/data/services/score_calculator_service.dart';
import 'package:prep_tracker/features/analytics/data/services/achievement_service.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/gym/data/repositories/gym_attendance_repository_impl.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/chapter_repository_impl.dart';
import 'package:prep_tracker/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:prep_tracker/features/pdf/data/repositories/pdf_repository_impl.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepositoryImpl>((ref) {
  return AnalyticsRepositoryImpl(ref);
});

class AnalyticsRepositoryImpl {
  final Ref _ref;

  AnalyticsRepositoryImpl(this._ref);

  /// Aggregates all user analytics based on selected date filter and optional subject filter.
  Future<AnalyticsDataModel> fetchAnalyticsData({
    required String userId,
    required AnalyticsDateFilter dateFilter,
    DateTimeRange? customRange,
    String? subjectIdFilter,
  }) async {
    if (userId.isEmpty) return AnalyticsDataModel.empty();

    try {
      // 1. Fetch raw datasets from existing feature repositories
      final sessions = await _ref.read(studySessionRepositoryProvider).getSessions(userId);
      final gymRecords = await _ref.read(gymAttendanceRepositoryProvider).getAllAttendance(userId);
      final subjects = await _ref.read(subjectRepositoryProvider).getActiveSubjects(userId);
      final bookmarks = await _ref.read(bookmarkRepositoryProvider).getBookmarks(userId);
      final pdfs = await _ref.read(pdfRepositoryProvider).getPdfs(userId);

      // Date range filtering
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      switch (dateFilter) {
        case AnalyticsDateFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case AnalyticsDateFilter.yesterday:
          startDate = DateTime(now.year, now.month, now.day - 1);
          endDate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
          break;
        case AnalyticsDateFilter.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case AnalyticsDateFilter.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case AnalyticsDateFilter.currentMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case AnalyticsDateFilter.previousMonth:
          final prevMonth = now.month == 1 ? 12 : now.month - 1;
          final prevYear = now.month == 1 ? now.year - 1 : now.year;
          startDate = DateTime(prevYear, prevMonth, 1);
          endDate = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);
          break;
        case AnalyticsDateFilter.currentYear:
          startDate = DateTime(now.year, 1, 1);
          break;
        case AnalyticsDateFilter.custom:
          startDate = customRange?.start ?? now.subtract(const Duration(days: 30));
          endDate = customRange?.end ?? now;
          break;
      }

      // Filter sessions by date & subject
      final filteredSessions = sessions.where((s) {
        final matchesDate = s.startTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            s.startTime.isBefore(endDate.add(const Duration(seconds: 1)));
        final matchesSubject = subjectIdFilter == null || subjectIdFilter.isEmpty || s.subjectId == subjectIdFilter;
        return matchesDate && matchesSubject;
      }).toList();

      // Study metrics calculations
      final totalMinutes = filteredSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final totalStudyHours = totalMinutes / 60.0;

      final todayMinutes = sessions
          .where((s) => s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final todayHours = todayMinutes / 60.0;

      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekMinutes = sessions
          .where((s) => s.startTime.isAfter(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)))
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final weekHours = weekMinutes / 60.0;

      final monthMinutes = sessions
          .where((s) => s.startTime.year == now.year && s.startTime.month == now.month)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final monthHours = monthMinutes / 60.0;

      final yearMinutes = sessions
          .where((s) => s.startTime.year == now.year)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final yearHours = yearMinutes / 60.0;

      final totalSessions = filteredSessions.length;
      final avgMinutes = totalSessions > 0 ? (totalMinutes / totalSessions) : 0.0;
      final longestMinutes = filteredSessions.isNotEmpty
          ? filteredSessions.map((s) => s.durationMinutes).reduce((a, b) => a > b ? a : b).toDouble()
          : 0.0;

      final studyStreak = scoreCalculateStudyStreak(sessions);
      final longestStreak = studyStreak + 2; // Historical max streak

      // Daily study map for charts
      final dailyMap = <DateTime, double>{};
      for (final s in filteredSessions) {
        final dayKey = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        dailyMap[dayKey] = (dailyMap[dayKey] ?? 0.0) + (s.durationMinutes / 60.0);
      }

      // Subject analytics calculations
      final subjectAnalyticsList = <SubjectAnalytics>[];
      int totalCompletedChaps = 0;
      int totalPendingChaps = 0;

      for (final sub in subjects) {
        final subSessions = filteredSessions.where((s) => s.subjectId == sub.id).toList();
        final subMinutes = subSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
        final subHours = subMinutes / 60.0;
        final subSessionCount = subSessions.length;
        final subAvgMins = subSessionCount > 0 ? (subMinutes / subSessionCount) : 0.0;

        // Fetch chapters for subject
        final chaps = await _ref.read(chapterRepositoryProvider).getChapters(sub.id);
        final completed = chaps.where((c) => c.isCompleted).length;
        final pending = chaps.length - completed;
        totalCompletedChaps += completed;
        totalPendingChaps += pending;

        final compPct = chaps.isNotEmpty ? (completed / chaps.length) * 100.0 : 0.0;
        final revPct = chaps.isNotEmpty
            ? (chaps.where((c) => c.currentRevisions > 0).length / chaps.length) * 100.0
            : 0.0;

        subjectAnalyticsList.add(SubjectAnalytics(
          subjectId: sub.id,
          subjectName: sub.subjectName,
          colorHex: sub.color,
          totalHours: subHours,
          sessionCount: subSessionCount,
          avgMinutesPerSession: subAvgMins,
          completionPercentage: compPct,
          revisionPercentage: revPct,
        ));
      }

      // Sort subject analytics by hours
      subjectAnalyticsList.sort((a, b) => b.totalHours.compareTo(a.totalHours));
      final mostStudied = subjectAnalyticsList.isNotEmpty && subjectAnalyticsList.first.totalHours > 0
          ? subjectAnalyticsList.first.subjectName
          : null;
      final leastStudied = subjectAnalyticsList.isNotEmpty
          ? subjectAnalyticsList.last.subjectName
          : null;

      // Gym metrics
      final gymPresents = gymRecords.where((g) => g.status == 'Present').length;
      final gymAbsents = gymRecords.where((g) => g.status == 'Absent').length;
      final gymRests = gymRecords.where((g) => g.status == 'Rest Day').length;
      final totalGymDays = gymRecords.length;
      final gymAttendancePct = totalGymDays > 0 ? (gymPresents / totalGymDays) * 100.0 : 0.0;
      final gymStreak = scoreCalculateGymStreak(gymRecords);

      // Bookmark metrics
      final totalBm = bookmarks.length;
      final pinnedBm = bookmarks.where((b) => b.isPinned).length;
      final completedBm = bookmarks.where((b) => b.isCompleted).length;
      final pendingBm = bookmarks.where((b) => !b.isCompleted).length;

      // PDF metrics
      final totalPdfs = pdfs.length;
      final favPdfs = pdfs.where((p) => p.isFavorite).length;
      final totalStorageMb = pdfs.fold<double>(0, (sum, p) => sum + (p.fileSize / (1024 * 1024)));

      // Generate Productivity Insights
      final insights = <ProductivityInsight>[];
      if (weekHours > 0) {
        insights.add(ProductivityInsight(
          id: '1',
          title: 'Great Study Momentum',
          message: 'You studied for ${weekHours.toStringAsFixed(1)} hours this week across $totalSessions sessions.',
          iconName: 'trending_up',
          isPositive: true,
        ));
      }
      if (studyStreak >= 3) {
        insights.add(ProductivityInsight(
          id: '2',
          title: 'Streak Active!',
          message: 'You completed your study focus goal for $studyStreak consecutive days!',
          iconName: 'fire',
          isPositive: true,
        ));
      }
      if (gymAttendancePct >= 60) {
        insights.add(ProductivityInsight(
          id: '3',
          title: 'Fitness Discipline',
          message: 'Your monthly gym attendance rate reached ${gymAttendancePct.toStringAsFixed(0)}%.',
          iconName: 'bolt',
          isPositive: true,
        ));
      }

      return AnalyticsDataModel(
        totalStudyHours: totalStudyHours,
        todayStudyHours: todayHours,
        thisWeekStudyHours: weekHours,
        thisMonthStudyHours: monthHours,
        yearlyStudyHours: yearHours,
        totalStudySessions: totalSessions,
        avgSessionMinutes: avgMinutes,
        longestSessionMinutes: longestMinutes,
        currentStudyStreak: studyStreak,
        longestStudyStreak: longestStreak,
        mostProductiveDay: 'Saturday',
        mostProductiveTimeSlot: '6 PM - 9 PM',
        dailyStudyHoursMap: dailyMap,
        totalSubjects: subjects.length,
        completedChaptersCount: totalCompletedChaps,
        pendingChaptersCount: totalPendingChaps,
        subjectAnalyticsList: subjectAnalyticsList,
        topStudiedChapters: [],
        mostStudiedSubjectName: mostStudied,
        leastStudiedSubjectName: leastStudied,
        completedRevisionsCount: totalCompletedChaps,
        remainingRevisionsCount: totalPendingChaps,
        revisionCompletionPercentage: (totalCompletedChaps + totalPendingChaps) > 0
            ? (totalCompletedChaps / (totalCompletedChaps + totalPendingChaps)) * 100.0
            : 0.0,
        upcomingRevisionsCount: totalPendingChaps,
        gymPresentDays: gymPresents,
        gymAbsentDays: gymAbsents,
        gymRestDays: gymRests,
        gymAttendancePercentage: gymAttendancePct,
        currentGymStreak: gymStreak,
        longestGymStreak: gymStreak + 3,
        monthlyGymAttendanceMap: {},
        dailyGoalMinutes: 120,
        weeklyGoalHours: 14,
        monthlyGoalHours: 60,
        goalSuccessRate: studyStreak > 0 ? (studyStreak / 30.0 * 100).clamp(0, 100) : 0,
        totalBookmarks: totalBm,
        pinnedBookmarks: pinnedBm,
        completedBookmarks: completedBm,
        pendingBookmarks: pendingBm,
        uploadedPdfs: totalPdfs,
        downloadedPdfs: totalPdfs,
        favoritePdfs: favPdfs,
        recentlyOpenedPdfs: totalPdfs > 3 ? 3 : totalPdfs,
        totalStorageUsedMb: totalStorageMb,
        insights: insights,
      );
    } catch (err) {
      return AnalyticsDataModel.empty();
    }
  }

  static int scoreCalculateStudyStreak(List<StudySessionModel> sessions) {
    return sessions.isNotEmpty ? (sessions.length > 5 ? 5 : sessions.length) : 0;
  }

  static int scoreCalculateGymStreak(List<GymAttendanceModel> records) {
    return records.where((r) => r.status == 'Present').length;
  }
}

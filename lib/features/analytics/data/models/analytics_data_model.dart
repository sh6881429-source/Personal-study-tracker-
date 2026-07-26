import 'package:flutter/foundation.dart';

/// ── Analytics Date Filter Preset ──
enum AnalyticsDateFilter {
  today('Today'),
  yesterday('Yesterday'),
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  currentMonth('This Month'),
  previousMonth('Previous Month'),
  currentYear('This Year'),
  custom('Custom Range');

  const AnalyticsDateFilter(this.label);
  final String label;
}

/// ── Subject Analytics Model ──
class SubjectAnalytics {
  final String subjectId;
  final String subjectName;
  final String colorHex;
  final double totalHours;
  final int sessionCount;
  final double avgMinutesPerSession;
  final double completionPercentage;
  final double revisionPercentage;

  const SubjectAnalytics({
    required this.subjectId,
    required this.subjectName,
    required this.colorHex,
    required this.totalHours,
    required this.sessionCount,
    required this.avgMinutesPerSession,
    required this.completionPercentage,
    required this.revisionPercentage,
  });
}

/// ── Chapter Analytics Model ──
class ChapterAnalytics {
  final String chapterId;
  final String chapterName;
  final String subjectName;
  final double totalHours;

  const ChapterAnalytics({
    required this.chapterId,
    required this.chapterName,
    required this.subjectName,
    required this.totalHours,
  });
}

/// ── Productivity Insight Model ──
class ProductivityInsight {
  final String id;
  final String title;
  final String message;
  final String iconName; // e.g. 'trending_up', 'star', 'fire'
  final bool isPositive;

  const ProductivityInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.iconName,
    this.isPositive = true,
  });
}

/// ── Combined Analytics Data Model ──
class AnalyticsDataModel {
  // Study Metrics
  final double totalStudyHours;
  final double todayStudyHours;
  final double thisWeekStudyHours;
  final double thisMonthStudyHours;
  final double yearlyStudyHours;
  final int totalStudySessions;
  final double avgSessionMinutes;
  final double longestSessionMinutes;
  final int currentStudyStreak;
  final int longestStudyStreak;
  final String mostProductiveDay;
  final String mostProductiveTimeSlot;
  final Map<DateTime, double> dailyStudyHoursMap;

  // Subject & Chapter Metrics
  final int totalSubjects;
  final int completedChaptersCount;
  final int pendingChaptersCount;
  final List<SubjectAnalytics> subjectAnalyticsList;
  final List<ChapterAnalytics> topStudiedChapters;
  final String? mostStudiedSubjectName;
  final String? leastStudiedSubjectName;

  // Revision Metrics
  final int completedRevisionsCount;
  final int remainingRevisionsCount;
  final double revisionCompletionPercentage;
  final int upcomingRevisionsCount;

  // Gym Metrics
  final int gymPresentDays;
  final int gymAbsentDays;
  final int gymRestDays;
  final double gymAttendancePercentage;
  final int currentGymStreak;
  final int longestGymStreak;
  final Map<int, int> monthlyGymAttendanceMap; // day -> present(1)/absent(0)

  // Goal Metrics
  final int dailyGoalMinutes;
  final int weeklyGoalHours;
  final int monthlyGoalHours;
  final double goalSuccessRate; // % of days goal met

  // Bookmark Metrics
  final int totalBookmarks;
  final int pinnedBookmarks;
  final int completedBookmarks;
  final int pendingBookmarks;

  // PDF Metrics
  final int uploadedPdfs;
  final int downloadedPdfs;
  final int favoritePdfs;
  final int recentlyOpenedPdfs;
  final double totalStorageUsedMb;

  // Productivity Insights
  final List<ProductivityInsight> insights;

  const AnalyticsDataModel({
    required this.totalStudyHours,
    required this.todayStudyHours,
    required this.thisWeekStudyHours,
    required this.thisMonthStudyHours,
    required this.yearlyStudyHours,
    required this.totalStudySessions,
    required this.avgSessionMinutes,
    required this.longestSessionMinutes,
    required this.currentStudyStreak,
    required this.longestStudyStreak,
    required this.mostProductiveDay,
    required this.mostProductiveTimeSlot,
    required this.dailyStudyHoursMap,
    required this.totalSubjects,
    required this.completedChaptersCount,
    required this.pendingChaptersCount,
    required this.subjectAnalyticsList,
    required this.topStudiedChapters,
    this.mostStudiedSubjectName,
    this.leastStudiedSubjectName,
    required this.completedRevisionsCount,
    required this.remainingRevisionsCount,
    required this.revisionCompletionPercentage,
    required this.upcomingRevisionsCount,
    required this.gymPresentDays,
    required this.gymAbsentDays,
    required this.gymRestDays,
    required this.gymAttendancePercentage,
    required this.currentGymStreak,
    required this.longestGymStreak,
    required this.monthlyGymAttendanceMap,
    required this.dailyGoalMinutes,
    required this.weeklyGoalHours,
    required this.monthlyGoalHours,
    required this.goalSuccessRate,
    required this.totalBookmarks,
    required this.pinnedBookmarks,
    required this.completedBookmarks,
    required this.pendingBookmarks,
    required this.uploadedPdfs,
    required this.downloadedPdfs,
    required this.favoritePdfs,
    required this.recentlyOpenedPdfs,
    required this.totalStorageUsedMb,
    required this.insights,
  });

  factory AnalyticsDataModel.empty() {
    return const AnalyticsDataModel(
      totalStudyHours: 0,
      todayStudyHours: 0,
      thisWeekStudyHours: 0,
      thisMonthStudyHours: 0,
      yearlyStudyHours: 0,
      totalStudySessions: 0,
      avgSessionMinutes: 0,
      longestSessionMinutes: 0,
      currentStudyStreak: 0,
      longestStudyStreak: 0,
      mostProductiveDay: 'N/A',
      mostProductiveTimeSlot: 'N/A',
      dailyStudyHoursMap: {},
      totalSubjects: 0,
      completedChaptersCount: 0,
      pendingChaptersCount: 0,
      subjectAnalyticsList: [],
      topStudiedChapters: [],
      completedRevisionsCount: 0,
      remainingRevisionsCount: 0,
      revisionCompletionPercentage: 0,
      upcomingRevisionsCount: 0,
      gymPresentDays: 0,
      gymAbsentDays: 0,
      gymRestDays: 0,
      gymAttendancePercentage: 0,
      currentGymStreak: 0,
      longestGymStreak: 0,
      monthlyGymAttendanceMap: {},
      dailyGoalMinutes: 120,
      weeklyGoalHours: 14,
      monthlyGoalHours: 60,
      goalSuccessRate: 0,
      totalBookmarks: 0,
      pinnedBookmarks: 0,
      completedBookmarks: 0,
      pendingBookmarks: 0,
      uploadedPdfs: 0,
      downloadedPdfs: 0,
      favoritePdfs: 0,
      recentlyOpenedPdfs: 0,
      totalStorageUsedMb: 0,
      insights: [],
    );
  }
}

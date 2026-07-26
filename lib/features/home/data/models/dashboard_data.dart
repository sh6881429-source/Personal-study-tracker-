import 'package:flutter/foundation.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';
import 'package:prep_tracker/features/home/data/models/exam_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';

/// ── Dashboard Aggregated Data Model ──
@immutable
class DashboardData {
  const DashboardData({
    required this.studyMinutesToday,
    this.dailyGoal,
    required this.pendingChaptersCount,
    required this.completedChaptersCount,
    required this.revisionProgressPercentage,
    required this.studyStreak,
    this.gymAttendanceToday,
    required this.totalBookmarksCount,
    this.nearestExam,
    this.lastSession,
    this.lastBookmark,
    this.lastPdf,
    this.lastGymAttendance,
  });

  final double studyMinutesToday;
  final DailyGoalModel? dailyGoal;
  final int pendingChaptersCount;
  final int completedChaptersCount;
  final double revisionProgressPercentage;
  final int studyStreak;
  final GymAttendanceModel? gymAttendanceToday;
  final int totalBookmarksCount;
  final ExamModel? nearestExam;
  final StudySessionModel? lastSession;
  final BookmarkModel? lastBookmark;
  final PdfModel? lastPdf;
  final GymAttendanceModel? lastGymAttendance;

  bool get hasAnyActivity =>
      studyMinutesToday > 0 ||
      pendingChaptersCount > 0 ||
      completedChaptersCount > 0 ||
      totalBookmarksCount > 0 ||
      gymAttendanceToday != null ||
      nearestExam != null ||
      lastSession != null ||
      lastBookmark != null ||
      lastPdf != null;

  DashboardData copyWith({
    double? studyMinutesToday,
    DailyGoalModel? dailyGoal,
    int? pendingChaptersCount,
    int? completedChaptersCount,
    double? revisionProgressPercentage,
    int? studyStreak,
    GymAttendanceModel? gymAttendanceToday,
    int? totalBookmarksCount,
    ExamModel? nearestExam,
    StudySessionModel? lastSession,
    BookmarkModel? lastBookmark,
    PdfModel? lastPdf,
    GymAttendanceModel? lastGymAttendance,
  }) {
    return DashboardData(
      studyMinutesToday: studyMinutesToday ?? this.studyMinutesToday,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      pendingChaptersCount: pendingChaptersCount ?? this.pendingChaptersCount,
      completedChaptersCount: completedChaptersCount ?? this.completedChaptersCount,
      revisionProgressPercentage: revisionProgressPercentage ?? this.revisionProgressPercentage,
      studyStreak: studyStreak ?? this.studyStreak,
      gymAttendanceToday: gymAttendanceToday ?? this.gymAttendanceToday,
      totalBookmarksCount: totalBookmarksCount ?? this.totalBookmarksCount,
      nearestExam: nearestExam ?? this.nearestExam,
      lastSession: lastSession ?? this.lastSession,
      lastBookmark: lastBookmark ?? this.lastBookmark,
      lastPdf: lastPdf ?? this.lastPdf,
      lastGymAttendance: lastGymAttendance ?? this.lastGymAttendance,
    );
  }
}

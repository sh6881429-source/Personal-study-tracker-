import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/services/export_service.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';
import 'package:prep_tracker/features/analytics/data/models/achievement_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';

/// ── Analytics CSV Export Service ──
/// Exports all raw analytics data, study sessions, subject statistics, and achievements to CSV.
class AnalyticsCsvService {
  static Future<void> exportAnalyticsCsv({
    required AnalyticsDataModel data,
    required ConsistencyScoreModel scoreModel,
    required List<AchievementModel> achievements,
    required List<StudySessionModel> sessions,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Section 1: Overview Summary
    buffer.writeln('=== PREPTRACKER ANALYTICS OVERVIEW ===');
    buffer.writeln('Export Date,${dateFormat.format(DateTime.now())}');
    buffer.writeln('Total Study Hours,${data.totalStudyHours}');
    buffer.writeln('Today Study Hours,${data.todayStudyHours}');
    buffer.writeln('This Week Study Hours,${data.thisWeekStudyHours}');
    buffer.writeln('This Month Study Hours,${data.thisMonthStudyHours}');
    buffer.writeln('Total Study Sessions,${data.totalStudySessions}');
    buffer.writeln('Average Session Duration (mins),${data.avgSessionMinutes}');
    buffer.writeln('Current Study Streak (days),${data.currentStudyStreak}');
    buffer.writeln('Longest Study Streak (days),${data.longestStudyStreak}');
    buffer.writeln('Consistency Score,${scoreModel.currentScore}');
    buffer.writeln('Consistency Rating Level,${scoreModel.level.label}');
    buffer.writeln('Gym Attendance Rate (%),${data.gymAttendancePercentage}');
    buffer.writeln('Current Gym Streak (days),${data.currentGymStreak}');
    buffer.writeln();

    // Section 2: Subject Breakdown
    buffer.writeln('=== SUBJECT STATISTICS ===');
    buffer.writeln('Subject ID,Subject Name,Total Hours,Session Count,Avg Session Mins,Completion %,Revision %');
    for (final s in data.subjectAnalyticsList) {
      buffer.writeln('"${s.subjectId}","${s.subjectName}",${s.totalHours},${s.sessionCount},${s.avgMinutesPerSession},${s.completionPercentage},${s.revisionPercentage}');
    }
    buffer.writeln();

    // Section 3: Study Sessions Log
    buffer.writeln('=== STUDY SESSIONS LOG ===');
    buffer.writeln('Session ID,Subject ID,Chapter ID,Start Time,End Time,Duration Mins,Notes');
    for (final s in sessions) {
      final noteText = s.sessionNotes?.replaceAll('"', '""') ?? '';
      buffer.writeln('"${s.id}","${s.subjectId}","${s.chapterId}","${dateFormat.format(s.startTime)}","${dateFormat.format(s.endTime)}",${s.durationMinutes},"$noteText"');
    }
    buffer.writeln();

    // Section 4: Achievements & Badges
    buffer.writeln('=== ACHIEVEMENTS & MILESTONES ===');
    buffer.writeln('Achievement ID,Title,Category,Difficulty,Current Value,Target Value,Progress %,Is Unlocked');
    for (final a in achievements) {
      buffer.writeln('"${a.id}","${a.title}","${a.category.label}","${a.difficulty.label}",${a.currentValue},${a.targetValue},${a.progressPercent},${a.isUnlocked}');
    }

    final csvString = buffer.toString();
    final bytes = Uint8List.fromList(utf8.encode(csvString));
    final fileName = 'PrepTracker_Analytics_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    await ExportService.downloadFile(bytes, fileName, 'text/csv');
  }
}

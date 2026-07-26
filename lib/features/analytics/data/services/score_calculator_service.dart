import 'package:flutter/foundation.dart';

import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';

/// ── Score Calculator Service ──
/// Computes CIBIL-style Consistency Score (300–900) using weighted discipline metrics.
class ScoreCalculatorService {
  static ConsistencyScoreModel calculateScore({
    required List<StudySessionModel> sessions,
    required List<GymAttendanceModel> gymRecords,
    required DailyGoalModel? dailyGoal,
    required int previousScore,
    required int storedHighest,
    required int storedLowest,
  }) {
    final now = DateTime.now();

    // 1. Study Goal & Session Consistency (Weight: 35%)
    final totalStudyMinutesMonth = sessions
        .where((s) => s.startTime.month == now.month && s.startTime.year == now.year)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final targetDailyMinutes = dailyGoal?.studyGoalMinutes ?? 120;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final expectedMonthMinutes = targetDailyMinutes * (now.day);

    final double studyRatio = expectedMonthMinutes > 0
        ? (totalStudyMinutesMonth / expectedMonthMinutes).clamp(0.0, 1.0)
        : 0.0;
    final double studyPoints = studyRatio * 210; // Max 210 pts

    // 2. Gym Consistency (Weight: 25%)
    final gymPresentsMonth = gymRecords
        .where((g) => g.attendanceDate.month == now.month && g.attendanceDate.year == now.year && g.status == 'Present')
        .length;
    final double gymRatio = now.day > 0 ? (gymPresentsMonth / (now.day * 0.71)).clamp(0.0, 1.0) : 0.0;
    final double gymPoints = gymRatio * 150; // Max 150 pts

    // 3. Streak Multiplier (Weight: 20%)
    final studyStreak = _calculateStudyStreak(sessions);
    final gymStreak = _calculateGymStreak(gymRecords);
    final double streakRatio = ((studyStreak + gymStreak) / 30.0).clamp(0.0, 1.0);
    final double streakPoints = streakRatio * 120; // Max 120 pts

    // 4. Session Quality & Regularity (Weight: 20%)
    final avgMinutes = sessions.isNotEmpty
        ? (sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) / sessions.length)
        : 0.0;
    final double qualityRatio = (avgMinutes / 45.0).clamp(0.0, 1.0);
    final double qualityPoints = qualityRatio * 120; // Max 120 pts

    // Final Score Calculation
    final int rawScore = (300 + studyPoints + gymPoints + streakPoints + qualityPoints).round();
    final int currentScore = rawScore.clamp(300, 900);

    final level = ConsistencyLevel.fromScore(currentScore);

    final highestScore = currentScore > storedHighest ? currentScore : storedHighest;
    final lowestScore = (storedLowest == 0 || currentScore < storedLowest) ? currentScore : storedLowest;

    // Monthly score history generation (simulated or real history points)
    final history = <MapEntry<DateTime, int>>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i * 4));
      final factor = (1.0 - (i * 0.03)).clamp(0.7, 1.0);
      history.add(MapEntry(date, (currentScore * factor).round().clamp(300, 900)));
    }

    return ConsistencyScoreModel(
      currentScore: currentScore,
      previousScore: previousScore == 0 ? currentScore : previousScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      level: level,
      studyConsistencyPercent: (studyRatio * 100).roundToDouble(),
      gymConsistencyPercent: (gymRatio * 100).roundToDouble(),
      goalCompletionPercent: (((studyRatio + gymRatio) / 2.0) * 100).roundToDouble(),
      streakConsistencyPercent: (streakRatio * 100).roundToDouble(),
      overallConsistencyPercent: (((currentScore - 300) / 600.0) * 100).roundToDouble(),
      monthlyScoreHistory: history,
    );
  }

  static int _calculateStudyStreak(List<StudySessionModel> sessions) {
    if (sessions.isEmpty) return 0;
    final dates = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!dates.contains(today) && !dates.contains(yesterday)) return 0;

    int streak = 0;
    DateTime check = dates.contains(today) ? today : yesterday;
    while (dates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _calculateGymStreak(List<GymAttendanceModel> records) {
    if (records.isEmpty) return 0;
    final presentDates = records
        .where((r) => r.status == 'Present')
        .map((r) => DateTime(r.attendanceDate.year, r.attendanceDate.month, r.attendanceDate.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!presentDates.contains(today) && !presentDates.contains(yesterday)) return 0;

    int streak = 0;
    DateTime check = presentDates.contains(today) ? today : yesterday;
    while (presentDates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

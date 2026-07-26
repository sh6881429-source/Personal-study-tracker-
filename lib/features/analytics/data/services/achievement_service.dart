import 'package:flutter/material.dart';
import 'package:prep_tracker/features/analytics/data/models/achievement_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';

/// ── Achievement Service ──
/// Automatically calculates progress & unlock status for achievements & milestones.
class AchievementService {
  static List<AchievementModel> evaluateAchievements({
    required List<StudySessionModel> sessions,
    required List<GymAttendanceModel> gymRecords,
    required ConsistencyScoreModel consistencyScore,
  }) {
    final totalSessions = sessions.length;
    final totalStudyMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalStudyHours = totalStudyMinutes / 60.0;
    final studyStreak = _calculateStudyStreak(sessions);
    final gymPresentCount = gymRecords.where((g) => g.status == 'Present').length;
    final gymStreak = _calculateGymStreak(gymRecords);
    final score = consistencyScore.currentScore;

    return [
      // ── Study Session Count Badges ──
      AchievementModel(
        id: 'study_1',
        title: 'First Study Session',
        description: 'Complete your first study session in PrepTracker',
        category: AchievementCategory.study,
        difficulty: AchievementDifficulty.bronze,
        icon: Icons.play_circle_fill_rounded,
        color: const Color(0xFF3B82F6),
        currentValue: totalSessions.toDouble(),
        targetValue: 1,
        isUnlocked: totalSessions >= 1,
      ),
      AchievementModel(
        id: 'study_10',
        title: '10 Study Sessions',
        description: 'Log 10 complete study focus sessions',
        category: AchievementCategory.study,
        difficulty: AchievementDifficulty.silver,
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF6366F1),
        currentValue: totalSessions.toDouble(),
        targetValue: 10,
        isUnlocked: totalSessions >= 10,
      ),
      AchievementModel(
        id: 'study_100',
        title: '100 Study Sessions',
        description: 'Master of Focus — Log 100 study sessions',
        category: AchievementCategory.study,
        difficulty: AchievementDifficulty.gold,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF8B5CF6),
        currentValue: totalSessions.toDouble(),
        targetValue: 100,
        isUnlocked: totalSessions >= 100,
      ),

      // ── Study Streak Badges ──
      AchievementModel(
        id: 'streak_7',
        title: '7 Day Study Streak',
        description: 'Study every single day for 1 week',
        category: AchievementCategory.streak,
        difficulty: AchievementDifficulty.silver,
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFB923C),
        currentValue: studyStreak.toDouble(),
        targetValue: 7,
        isUnlocked: studyStreak >= 7,
      ),
      AchievementModel(
        id: 'streak_30',
        title: '30 Day Study Streak',
        description: 'Unstoppable Momentum — 30 consecutive days of study',
        category: AchievementCategory.streak,
        difficulty: AchievementDifficulty.gold,
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFEF4444),
        currentValue: studyStreak.toDouble(),
        targetValue: 30,
        isUnlocked: studyStreak >= 30,
      ),
      AchievementModel(
        id: 'streak_100',
        title: '100 Day Study Streak',
        description: 'Legendary Discipline — 100 days streak!',
        category: AchievementCategory.streak,
        difficulty: AchievementDifficulty.diamond,
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFEC4899),
        currentValue: studyStreak.toDouble(),
        targetValue: 100,
        isUnlocked: studyStreak >= 100,
      ),

      // ── Gym Badges ──
      AchievementModel(
        id: 'gym_1',
        title: 'First Gym Entry',
        description: 'Log your first workout session or attendance',
        category: AchievementCategory.gym,
        difficulty: AchievementDifficulty.bronze,
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFF10B981),
        currentValue: gymPresentCount.toDouble(),
        targetValue: 1,
        isUnlocked: gymPresentCount >= 1,
      ),
      AchievementModel(
        id: 'gym_7',
        title: '7 Day Gym Streak',
        description: 'Consistent fitness — 7 active gym days',
        category: AchievementCategory.gym,
        difficulty: AchievementDifficulty.silver,
        icon: Icons.bolt_rounded,
        color: const Color(0xFF059669),
        currentValue: gymStreak.toDouble(),
        targetValue: 7,
        isUnlocked: gymStreak >= 7,
      ),
      AchievementModel(
        id: 'gym_30',
        title: '30 Day Gym Streak',
        description: 'Iron Body — 30 days gym consistency',
        category: AchievementCategory.gym,
        difficulty: AchievementDifficulty.gold,
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF047857),
        currentValue: gymStreak.toDouble(),
        targetValue: 30,
        isUnlocked: gymStreak >= 30,
      ),

      // ── Study Hours Milestones ──
      AchievementModel(
        id: 'hours_100',
        title: '100 Study Hours',
        description: 'Log 100 hours of focused study time',
        category: AchievementCategory.mastery,
        difficulty: AchievementDifficulty.silver,
        icon: Icons.timer_rounded,
        color: const Color(0xFF0EA5E9),
        currentValue: totalStudyHours,
        targetValue: 100,
        isUnlocked: totalStudyHours >= 100,
      ),
      AchievementModel(
        id: 'hours_250',
        title: '250 Study Hours',
        description: 'Deep Work Pioneer — 250 hours logged',
        category: AchievementCategory.mastery,
        difficulty: AchievementDifficulty.gold,
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFD97706),
        currentValue: totalStudyHours,
        targetValue: 250,
        isUnlocked: totalStudyHours >= 250,
      ),
      AchievementModel(
        id: 'hours_500',
        title: '500 Study Hours',
        description: 'Halfway to Mastery — 500 hours logged',
        category: AchievementCategory.mastery,
        difficulty: AchievementDifficulty.platinum,
        icon: Icons.stars_rounded,
        color: const Color(0xFF4338CA),
        currentValue: totalStudyHours,
        targetValue: 500,
        isUnlocked: totalStudyHours >= 500,
      ),
      AchievementModel(
        id: 'hours_1000',
        title: '1000 Study Hours',
        description: 'Mastermind — 1,000 total hours achieved!',
        category: AchievementCategory.mastery,
        difficulty: AchievementDifficulty.diamond,
        icon: Icons.diamond_rounded,
        color: const Color(0xFF2563EB),
        currentValue: totalStudyHours,
        targetValue: 1000,
        isUnlocked: totalStudyHours >= 1000,
      ),

      // ── Consistency Score Badges ──
      AchievementModel(
        id: 'score_750',
        title: 'Consistent Performer',
        description: 'Reach a Consistency Score of 750 (Excellent)',
        category: AchievementCategory.goals,
        difficulty: AchievementDifficulty.gold,
        icon: Icons.verified_rounded,
        color: const Color(0xFF10B981),
        currentValue: score.toDouble(),
        targetValue: 750,
        isUnlocked: score >= 750,
      ),
      AchievementModel(
        id: 'score_850',
        title: 'Elite Discipline',
        description: 'Achieve an Elite Consistency Score of 850+',
        category: AchievementCategory.goals,
        difficulty: AchievementDifficulty.diamond,
        icon: Icons.shield_rounded,
        color: const Color(0xFF6366F1),
        currentValue: score.toDouble(),
        targetValue: 850,
        isUnlocked: score >= 850,
      ),
    ];
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

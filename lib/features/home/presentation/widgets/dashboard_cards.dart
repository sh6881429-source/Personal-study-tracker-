import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/home/data/models/dashboard_data.dart';
import 'package:prep_tracker/features/home/data/models/exam_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_timer_provider.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
import 'package:prep_tracker/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';

BoxDecoration _brutalDecoration(Color color) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border, width: 3),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        offset: Offset(4, 4),
      ),
    ],
  );
}

Widget _iconBadge(IconData icon, Color color) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border, width: 2),
    ),
    child: Icon(icon, color: color, size: 18),
  );
}

// ─── CARD 1: Today's Study Goal (Soft Purple Card) ──────────────────────────
class TodayStudyGoalCard extends StatelessWidget {
  const TodayStudyGoalCard({
    super.key,
    required this.studyMinutes,
    required this.goalMinutes,
  });

  final double studyMinutes;
  final int goalMinutes;

  @override
  Widget build(BuildContext context) {
    final double hours = studyMinutes / 60.0;
    final double targetHours = (goalMinutes > 0 ? goalMinutes : 120) / 60.0;
    final double progress = goalMinutes > 0 ? (studyMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;
    final int percentVal = (progress * 100).round();

    return GestureDetector(
      onTap: () => context.push('/study/goals'),
      child: Container(
        decoration: _brutalDecoration(const Color(0xFFC7D2FE)), // Soft Lavender Purple
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(Icons.track_changes_rounded, const Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Today's Goal",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$percentVal',
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.0,
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            Text(
              '${hours.toStringAsFixed(1)} / ${targetHours.toStringAsFixed(1)} hrs completed',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Progress bar track
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  percentVal >= 100 ? 'Goal Met! 🎯' : '${100 - percentVal}% Left',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Set Goal',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARD 2: Study Timer (Bright Yellow Card) ────────────────────────────────
class StudyTimerCard extends StatelessWidget {
  const StudyTimerCard({
    super.key,
    required this.timerState,
    required this.onStartTap,
    required this.accumulatedSecondsToday,
  });

  final StudyTimerState timerState;
  final VoidCallback onStartTap;
  final int accumulatedSecondsToday;

  String _formatTimer(int totalSecs) {
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // If timer is stopped, show total accumulated study hours logged today!
    final int displaySeconds = timerState.status == TimerStatus.stopped
        ? accumulatedSecondsToday
        : timerState.durationSeconds;

    final timerString = _formatTimer(displaySeconds);
    final isRunning = timerState.status == TimerStatus.running;

    return GestureDetector(
      onTap: () => context.go('/study'),
      child: Container(
        decoration: _brutalDecoration(const Color(0xFFFFD93D)), // Yellow
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(Icons.timer_rounded, const Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Study Timer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 16),
              ],
            ),
            const SizedBox(height: 12),

            // Digital Timer display
            Center(
              child: Text(
                timerString,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Focus Mode pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.track_changes_rounded, size: 10, color: AppColors.text),
                    const SizedBox(width: 3),
                    Text(
                      'Focus Mode',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Play/Stop Button
            GestureDetector(
              onTap: onStartTap,
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isRunning ? 'Stop Timer' : 'Start Timer',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.text,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARD 3: Gym Progress (Vibrant Pink Card) ────────────────────────────────
class GymProgressCard extends ConsumerWidget {
  const GymProgressCard({
    super.key,
    required this.data,
  });

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gymStatsProvider);
    final isPresentToday = data.gymAttendanceToday?.status == 'Present';

    return statsAsync.when(
      loading: () => Container(
        height: 120,
        decoration: _brutalDecoration(const Color(0xFFFF8EAF)),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
      error: (err, _) => Container(
        height: 120,
        decoration: _brutalDecoration(const Color(0xFFFF8EAF)),
        child: Center(
          child: Text(
            'Error: $err',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      data: (stats) {
        final double progress = stats.monthlyAttendancePercentage / 100.0;
        final int percentVal = stats.monthlyAttendancePercentage.round();
        final int workoutsDone = stats.presentCount;

        return GestureDetector(
          onTap: () => context.go('/gym'),
          child: Container(
            decoration: _brutalDecoration(const Color(0xFFFF8EAF)), // Soft vibrant pink
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBadge(Icons.fitness_center_rounded, const Color(0xFFE11D48)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Gym Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$percentVal',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '%',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Monthly Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isPresentToday ? 'Logged Today!' : '$workoutsDone Present This Month',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── CARD 4: Daily Streak (Vibrant Orange Card with custom Flame painting) ──
class DailyStreakCard extends StatelessWidget {
  const DailyStreakCard({
    super.key,
    required this.streakCount,
    required this.weeklyDays,
  });

  final int streakCount;
  final Set<int> weeklyDays;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/study'),
      child: Container(
        decoration: _brutalDecoration(const Color(0xFFFB923C)), // Orange
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(Icons.local_fire_department_rounded, const Color(0xFFEA580C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Daily Streak',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 16),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streakCount Days',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Keep streak alive!',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CustomPaint(
                    painter: _FlamePainter(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weekdays row - dynamically highlights based on weeklyDays set
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dayCircle('M', weeklyDays.contains(1)),
                _dayCircle('T', weeklyDays.contains(2)),
                _dayCircle('W', weeklyDays.contains(3)),
                _dayCircle('T', weeklyDays.contains(4)),
                _dayCircle('F', weeklyDays.contains(5)),
                _dayCircle('S', weeklyDays.contains(6)),
                _dayCircle('S', weeklyDays.contains(7)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCircle(String label, bool active) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFD93D) : Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final pathOuter = Path()
      ..moveTo(cx, 2)
      ..cubicTo(cx - 20, cy + 6, cx - 16, size.height, cx, size.height - 2)
      ..cubicTo(cx + 18, size.height, cx + 20, cy + 6, cx, 2)
      ..close();
    canvas.drawPath(pathOuter, paint);
    canvas.drawPath(pathOuter, outline);

    paint.color = const Color(0xFFFFD93D);
    final pathInner = Path()
      ..moveTo(cx, cy - 4)
      ..cubicTo(cx - 8, cy + 2, cx - 6, size.height - 4, cx, size.height - 5)
      ..cubicTo(cx + 6, size.height - 4, cx + 8, cy + 2, cx, cy - 4)
      ..close();
    canvas.drawPath(pathInner, paint);
    canvas.drawPath(pathInner, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── CARD 5: Syllabus (Sky Blue Card - optimized for phone) ──────────────────
class SyllabusCard extends StatelessWidget {
  const SyllabusCard({
    super.key,
    required this.data,
  });

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final total = data.completedChaptersCount + data.pendingChaptersCount;
    final progress = total > 0 ? (data.completedChaptersCount / total) : 0.0;
    final percentVal = (progress * 100).round();

    return GestureDetector(
      onTap: () => context.go('/syllabus'),
      child: Container(
        decoration: _brutalDecoration(const Color(0xFF93C5FD)), // Light Blue
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(Icons.menu_book_rounded, Colors.blue.shade700),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 14),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Syllabus',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${data.completedChaptersCount}/$total Chapters',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$percentVal% Done',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Mini progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARD 6: Consistency Score Card (Replaces Analytics Card - Navigates to Consistency Tab) ────────────
class ConsistencyScoreCard extends ConsumerWidget {
  const ConsistencyScoreCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(consistencyScoreProvider);

    return scoreAsync.when(
      loading: () => Container(
        height: 110,
        decoration: _brutalDecoration(const Color(0xFF7DD3FC)),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          ),
        ),
      ),
      error: (err, _) => Container(
        height: 110,
        decoration: _brutalDecoration(const Color(0xFF7DD3FC)),
        child: Center(
          child: Text('Score Error', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ),
      data: (scoreModel) {
        final badgeTextColor = (scoreModel.level.color == const Color(0xFFFFD60A) || scoreModel.level.color == const Color(0xFF34D399))
            ? Colors.black
            : Colors.white;

        return GestureDetector(
          onTap: () => context.go('/analytics?tab=consistency'),
          child: Container(
            decoration: _brutalDecoration(const Color(0xFF7DD3FC)), // Sky Blue
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBadge(Icons.verified_user_rounded, const Color(0xFF0369A1)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Consistency',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: scoreModel.level.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    scoreModel.level.label,
                    style: GoogleFonts.poppins(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${scoreModel.currentScore}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Backwards compatibility alias for AnalyticsCard
typedef AnalyticsCard = ConsistencyScoreCard;

// ─── CARD 7: Achievements Card (Real-Time Badges & Navigates to Achievements Tab) ───────
class AchievementsCard extends ConsumerWidget {
  const AchievementsCard({
    super.key,
    this.badgeCount = 0,
  });

  final int badgeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      loading: () => Container(
        height: 110,
        decoration: _brutalDecoration(const Color(0xFF86EFAC)),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          ),
        ),
      ),
      error: (err, _) => Container(
        height: 110,
        decoration: _brutalDecoration(const Color(0xFF86EFAC)),
        child: Center(
          child: Text('Error', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ),
      data: (achievements) {
        final unlockedCount = achievements.where((a) => a.isUnlocked).length;
        final totalCount = achievements.isEmpty ? 15 : achievements.length;

        return GestureDetector(
          onTap: () => context.go('/analytics?tab=achievements'),
          child: Container(
            decoration: _brutalDecoration(const Color(0xFF86EFAC)), // Soft Green
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBadge(Icons.emoji_events_rounded, const Color(0xFF15803D)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.text, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Achievements',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Unlocked Badges',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$unlockedCount / $totalCount',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(
                        painter: _MedalPainter(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MedalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final ribbon1 = Path()
      ..moveTo(cx - 4, cy)
      ..lineTo(cx - 8, size.height)
      ..lineTo(cx - 1, size.height - 3)
      ..lineTo(cx - 1, cy)
      ..close();
    canvas.drawPath(ribbon1, paint);
    canvas.drawPath(ribbon1, outline);

    final ribbon2 = Path()
      ..moveTo(cx + 4, cy)
      ..lineTo(cx + 8, size.height)
      ..lineTo(cx + 1, size.height - 3)
      ..lineTo(cx + 1, cy)
      ..close();
    canvas.drawPath(ribbon2, paint);
    canvas.drawPath(ribbon2, outline);

    paint.color = const Color(0xFFFFD93D);
    canvas.drawCircle(Offset(cx, cy - 2), 6, paint);
    canvas.drawCircle(Offset(cx, cy - 2), 6, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

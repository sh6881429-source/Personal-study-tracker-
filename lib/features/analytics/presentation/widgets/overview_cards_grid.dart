import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';

class OverviewCardsGrid extends StatelessWidget {
  const OverviewCardsGrid({
    super.key,
    required this.data,
    required this.scoreModel,
  });

  final AnalyticsDataModel data;
  final ConsistencyScoreModel scoreModel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final crossAxisCount = isDesktop ? 4 : 2;

    final metrics = [
      _MetricItem('Total Study Hours', '${data.totalStudyHours.toStringAsFixed(1)} hrs', Icons.timer_rounded, const Color(0xFF5B5FEF)),
      _MetricItem('Today Study Time', '${data.todayStudyHours.toStringAsFixed(1)} hrs', Icons.today_rounded, const Color(0xFF34D399)),
      _MetricItem('This Week Time', '${data.thisWeekStudyHours.toStringAsFixed(1)} hrs', Icons.date_range_rounded, const Color(0xFFFFD60A)),
      _MetricItem('This Month Time', '${data.thisMonthStudyHours.toStringAsFixed(1)} hrs', Icons.calendar_month_rounded, const Color(0xFFFF8C42)),
      _MetricItem('Total Sessions', '${data.totalStudySessions}', Icons.play_circle_fill_rounded, const Color(0xFF8B5CF6)),
      _MetricItem('Avg Session Length', '${data.avgSessionMinutes.toStringAsFixed(0)} mins', Icons.timelapse_rounded, const Color(0xFF0EA5E9)),
      _MetricItem('Longest Session', '${data.longestSessionMinutes.toStringAsFixed(0)} mins', Icons.stars_rounded, const Color(0xFFEC4899)),
      _MetricItem('Current Streak', '${data.currentStudyStreak} Days', Icons.local_fire_department_rounded, const Color(0xFFEF4444)),
      _MetricItem('Longest Streak', '${data.longestStudyStreak} Days', Icons.whatshot_rounded, const Color(0xFFF97316)),
      _MetricItem('Total Subjects', '${data.totalSubjects}', Icons.menu_book_rounded, const Color(0xFF6366F1)),
      _MetricItem('Completed Chaps', '${data.completedChaptersCount}', Icons.check_circle_rounded, const Color(0xFF10B981)),
      _MetricItem('Pending Chaps', '${data.pendingChaptersCount}', Icons.pending_actions_rounded, const Color(0xFF64748B)),
      _MetricItem('Revision Rate', '${data.revisionCompletionPercentage.toStringAsFixed(0)}%', Icons.published_with_changes_rounded, const Color(0xFF14B8A6)),
      _MetricItem('Gym Attendance', '${data.gymAttendancePercentage.toStringAsFixed(0)}%', Icons.fitness_center_rounded, const Color(0xFFE11D48)),
      _MetricItem('Gym Streak', '${data.currentGymStreak} Days', Icons.bolt_rounded, const Color(0xFF059669)),
      _MetricItem('Consistency Score', '${scoreModel.currentScore}', Icons.verified_rounded, scoreModel.level.color),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isDesktop ? 2.2 : 1.75,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(3, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _MetricItem(this.title, this.value, this.icon, this.color);
}

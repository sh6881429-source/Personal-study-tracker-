import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/consistency_score_model.dart';

class ConsistencyScoreWidget extends StatelessWidget {
  const ConsistencyScoreWidget({
    super.key,
    required this.scoreModel,
  });

  final ConsistencyScoreModel scoreModel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    // Helper for contrasting text color on level badge
    final badgeTextColor = (scoreModel.level.color == const Color(0xFFFFD60A) || scoreModel.level.color == const Color(0xFF34D399))
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title & badge with Overflow Protection
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: scoreModel.level.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Icon(Icons.verified_user_rounded, color: badgeTextColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consistency Score',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 15, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scoreModel.level.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                ),
                child: Text(
                  scoreModel.level.label,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10, color: badgeTextColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Central Score Gauge & Stats
          Row(
            children: [
              // Large Circular Gauge with High Visibility Background & Borders
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFDF0),
                  border: Border.all(color: scoreModel.level.color, width: 5),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${scoreModel.currentScore}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreModel.level.color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        '300 - 900',
                        style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w900, color: badgeTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // High/Low/Previous metrics
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFDF0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                  ),
                  child: Column(
                    children: [
                      _scoreMetricRow('Previous Score', '${scoreModel.previousScore}', isDark),
                      const Divider(height: 10, color: Colors.black26),
                      _scoreMetricRow('Highest Score', '${scoreModel.highestScore}', isDark, color: const Color(0xFF10B981)),
                      const Divider(height: 10, color: Colors.black26),
                      _scoreMetricRow('Lowest Score', '${scoreModel.lowestScore}', isDark, color: const Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Breakdown Contribution Progress Bars
          Text(
            'Score Contribution Breakdown',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13, color: textColor),
          ),
          const SizedBox(height: 10),
          _breakdownBar('Study Goals Consistency', scoreModel.studyConsistencyPercent, AppColors.primary, isDark),
          _breakdownBar('Gym Attendance Rate', scoreModel.gymConsistencyPercent, const Color(0xFFE11D48), isDark),
          _breakdownBar('Goal Success Rate', scoreModel.goalCompletionPercent, const Color(0xFF10B981), isDark),
          _breakdownBar('Active Streaks', scoreModel.streakConsistencyPercent, const Color(0xFFF97316), isDark),

          const SizedBox(height: 18),

          // Monthly Score History Line Chart
          Text(
            'Monthly Score History',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13, color: textColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < scoreModel.monthlyScoreHistory.length) {
                          final date = scoreModel.monthlyScoreHistory[idx].key;
                          return Text(
                            DateFormat('d/M').format(date),
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : AppColors.textSecondary),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 300,
                maxY: 900,
                lineBarsData: [
                  LineChartBarData(
                    spots: scoreModel.monthlyScoreHistory.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: scoreModel.level.color,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: scoreModel.level.color.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreMetricRow(String label, String value, bool isDark, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: color ?? (isDark ? Colors.white : AppColors.text)),
        ),
      ],
    );
  }

  Widget _breakdownBar(String label, double percent, Color barColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : AppColors.text),
              ),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (percent / 100.0).clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

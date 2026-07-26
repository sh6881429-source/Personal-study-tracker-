import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';

class StudyChartsWidget extends StatelessWidget {
  const StudyChartsWidget({
    super.key,
    required this.data,
  });

  final AnalyticsDataModel data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Daily Study Hours Bar Chart
        Container(
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
              // Header Row with Overflow Protection
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Study Hours Trend',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      '${data.totalStudyHours.toStringAsFixed(1)} Total Hrs',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: data.dailyStudyHoursMap.isEmpty
                    ? Center(
                        child: Text(
                          'No study hours logged for this period.',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final entries = data.dailyStudyHoursMap.entries.toList();
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < entries.length) {
                                    return Text(
                                      DateFormat('dd/M').format(entries[idx].key),
                                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : AppColors.textSecondary),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: data.dailyStudyHoursMap.entries.toList().asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value,
                                  color: AppColors.primary,
                                  width: 12,
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 2: Subject Breakdown Pie/Donut Chart
        Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subject Distribution',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.subjectAnalyticsList.isEmpty || data.subjectAnalyticsList.every((s) => s.totalHours == 0))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No subject study logs available.',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 35,
                          sections: data.subjectAnalyticsList.where((s) => s.totalHours > 0).map((s) {
                            final color = _hexToColor(s.colorHex);
                            return PieChartSectionData(
                              color: color,
                              value: s.totalHours,
                              title: '${s.totalHours.toStringAsFixed(1)}h',
                              radius: 40,
                              titleStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: data.subjectAnalyticsList.map((s) {
                        final color = _hexToColor(s.colorHex);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${s.subjectName} (${s.totalHours.toStringAsFixed(1)}h)',
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

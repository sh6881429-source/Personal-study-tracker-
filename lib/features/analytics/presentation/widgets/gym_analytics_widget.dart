import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';

class GymAnalyticsWidget extends StatelessWidget {
  const GymAnalyticsWidget({
    super.key,
    required this.data,
  });

  final AnalyticsDataModel data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gym Analytics',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 15, color: textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                ),
                child: Text(
                  '${data.gymAttendancePercentage.toStringAsFixed(0)}% Rate',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3 Columns: Present, Absent, Rest Days with High-Legibility Styling
          Row(
            children: [
              Expanded(
                child: _gymStatTile(
                  'Present',
                  '${data.gymPresentDays} Days',
                  bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  valColor: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                  lblColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _gymStatTile(
                  'Absent',
                  '${data.gymAbsentDays} Days',
                  bgColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                  valColor: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                  lblColor: isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _gymStatTile(
                  'Rest Days',
                  '${data.gymRestDays} Days',
                  bgColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                  valColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                  lblColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Attendance Progress Bar
          Text(
            'Monthly Gym Attendance Goal',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (data.gymAttendancePercentage / 100.0).clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gymStatTile(
    String label,
    String value, {
    required Color bgColor,
    required Color valColor,
    required Color lblColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w900, color: valColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: lblColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';

class GoalPdfBookmarkWidget extends StatelessWidget {
  const GoalPdfBookmarkWidget({
    super.key,
    required this.data,
  });

  final AnalyticsDataModel data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    return Column(
      children: [
        // Card 1: Goal & Revision Analytics
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Goal & Revision Analytics',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _infoBox('Daily Goal', '${(data.dailyGoalMinutes / 60).toStringAsFixed(1)} hrs/day', isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _infoBox('Weekly Goal', '${data.weeklyGoalHours} hrs/wk', isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _infoBox('Success Rate', '${data.goalSuccessRate.toStringAsFixed(0)}%', isDark)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card 2: Bookmark & PDF Analytics
        Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bookmarks & PDF Library',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _infoBox('Total Bookmarks', '${data.totalBookmarks}', isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _infoBox('Pinned Links', '${data.pinnedBookmarks}', isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _infoBox('PDF Documents', '${data.uploadedPdfs}', isDark)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _infoBox('Favorite PDFs', '${data.favoritePdfs}', isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _infoBox('Storage Used', '${data.totalStorageUsedMb.toStringAsFixed(1)} MB', isDark)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBox(String title, String val, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

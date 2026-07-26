import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/home/data/models/dashboard_data.dart';

/// ── Recent Activity Section ──
class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({
    super.key,
    required this.data,
  });

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    // If no activity exists at all, hide or return empty
    if (data.lastSession == null &&
        data.lastBookmark == null &&
        data.lastPdf == null &&
        data.lastGymAttendance == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LATEST UPDATES',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            // Last Study Session (Soft Purple)
            if (data.lastSession != null)
              _ActivityTile(
                icon: Icons.timer_rounded,
                bgColor: const Color(0xFFE9D5FF), // Soft Purple
                title: 'Logged Study Session',
                subtitle: 'Studied for ${data.lastSession!.durationMinutes} minutes',
                trailingText: '${data.lastSession!.studyDate.day}/${data.lastSession!.studyDate.month}',
              ),

            // Last Bookmark (Soft Blue/Sky)
            if (data.lastBookmark != null)
              _ActivityTile(
                icon: Icons.link_rounded,
                bgColor: const Color(0xFFBAE6FD), // Soft Blue
                title: 'Saved Bookmark Link',
                subtitle: data.lastBookmark!.title,
                trailingText: 'Added',
              ),

            // Latest PDF (Soft Teal/Mint)
            if (data.lastPdf != null)
              _ActivityTile(
                icon: Icons.upload_file_rounded,
                bgColor: const Color(0xFF99F6E4), // Soft Teal
                title: 'Uploaded Document',
                subtitle: data.lastPdf!.originalName,
                trailingText: '${(data.lastPdf!.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
              ),

            // Latest Gym Attendance (Soft Pink/Rose)
            if (data.lastGymAttendance != null)
              _ActivityTile(
                icon: Icons.fitness_center_rounded,
                bgColor: const Color(0xFFFECDD3), // Soft Pink
                title: 'Logged Gym Attendance',
                subtitle: 'Status: ${data.lastGymAttendance!.status}',
                trailingText: '${data.lastGymAttendance!.attendanceDate.day}/${data.lastGymAttendance!.attendanceDate.month}',
              ),
          ],
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
  });

  final IconData icon;
  final Color bgColor;
  final String title;
  final String subtitle;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(2.5, 2.5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Icon(icon, color: AppColors.text, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              trailingText,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

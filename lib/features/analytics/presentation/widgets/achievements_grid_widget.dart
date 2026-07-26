import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/achievement_model.dart';

class AchievementsGridWidget extends StatelessWidget {
  const AchievementsGridWidget({
    super.key,
    required this.achievements,
  });

  final List<AchievementModel> achievements;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount;
    final double childAspectRatio;

    if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.92;
    } else if (screenWidth < 1100) {
      crossAxisCount = 3;
      childAspectRatio = 1.25;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.45;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD60A),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Achievements',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2))],
                ),
                child: Text(
                  '$unlockedCount / ${achievements.length} Unlocked',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Achievements Responsive Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: a.isUnlocked
                      ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF9C3))
                      : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black,
                    width: a.isUnlocked ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: a.isUnlocked ? const Offset(3.5, 3.5) : const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Icon + Difficulty Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: a.isUnlocked ? a.color : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Icon(
                            a.icon,
                            color: a.isUnlocked ? Colors.white : Colors.grey.shade700,
                            size: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: a.difficulty.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            a.difficulty.label,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title & Description
                    Text(
                      a.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: a.isUnlocked ? textColor : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      a.description,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Progress or Unlocked Tag
                    if (!a.isUnlocked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                              ),
                              Text(
                                '${a.progressPercent}%',
                                style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 1.2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: a.progressRatio,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'UNLOCKED',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

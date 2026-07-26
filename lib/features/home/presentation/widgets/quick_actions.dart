import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';

/// ── Quick Actions Card ──
/// A single white Brutalist card containing a horizontal row of shortcuts.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),

        // Main white card row
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                offset: Offset(4, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionTile(
                label: 'Add Study\nSession',
                icon: Icons.edit_note_rounded,
                bgColor: const Color(0xFFC7D2FE), // Purple
                iconColor: const Color(0xFF7C3AED),
                onTap: () => context.push('/syllabus'),
              ),
              _ActionTile(
                label: 'Quick\nTimer',
                icon: Icons.timer_rounded,
                bgColor: const Color(0xFFFEF08A), // Yellow
                iconColor: const Color(0xFFD97706),
                onTap: () => context.go('/study'),
              ),
              _ActionTile(
                label: 'Workout\nLog',
                icon: Icons.fitness_center_rounded,
                bgColor: const Color(0xFFFECDD3), // Pink
                iconColor: const Color(0xFFE11D48),
                onTap: () => context.go('/gym'),
              ),
              _ActionTile(
                label: 'Reminders',
                icon: Icons.notifications_active_rounded,
                bgColor: const Color(0xFFBBF7D0), // Mint Green
                iconColor: const Color(0xFF16A34A),
                onTap: () => context.push('/reminders'),
              ),
              _ActionTile(
                label: 'Ask AI',
                icon: Icons.smart_toy_rounded,
                bgColor: const Color(0xFFBAE6FD), // Sky Blue
                iconColor: const Color(0xFF0284C7),
                onTap: () => context.push('/ask-yash'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Icon(icon, color: AppColors.text, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';

/// ── Neo Brutalism Card ──
/// Base card with thick border, hard offset shadow, and rounded corners.
///
/// ```dart
/// AppCard(
///   child: Text('Hello'),
///   onTap: () {},
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding,
    this.onTap,
    this.hasShadow = true,
    this.hasBorder = true,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hasShadow;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: hasBorder
            ? Border.all(
                color: AppColors.border,
                width: AppConstants.borderWidth,
              )
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.2),
                  offset: const Offset(
                    AppConstants.shadowOffset,
                    AppConstants.shadowOffset,
                  ),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// ── Stat Card ──
/// Displays a numeric value with icon, title, and optional subtitle.
/// Great for dashboards: study hours, gym sessions, streaks, etc.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Icon badge ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              border: Border.all(
                color: AppColors.border,
                width: AppConstants.borderWidth - 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Value ──
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.2,
            ),
          ),

          // ── Title ──
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          // ── Subtitle ──
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ── Action Card ──
/// Tappable card with icon, title/subtitle, and trailing arrow.
/// Used for navigation items: "View Study History", "Start Workout", etc.
class AppActionCard extends StatelessWidget {
  const AppActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // ── Leading icon ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              border: Border.all(
                color: AppColors.border,
                width: AppConstants.borderWidth - 1,
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // ── Trailing arrow ──
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

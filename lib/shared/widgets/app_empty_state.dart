import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';

/// ── Empty State Widget ──
/// Displays a centered icon, title, descriptive message, and an optional
/// action button. Used when a list is empty, a feature is not yet available,
/// or no data matches a search.
///
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox_rounded,
///   title: 'No Bookmarks',
///   message: 'Save resources here for quick access.',
///   actionLabel: 'Browse Resources',
///   onAction: () {},
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon Badge ──
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: AppConstants.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.15),
                    offset: const Offset(
                      AppConstants.shadowOffset,
                      AppConstants.shadowOffset,
                    ),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Title ──
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Message ──
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            // ── Action Button ──
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.md,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

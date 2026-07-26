import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';

/// ── Neo Brutalism Dialogs ──
/// Static helper class for showing styled dialogs with thick borders,
/// hard shadows, and bold typography.
abstract final class AppDialog {
  /// Shows a confirmation dialog with confirm / cancel actions.
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StyledDialog(
        icon: Icons.help_outline_rounded,
        iconColor: AppColors.primary,
        title: title,
        message: message,
        actions: [
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: confirmLabel,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  /// Shows an informational dialog with an OK button.
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _StyledDialog(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.primary,
        title: title,
        message: message,
        actions: [
          AppButton(
            label: 'OK',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog with an OK button.
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _StyledDialog(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: title,
        message: message,
        actions: [
          AppButton(
            label: 'OK',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Internal reusable dialog shell.
class _StyledDialog extends StatelessWidget {
  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.2),
              offset: const Offset(
                AppConstants.shadowOffset,
                AppConstants.shadowOffset,
              ),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: AppSpacing.md),

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
            const SizedBox(height: AppSpacing.lg),

            // ── Actions ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

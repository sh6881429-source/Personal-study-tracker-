import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';

/// Button variant determines the visual style.
enum AppButtonVariant { primary, secondary, outline, danger, success }

/// Button size determines padding and font size.
enum AppButtonSize { sm, md, lg }

/// ── Neo Brutalism Button ──
/// A versatile button with thick borders, hard shadows, and press animation.
///
/// ```dart
/// AppButton(
///   label: 'Start Session',
///   onPressed: () {},
///   variant: AppButtonVariant.primary,
///   icon: Icons.play_arrow_rounded,
/// )
/// ```
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;
  final AppButtonSize size;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  /// Whether interaction is entirely blocked.
  bool get _isInteractionDisabled =>
      widget.isDisabled || widget.isLoading || widget.onPressed == null;

  // ── Color Helpers ──

  Color get _backgroundColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.surface;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.error;
      case AppButtonVariant.success:
        return AppColors.secondary;
    }
  }

  Color get _foregroundColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.success:
        return Colors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return AppColors.text;
    }
  }

  Color get _borderColor => AppColors.border;

  // ── Size Helpers ──

  EdgeInsets get _padding {
    final bool isIconOnly = widget.label.isEmpty;
    switch (widget.size) {
      case AppButtonSize.sm:
        return EdgeInsets.symmetric(
          horizontal: isIconOnly ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.md:
        return EdgeInsets.symmetric(
          horizontal: isIconOnly ? AppSpacing.md : AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.lg:
        return EdgeInsets.symmetric(
          horizontal: isIconOnly ? AppSpacing.md + 4 : AppSpacing.xl,
          vertical: AppSpacing.md + 4,
        );
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 13;
      case AppButtonSize.md:
        return 15;
      case AppButtonSize.lg:
        return 17;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 16;
      case AppButtonSize.md:
        return 20;
      case AppButtonSize.lg:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shadow disappears on press; slight upward shift on hover is handled
    // implicitly — the translate-down on press is the primary interaction cue.
    final double translateY = _isPressed ? AppConstants.shadowOffset : 0;

    final button = GestureDetector(
      onTapDown: _isInteractionDisabled
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: _isInteractionDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: _isInteractionDisabled
          ? null
          : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, translateY, 0),
        padding: _padding,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          border: Border.all(
            color: _borderColor,
            width: AppConstants.borderWidth,
          ),
          boxShadow: _isPressed
              ? [] // Shadow removed when pressed
              : [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.2),
                    offset: const Offset(
                      AppConstants.shadowOffset,
                      AppConstants.shadowOffset,
                    ),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize:
              widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading) ...[
              SizedBox(
                width: _iconSize,
                height: _iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_foregroundColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, size: _iconSize, color: _foregroundColor),
              if (widget.label.isNotEmpty) const SizedBox(width: AppSpacing.sm),
            ],
            if (widget.label.isNotEmpty)
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    color: _foregroundColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap in Opacity for disabled state.
    final result = _isInteractionDisabled && !widget.isLoading
        ? Opacity(opacity: 0.5, child: IgnorePointer(child: button))
        : button;

    return widget.isFullWidth
        ? SizedBox(width: double.infinity, child: result)
        : result;
  }
}

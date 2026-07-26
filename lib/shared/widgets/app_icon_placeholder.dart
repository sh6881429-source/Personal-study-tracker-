import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';

/// ── PrepTracker App Icon Placeholder ──
/// A vector-based representation of the app icon following the Neo Brutalism style guide.
/// Features a yellow card, heavy black outline, and double-bolt or book-dumbbell visual.
class AppIconPlaceholder extends StatelessWidget {
  const AppIconPlaceholder({
    super.key,
    this.size = 120,
    this.showBorder = true,
  });

  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent, // Yellow accent background from reference
        borderRadius: BorderRadius.circular(size * 0.25),
        border: showBorder
            ? Border.all(
                color: AppColors.border,
                width: size * 0.05,
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(size * 0.04, size * 0.04),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: size * 0.5,
              color: AppColors.text,
            ),
            Text(
              'PT',
              style: GoogleFonts.poppins(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/shared/widgets/app_icon_placeholder.dart';

/// ── PrepTracker Splash Screen Placeholder ──
/// Displayed during app initialization, showing the application icon and name.
class SplashScreenPlaceholder extends StatelessWidget {
  const SplashScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIconPlaceholder(size: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'PREPTRACKER',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: 2,
              ),
            ),
            Text(
              'BY YASH',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

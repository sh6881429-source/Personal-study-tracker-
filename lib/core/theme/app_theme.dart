import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/core/constants/app_text_styles.dart';

/// ── PrepTracker Neo Brutalism Theme ──
/// Fully implements the flat, high-contrast, bold-outline style.
abstract final class AppTheme {
  static const Color _backgroundDark = Color(0xFF121212);

  static final BorderSide _standardBorder = BorderSide(
    color: AppColors.border,
    width: AppConstants.borderWidth,
  );

  /// Helper to get the hard offset shadow list.
  static List<BoxShadow> get hardShadow => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.2),
          offset: const Offset(
            AppConstants.shadowOffset,
            AppConstants.shadowOffset,
          ),
          blurRadius: 0,
        ),
      ];

  /// Light Theme Configuration.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
        onError: Colors.white,
      ),

      // ── AppBar Theme ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMD(color: AppColors.text),
        iconTheme: const IconThemeData(color: AppColors.text),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
        ),
      ),

      // ── Card Theme ──
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: _standardBorder,
        ),
      ),

      // ── Button Themes ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            side: _standardBorder,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface,
          elevation: 0,
          side: _standardBorder,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTextStyles.labelLG(),
        ),
      ),

      // ── Inputs / TextFields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: _standardBorder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: _standardBorder,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: AppConstants.borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppConstants.borderWidth,
          ),
        ),
        labelStyle: AppTextStyles.bodyMD(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.bodyMD(color: AppColors.textSecondary),
      ),

      // ── Dialog Theme ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: _standardBorder,
        ),
        titleTextStyle: AppTextStyles.headingSM(),
        contentTextStyle: AppTextStyles.bodyMD(),
      ),

      // ── SnackBar Theme ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        actionTextColor: AppColors.primary,
        contentTextStyle: AppTextStyles.bodyMD(),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          side: _standardBorder,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Bottom Nav Bar Theme ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.labelSM(),
        unselectedLabelStyle: AppTextStyles.labelSM(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Chip Theme ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        disabledColor: AppColors.background,
        selectedColor: AppColors.accent,
        secondarySelectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          side: _standardBorder,
        ),
        labelStyle: AppTextStyles.labelMD(),
      ),

      // ── Divider Theme ──
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: AppConstants.borderWidth,
        space: AppSpacing.lg,
      ),

      // ── Typography Integration ──
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingXL(),
        headlineMedium: AppTextStyles.headingLG(),
        titleLarge: AppTextStyles.headingSM(),
        bodyLarge: AppTextStyles.bodyLG(),
        bodyMedium: AppTextStyles.bodyMD(),
        bodySmall: AppTextStyles.bodySM(),
        labelLarge: AppTextStyles.labelLG(),
        labelSmall: AppTextStyles.labelSM(),
      ),
    );
  }

  /// Dark Theme Configuration.
  /// Uses a high contrast, vibrant dark mode palette.
  static ThemeData get dark {
    final lightTheme = light;
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF262626),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: _backgroundDark,
        titleTextStyle: AppTextStyles.headingMD(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: Border(
          bottom: BorderSide(
            color: Colors.white,
            width: AppConstants.borderWidth,
          ),
        ),
      ),
      cardTheme: lightTheme.cardTheme.copyWith(
        color: const Color(0xFF262626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(
            color: Colors.white,
            width: AppConstants.borderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            side: const BorderSide(
              color: Colors.white,
              width: AppConstants.borderWidth,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF262626),
          elevation: 0,
          side: const BorderSide(
            color: Colors.white,
            width: AppConstants.borderWidth,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF262626),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: const BorderSide(color: Colors.white, width: AppConstants.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: const BorderSide(color: Colors.white, width: AppConstants.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: BorderSide(color: AppColors.primary, width: AppConstants.borderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          borderSide: BorderSide(color: AppColors.error, width: AppConstants.borderWidth),
        ),
        labelStyle: AppTextStyles.bodyMD(color: Colors.grey[400]!),
        hintStyle: AppTextStyles.bodyMD(color: Colors.grey[400]!),
      ),
      dialogTheme: lightTheme.dialogTheme.copyWith(
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: Colors.white, width: AppConstants.borderWidth),
        ),
        titleTextStyle: AppTextStyles.headingSM(color: Colors.white),
        contentTextStyle: AppTextStyles.bodyMD(color: Colors.grey[300]!),
      ),
      snackBarTheme: lightTheme.snackBarTheme.copyWith(
        backgroundColor: const Color(0xFF262626),
        contentTextStyle: AppTextStyles.bodyMD(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          side: const BorderSide(color: Colors.white, width: AppConstants.borderWidth),
        ),
      ),
      bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey[600]!,
      ),
      chipTheme: lightTheme.chipTheme.copyWith(
        backgroundColor: const Color(0xFF262626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          side: const BorderSide(color: Colors.white, width: AppConstants.borderWidth),
        ),
        labelStyle: AppTextStyles.labelMD(color: Colors.white),
      ),
      dividerTheme: lightTheme.dividerTheme.copyWith(
        color: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingXL(color: Colors.white),
        headlineMedium: AppTextStyles.headingLG(color: Colors.white),
        titleLarge: AppTextStyles.headingSM(color: Colors.white),
        bodyLarge: AppTextStyles.bodyLG(color: Colors.grey[200]!),
        bodyMedium: AppTextStyles.bodyMD(color: Colors.grey[300]!),
        bodySmall: AppTextStyles.bodySM(color: Colors.grey[400]!),
        labelLarge: AppTextStyles.labelLG(color: Colors.white),
        labelSmall: AppTextStyles.labelSM(color: Colors.grey[400]!),
      ),
    );
  }
}

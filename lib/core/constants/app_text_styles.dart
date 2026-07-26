import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';

/// ── PrepTracker Typography System ──
/// Custom typography scales designed for Neo Brutalism UI.
/// Headings: Poppins (Bold/ExtraBold, heavy weight)
/// Body & Labels: Inter (Regular/Medium/SemiBold)
abstract final class AppTextStyles {
  // ── Headings (Poppins) ──
  static TextStyle headingXL({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  static TextStyle headingLG({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle headingMD({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );

  static TextStyle headingSM({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.35,
      );

  // ── Body Text (Inter) ──
  static TextStyle bodyLG({Color color = AppColors.text}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMD({Color color = AppColors.text}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodySM({Color color = AppColors.textSecondary}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // ── Labels & Action Buttons (Inter) ──
  static TextStyle labelLG({Color color = AppColors.text}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      );

  static TextStyle labelMD({Color color = AppColors.text}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelSM({Color color = AppColors.textSecondary}) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Stats (Poppins Bold Numbers) ──
  static TextStyle statXL({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.0,
      );

  static TextStyle statLG({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  static TextStyle statMD({Color color = AppColors.text}) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );
}

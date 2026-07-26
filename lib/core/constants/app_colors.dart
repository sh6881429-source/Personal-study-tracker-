import 'package:flutter/material.dart';

/// ── PrepTracker Color Tokens ──
/// Neo Brutalism palette: flat, vibrant, high-contrast colors.
/// All colors are intentionally opaque and saturated.
abstract final class AppColors {
  // ── Brand ──
  static const Color primary = Color(0xFF5B5FEF); // purple-blue
  static const Color secondary = Color(0xFF34D399); // green
  static const Color accent = Color(0xFFFFD60A); // yellow

  // ── Feedback ──
  static const Color error = Color(0xFFFF5D73); // pink
  static const Color warning = Color(0xFFFF8C42); // orange
  static const Color success = Color(0xFF34D399); // green (alias)
  static const Color info = Color(0xFF5B5FEF); // purple-blue (alias)

  // ── Surfaces ──
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color background = Color(0xFFF5F5F5); // light gray

  // ── Borders & Shadows ──
  static const Color border = Color(0xFF1A1A1A); // near-black
  static const Color shadow = Color(0xFF1A1A1A); // near-black

  // ── Typography ──
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Feature Accents ──
  static const Color study = Color(0xFF5B5FEF); // purple
  static const Color gym = Color(0xFFFF5D73); // pink
}

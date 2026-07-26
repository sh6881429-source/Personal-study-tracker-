import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ── String Extensions ──
extension StringExtension on String {
  /// Capitalizes the first letter: 'hello' → 'Hello'.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Validates basic email format.
  bool get isEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// True if the string contains non-whitespace characters.
  bool get isNotBlank => trim().isNotEmpty;
}

/// ── DateTime Extensions ──
extension DateTimeExtension on DateTime {
  /// Formatted date: 'Jul 10, 2026'.
  String get toFormattedDate => DateFormat('MMM dd, yyyy').format(this);

  /// Formatted time: '02:30 PM'.
  String get toFormattedTime => DateFormat('hh:mm a').format(this);

  /// Human-readable relative time: 'Just now', '5 minutes ago', 'Yesterday', etc.
  String get toRelative {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (isYesterday) return 'Yesterday';
    return toFormattedDate;
  }

  /// True if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// True if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

/// ── Duration Extensions ──
extension DurationExtension on Duration {
  /// Compact hours-and-minutes: '2h 30m'. Shows only minutes if < 1 hour.
  String get toHoursMinutes {
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  /// Timer format: '02:30:15'.
  String get toTimer {
    final h = inHours.toString().padLeft(2, '0');
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// ── BuildContext Extensions ──
extension BuildContextExtension on BuildContext {
  /// Screen width via MediaQuery.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height via MediaQuery.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Convenience to show a simple text snackbar.
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// ── Num Extensions ──
extension NumExtension on num {
  /// Creates a horizontal SizedBox spacer.
  SizedBox get toHorizontalSpace => SizedBox(width: toDouble());

  /// Creates a vertical SizedBox spacer.
  SizedBox get toVerticalSpace => SizedBox(height: toDouble());
}

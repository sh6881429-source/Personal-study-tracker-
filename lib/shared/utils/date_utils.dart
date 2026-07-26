import 'package:intl/intl.dart';

/// ── Date & Time Utility Helpers ──
abstract final class AppDateUtils {
  /// Returns the day names of the current week (e.g. M, T, W, Th, F, S, Su or Mon, Tue...)
  static List<String> getWeekDays() {
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  }

  /// Returns the start date of the week containing the given date (Monday).
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Returns the end date of the week containing the given date (Sunday).
  static DateTime getEndOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  /// Checks if two DateTimes fall on the same day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if a date is today.
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Format a duration (e.g. 75 minutes -> "1h 15m").
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format a duration in timer format (e.g. "00:45:12").
  static String formatTimer(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  /// Returns the month name from a given month index (1-12).
  static String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(2026, month));
  }

  /// Returns the day name (e.g., Monday).
  static String getDayName(DateTime date) {
    return DateFormat.EEEE().format(date);
  }
}

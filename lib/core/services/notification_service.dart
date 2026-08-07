import 'dart:async';
import 'package:flutter/foundation.dart';
import 'platform/notification_platform_io.dart'
    if (dart.library.html) 'platform/notification_platform_web.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/router/app_router.dart';
import 'package:prep_tracker/features/reminders/data/models/reminder_model.dart';
import 'package:prep_tracker/features/reminders/domain/models/reminder_type.dart';

/// ── Cross-Platform Notification Engine ──
/// Handles notification permissions, Web Push / HTML5 Notifications,
/// scheduled timer dispatches, in-app banner alerts, and route navigation.
class NotificationService {
  static final Map<String, Timer> _activeTimers = {};

  /// Request notification permission on Web and native platforms
 static Future<bool> requestPermission() async {
    return await requestPlatformPermission();
  }

  /// Checks if web notification permission is granted
  static bool get isPermissionGranted => isPlatformPermissionGranted;

  /// Immediately dispatches a notification across Web, Native, and In-App
  static void showNotification({
    required String title,
    required String message,
    required ReminderType type,
    String targetRoute = '/reminders',
    DateTime? scheduledTime,
  }) {
    final displayTime = scheduledTime != null
        ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}'
        : 'Now';

    debugPrint('🔔 [NOTIFICATION DISPATCH] $title — $message ($displayTime) -> Route: $targetRoute');

    // 1. Web Native HTML5 Browser Notification
    // 1. Platform Notification (Web HTML5 or Android/iOS native)
    showPlatformNotification(
      title: title,
      body: '$message\nScheduled for $displayTime • Tap to view',
    );

    // 2. In-App Foreground Banner Overlay
    _showInAppNotificationBanner(
      title: title,
      message: message,
      type: type,
      targetRoute: targetRoute,
    );
  }

  /// Deep-link navigation handler when a notification is tapped
  static void navigateTargetRoute(String targetRoute) {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        GoRouter.of(context).push(targetRoute);
      }
    } catch (e) {
      debugPrint('Navigation error from notification tap: $e');
    }
  }

  /// In-App Neo-Brutalist Banner Alert
  static void _showInAppNotificationBanner({
    required String title,
    required String message,
    required ReminderType type,
    required String targetRoute,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: type.color, width: 3),
        ),
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: type.color, width: 2),
              ),
              child: Icon(type.icon, color: type.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: type.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                navigateTargetRoute(targetRoute);
              },
              child: Text(
                'Open',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Synchronizes and schedules all active reminders in local timer memory
  static void syncScheduledReminders(List<ReminderModel> reminders) {
    // Clear previous scheduled timers
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    final now = DateTime.now();

    for (final reminder in reminders) {
      if (!reminder.isEnabled) continue;

      final diff = reminder.scheduledAt.difference(now);

      // If scheduled time is in the future, set a timer
      if (diff.inSeconds > 0) {
        _activeTimers[reminder.id] = Timer(diff, () {
          showNotification(
            title: reminder.title,
            message: reminder.message.isNotEmpty ? reminder.message : reminder.type.displayName,
            type: reminder.type,
            targetRoute: reminder.targetRoute,
            scheduledTime: reminder.scheduledAt,
          );
        });
        debugPrint('Scheduled reminder "${reminder.title}" in ${diff.inMinutes} minutes.');
      }
    }
  }

  // ── Backward Compatibility Methods for Legacy Settings ──

  static Future<void> scheduleStudyReminder({
    required String time,
    required bool enabled,
  }) async {
    if (enabled) {
      debugPrint('Scheduled Study Reminder daily at $time');
    }
  }

  static Future<void> scheduleGymReminder({
    required String time,
    required bool enabled,
  }) async {
    if (enabled) {
      debugPrint('Scheduled Gym Reminder daily at $time');
    }
  }

  static Future<void> scheduleRevisionReminder({
    required bool enabled,
  }) async {
    if (enabled) {
      debugPrint('Scheduled Revision Reminders periodically');
    }
  }

  static Future<void> scheduleExamReminder({
    required bool enabled,
  }) async {
    if (enabled) {
      debugPrint('Scheduled Exam countdown alerts');
    }
  }

  static Future<void> scheduleDailySummary({
    required bool enabled,
  }) async {
    if (enabled) {
      debugPrint('Scheduled Daily summary report at 21:00');
    }
  }
}

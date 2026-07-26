import 'package:flutter/material.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';

/// ── Reminder Types ──
/// Supported reminder categories across the PrepTracker ecosystem.
enum ReminderType {
  study,
  revision,
  gym,
  exam,
  summary,
  custom,
}

extension ReminderTypeExtension on ReminderType {
  String get id {
    switch (this) {
      case ReminderType.study:
        return 'study';
      case ReminderType.revision:
        return 'revision';
      case ReminderType.gym:
        return 'gym';
      case ReminderType.exam:
        return 'exam';
      case ReminderType.summary:
        return 'summary';
      case ReminderType.custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case ReminderType.study:
        return 'Study Focus';
      case ReminderType.revision:
        return 'Syllabus Revision';
      case ReminderType.gym:
        return 'Gym & Workout';
      case ReminderType.exam:
        return 'Exam Countdown';
      case ReminderType.summary:
        return 'Daily Summary';
      case ReminderType.custom:
        return 'Custom Reminder';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderType.study:
        return Icons.menu_book_rounded;
      case ReminderType.revision:
        return Icons.checklist_rounded;
      case ReminderType.gym:
        return Icons.fitness_center_rounded;
      case ReminderType.exam:
        return Icons.assignment_late_rounded;
      case ReminderType.summary:
        return Icons.insights_rounded;
      case ReminderType.custom:
        return Icons.alarm_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ReminderType.study:
        return AppColors.primary; // #5B5FEF
      case ReminderType.revision:
        return const Color(0xFF0EA5E9); // Sky Blue
      case ReminderType.gym:
        return AppColors.error; // #FF5D73
      case ReminderType.exam:
        return const Color(0xFFF59E0B); // Amber
      case ReminderType.summary:
        return AppColors.secondary; // #34D399
      case ReminderType.custom:
        return const Color(0xFFA855F7); // Purple
    }
  }

  String get defaultTargetRoute {
    switch (this) {
      case ReminderType.study:
        return '/study';
      case ReminderType.revision:
        return '/syllabus';
      case ReminderType.gym:
        return '/gym';
      case ReminderType.exam:
        return '/syllabus';
      case ReminderType.summary:
        return '/analytics';
      case ReminderType.custom:
        return '/reminders';
    }
  }

  static ReminderType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'study':
        return ReminderType.study;
      case 'revision':
        return ReminderType.revision;
      case 'gym':
        return ReminderType.gym;
      case 'exam':
        return ReminderType.exam;
      case 'summary':
        return ReminderType.summary;
      case 'custom':
      default:
        return ReminderType.custom;
    }
  }
}

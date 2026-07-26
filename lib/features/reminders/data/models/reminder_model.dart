import 'package:flutter/foundation.dart';
import 'package:prep_tracker/features/reminders/domain/models/reminder_type.dart';

/// ── Reminder Model ──
/// Immutable data model representing a user reminder.
@immutable
class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.targetRoute,
    required this.scheduledAt,
    this.isEnabled = true,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String? ?? '',
      type: ReminderTypeExtension.fromString(json['type'] as String? ?? 'custom'),
      targetRoute: json['target_route'] as String? ?? '/reminders',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      isEnabled: json['is_enabled'] as bool? ?? true,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  final String id;
  final String userId;
  final String title;
  final String message;
  final ReminderType type;
  final String targetRoute;
  final DateTime scheduledAt;
  final bool isEnabled;
  final bool isRecurring;
  final String? recurrencePattern;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.id,
      'target_route': targetRoute,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'is_enabled': isEnabled,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    ReminderType? type,
    String? targetRoute,
    DateTime? scheduledAt,
    bool? isEnabled,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetRoute: targetRoute ?? this.targetRoute,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isEnabled: isEnabled ?? this.isEnabled,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.targetRoute == targetRoute &&
        other.scheduledAt == scheduledAt &&
        other.isEnabled == isEnabled &&
        other.isRecurring == isRecurring &&
        other.recurrencePattern == recurrencePattern &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      message,
      type,
      targetRoute,
      scheduledAt,
      isEnabled,
      isRecurring,
      recurrencePattern,
      createdAt,
      updatedAt,
    );
  }
}

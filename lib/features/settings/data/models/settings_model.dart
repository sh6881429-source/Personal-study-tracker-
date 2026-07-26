import 'package:flutter/foundation.dart';

@immutable
class UserSettingsModel {
  const UserSettingsModel({
    required this.id,
    required this.userId,
    this.themeMode = 'system',
    this.notificationEnabled = true,
    this.studyReminderTime = '09:00',
    this.gymReminderTime = '17:00',
    this.defaultRevisionTarget = 3,
    this.language = 'en',
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      themeMode: json['theme_mode'] as String,
      notificationEnabled: json['notification_enabled'] as bool,
      studyReminderTime: json['study_reminder_time'] as String,
      gymReminderTime: json['gym_reminder_time'] as String,
      defaultRevisionTarget: json['default_revision_target'] as int,
      language: json['language'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String themeMode; // light, dark, system
  final bool notificationEnabled;
  final String studyReminderTime;
  final String gymReminderTime;
  final int defaultRevisionTarget;
  final String language;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'theme_mode': themeMode,
      'notification_enabled': notificationEnabled,
      'study_reminder_time': studyReminderTime,
      'gym_reminder_time': gymReminderTime,
      'default_revision_target': defaultRevisionTarget,
      'language': language,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserSettingsModel copyWith({
    String? id,
    String? userId,
    String? themeMode,
    bool? notificationEnabled,
    String? studyReminderTime,
    String? gymReminderTime,
    int? defaultRevisionTarget,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      studyReminderTime: studyReminderTime ?? this.studyReminderTime,
      gymReminderTime: gymReminderTime ?? this.gymReminderTime,
      defaultRevisionTarget: defaultRevisionTarget ?? this.defaultRevisionTarget,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettingsModel &&
        other.id == id &&
        other.userId == userId &&
        other.themeMode == themeMode &&
        other.notificationEnabled == notificationEnabled &&
        other.studyReminderTime == studyReminderTime &&
        other.gymReminderTime == gymReminderTime &&
        other.defaultRevisionTarget == defaultRevisionTarget &&
        other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      themeMode,
      notificationEnabled,
      studyReminderTime,
      gymReminderTime,
      defaultRevisionTarget,
      language,
    );
  }
}

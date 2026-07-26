import 'package:flutter/foundation.dart';

@immutable
class StudyGoalModel {
  const StudyGoalModel({
    required this.id,
    required this.userId,
    this.dailyGoalMinutes = 360, // Default 6 hours
    this.weeklyGoalMinutes = 2520, // Default 42 hours
    this.monthlyGoalMinutes = 10800, // Default 180 hours
    this.createdAt,
    this.updatedAt,
  });

  factory StudyGoalModel.fromJson(Map<String, dynamic> json) {
    return StudyGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyGoalMinutes: json['daily_goal_minutes'] as int? ?? 360,
      weeklyGoalMinutes: json['weekly_goal_minutes'] as int? ?? 2520,
      monthlyGoalMinutes: json['monthly_goal_minutes'] as int? ?? 10800,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final int dailyGoalMinutes;
  final int weeklyGoalMinutes;
  final int monthlyGoalMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get dailyGoalHours => dailyGoalMinutes / 60.0;
  double get weeklyGoalHours => weeklyGoalMinutes / 60.0;
  double get monthlyGoalHours => monthlyGoalMinutes / 60.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_goal_minutes': dailyGoalMinutes,
      'weekly_goal_minutes': weeklyGoalMinutes,
      'monthly_goal_minutes': monthlyGoalMinutes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudyGoalModel copyWith({
    String? id,
    String? userId,
    int? dailyGoalMinutes,
    int? weeklyGoalMinutes,
    int? monthlyGoalMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      monthlyGoalMinutes: monthlyGoalMinutes ?? this.monthlyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudyGoalModel &&
        other.id == id &&
        other.userId == userId &&
        other.dailyGoalMinutes == dailyGoalMinutes &&
        other.weeklyGoalMinutes == weeklyGoalMinutes &&
        other.monthlyGoalMinutes == monthlyGoalMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      dailyGoalMinutes,
      weeklyGoalMinutes,
      monthlyGoalMinutes,
    );
  }
}

import 'package:flutter/foundation.dart';

@immutable
class DailyGoalModel {
  const DailyGoalModel({
    required this.id,
    required this.userId,
    this.studyGoalMinutes = 120,
    this.targetChapters = 1,
    this.targetRevisions = 1,
    this.waterGoal = 8,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyGoalModel.fromJson(Map<String, dynamic> json) {
    return DailyGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      studyGoalMinutes: json['study_goal_minutes'] as int,
      targetChapters: json['target_chapters'] as int,
      targetRevisions: json['target_revisions'] as int,
      waterGoal: json['water_goal'] as int,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final int studyGoalMinutes;
  final int targetChapters;
  final int targetRevisions;
  final int waterGoal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'study_goal_minutes': studyGoalMinutes,
      'target_chapters': targetChapters,
      'target_revisions': targetRevisions,
      'water_goal': waterGoal,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  DailyGoalModel copyWith({
    String? id,
    String? userId,
    int? studyGoalMinutes,
    int? targetChapters,
    int? targetRevisions,
    int? waterGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studyGoalMinutes: studyGoalMinutes ?? this.studyGoalMinutes,
      targetChapters: targetChapters ?? this.targetChapters,
      targetRevisions: targetRevisions ?? this.targetRevisions,
      waterGoal: waterGoal ?? this.waterGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyGoalModel &&
        other.id == id &&
        other.userId == userId &&
        other.studyGoalMinutes == studyGoalMinutes &&
        other.targetChapters == targetChapters &&
        other.targetRevisions == targetRevisions &&
        other.waterGoal == waterGoal;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      studyGoalMinutes,
      targetChapters,
      targetRevisions,
      waterGoal,
    );
  }
}

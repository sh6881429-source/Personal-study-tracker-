import 'package:flutter/foundation.dart';

@immutable
class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.userId,
    required this.achievementName,
    required this.description,
    this.earned = false,
    this.earnedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementName: json['achievement_name'] as String,
      description: json['description'] as String,
      earned: json['earned'] as bool,
      earnedDate: json['earned_date'] != null ? DateTime.parse(json['earned_date'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String achievementName;
  final String description;
  final bool earned;
  final DateTime? earnedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_name': achievementName,
      'description': description,
      'earned': earned,
      'earned_date': earnedDate?.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  AchievementModel copyWith({
    String? id,
    String? userId,
    String? achievementName,
    String? description,
    bool? earned,
    DateTime? earnedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementName: achievementName ?? this.achievementName,
      description: description ?? this.description,
      earned: earned ?? this.earned,
      earnedDate: earnedDate ?? this.earnedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementModel &&
        other.id == id &&
        other.userId == userId &&
        other.achievementName == achievementName &&
        other.description == description &&
        other.earned == earned &&
        other.earnedDate == earnedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      achievementName,
      description,
      earned,
      earnedDate,
    );
  }
}

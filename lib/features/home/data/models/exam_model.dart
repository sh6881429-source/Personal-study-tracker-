import 'package:flutter/foundation.dart';

@immutable
class ExamModel {
  const ExamModel({
    required this.id,
    required this.userId,
    required this.examName,
    required this.examDate,
    this.targetScore,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      examName: json['exam_name'] as String,
      examDate: DateTime.parse(json['exam_date'] as String),
      targetScore: json['target_score'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String examName;
  final DateTime examDate;
  final String? targetScore;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exam_name': examName,
      'exam_date': examDate.toIso8601String(),
      'target_score': targetScore,
      'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ExamModel copyWith({
    String? id,
    String? userId,
    String? examName,
    DateTime? examDate,
    String? targetScore,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examName: examName ?? this.examName,
      examDate: examDate ?? this.examDate,
      targetScore: targetScore ?? this.targetScore,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamModel &&
        other.id == id &&
        other.userId == userId &&
        other.examName == examName &&
        other.examDate == examDate &&
        other.targetScore == targetScore &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      examName,
      examDate,
      targetScore,
      description,
    );
  }
}

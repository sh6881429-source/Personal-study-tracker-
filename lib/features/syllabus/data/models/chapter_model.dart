import 'package:flutter/foundation.dart';

@immutable
class ChapterModel {
  const ChapterModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.chapterName,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    this.targetRevisions = 1,
    this.currentRevisions = 0,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      chapterName: json['chapter_name'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      targetRevisions: json['target_revisions'] as int,
      currentRevisions: json['current_revisions'] as int,
      displayOrder: json['display_order'] as int,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String subjectId;
  final String chapterName;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final int targetRevisions;
  final int currentRevisions;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'chapter_name': chapterName,
      'description': description,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'target_revisions': targetRevisions,
      'current_revisions': currentRevisions,
      'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ChapterModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? chapterName,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    int? targetRevisions,
    int? currentRevisions,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      chapterName: chapterName ?? this.chapterName,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      targetRevisions: targetRevisions ?? this.targetRevisions,
      currentRevisions: currentRevisions ?? this.currentRevisions,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterModel &&
        other.id == id &&
        other.userId == userId &&
        other.subjectId == subjectId &&
        other.chapterName == chapterName &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.completedAt == completedAt &&
        other.targetRevisions == targetRevisions &&
        other.currentRevisions == currentRevisions &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      subjectId,
      chapterName,
      description,
      isCompleted,
      completedAt,
      targetRevisions,
      currentRevisions,
      displayOrder,
    );
  }
}

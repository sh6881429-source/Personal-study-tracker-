import 'package:flutter/foundation.dart';

@immutable
class BookmarkModel {
  const BookmarkModel({
    required this.id,
    required this.userId,
    this.subjectId,
    this.chapterId,
    required this.title,
    this.description,
    this.priority = 'Medium',
    this.isCompleted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.reminderDate,
    this.createdAt,
    this.updatedAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      chapterId: json['chapter_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String,
      isCompleted: json['is_completed'] as bool,
      isPinned: json['is_pinned'] as bool,
      isArchived: json['is_archived'] as bool? ?? false,
      reminderDate: json['reminder_date'] != null ? DateTime.parse(json['reminder_date'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String? subjectId;
  final String? chapterId;
  final String title;
  final String? description;
  final String priority;
  final bool isCompleted;
  final bool isPinned;
  final bool isArchived;
  final DateTime? reminderDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (subjectId != null) 'subject_id': subjectId,
      if (chapterId != null) 'chapter_id': chapterId,
      'title': title,
      'description': description,
      'priority': priority,
      'is_completed': isCompleted,
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'reminder_date': reminderDate?.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  BookmarkModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? chapterId,
    String? title,
    String? description,
    String? priority,
    bool? isCompleted,
    bool? isPinned,
    bool? isArchived,
    DateTime? reminderDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      reminderDate: reminderDate ?? this.reminderDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkModel &&
        other.id == id &&
        other.userId == userId &&
        other.subjectId == subjectId &&
        other.chapterId == chapterId &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.isCompleted == isCompleted &&
        other.isPinned == isPinned &&
        other.isArchived == isArchived &&
        other.reminderDate == reminderDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      subjectId,
      chapterId,
      title,
      description,
      priority,
      isCompleted,
      isPinned,
      isArchived,
      reminderDate,
    );
  }
}

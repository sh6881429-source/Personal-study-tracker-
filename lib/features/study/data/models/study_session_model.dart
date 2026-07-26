import 'package:flutter/foundation.dart';

@immutable
class StudySessionModel {
  const StudySessionModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    this.chapterId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.sessionNotes,
    required this.sessionType,
    required this.studyDate,
    this.createdAt,
    this.updatedAt,
  });

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      chapterId: json['chapter_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      durationMinutes: json['duration_minutes'] as int,
      sessionNotes: json['session_notes'] as String?,
      sessionType: json['session_type'] as String? ?? 'Normal Study',
      studyDate: DateTime.parse(json['study_date'] as String),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String subjectId;
  final String? chapterId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String? sessionNotes;
  final String sessionType;
  final DateTime studyDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      if (chapterId != null) 'chapter_id': chapterId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'session_notes': sessionNotes,
      'session_type': sessionType,
      'study_date': studyDate.toIso8601String().substring(0, 10), // Date format YYYY-MM-DD
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StudySessionModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? chapterId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? sessionNotes,
    String? sessionType,
    DateTime? studyDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      sessionType: sessionType ?? this.sessionType,
      studyDate: studyDate ?? this.studyDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudySessionModel &&
        other.id == id &&
        other.userId == userId &&
        other.subjectId == subjectId &&
        other.chapterId == chapterId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.durationMinutes == durationMinutes &&
        other.sessionNotes == sessionNotes &&
        other.sessionType == sessionType &&
        other.studyDate == studyDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      subjectId,
      chapterId,
      startTime,
      endTime,
      durationMinutes,
      sessionNotes,
      sessionType,
      studyDate,
    );
  }
}

import 'package:flutter/foundation.dart';

@immutable
class GymAttendanceModel {
  const GymAttendanceModel({
    required this.id,
    required this.userId,
    required this.attendanceDate,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory GymAttendanceModel.fromJson(Map<String, dynamic> json) {
    return GymAttendanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      attendanceDate: DateTime.parse(json['attendance_date'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final DateTime attendanceDate;
  final String status; // Present, Absent, Rest Day
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'attendance_date': attendanceDate.toIso8601String().substring(0, 10), // Date format YYYY-MM-DD
      'status': status,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  GymAttendanceModel copyWith({
    String? id,
    String? userId,
    DateTime? attendanceDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymAttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GymAttendanceModel &&
        other.id == id &&
        other.userId == userId &&
        other.attendanceDate == attendanceDate &&
        other.status == status &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, attendanceDate, status, notes);
  }
}

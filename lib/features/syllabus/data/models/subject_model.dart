import 'package:flutter/foundation.dart';

@immutable
class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.userId,
    required this.subjectName,
    this.description,
    required this.color,
    required this.icon,
    this.displayOrder = 0,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectName: json['subject_name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      icon: json['icon'] as String,
      displayOrder: json['display_order'] as int,
      isArchived: json['is_archived'] as bool,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String subjectName;
  final String? description;
  final String color;
  final String icon;
  final int displayOrder;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_name': subjectName,
      'description': description,
      'color': color,
      'icon': icon,
      'display_order': displayOrder,
      'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  SubjectModel copyWith({
    String? id,
    String? userId,
    String? subjectName,
    String? description,
    String? color,
    String? icon,
    int? displayOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectName: subjectName ?? this.subjectName,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubjectModel &&
        other.id == id &&
        other.userId == userId &&
        other.subjectName == subjectName &&
        other.description == description &&
        other.color == color &&
        other.icon == icon &&
        other.displayOrder == displayOrder &&
        other.isArchived == isArchived;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, subjectName, description, color, icon, displayOrder, isArchived);
  }
}

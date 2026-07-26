import 'package:flutter/foundation.dart';

@immutable
class PdfModel {
  const PdfModel({
    required this.id,
    required this.userId,
    this.subjectId,
    required this.fileName,
    required this.originalName,
    required this.storagePath,
    required this.fileSize,
    this.pageCount,
    this.isFavorite = false,
    this.description,
    this.lastOpened,
    this.createdAt,
    this.updatedAt,
  });

  factory PdfModel.fromJson(Map<String, dynamic> json) {
    return PdfModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String?,
      fileName: json['file_name'] as String,
      originalName: json['original_name'] as String,
      storagePath: json['storage_path'] as String,
      fileSize: json['file_size'] as int,
      pageCount: json['page_count'] as int?,
      isFavorite: json['is_favorite'] as bool,
      description: json['description'] as String?,
      lastOpened: json['last_opened'] != null ? DateTime.parse(json['last_opened'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String? subjectId;
  final String fileName;
  final String originalName;
  final String storagePath;
  final int fileSize;
  final int? pageCount;
  final bool isFavorite;
  final String? description;
  final DateTime? lastOpened;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (subjectId != null) 'subject_id': subjectId,
      'file_name': fileName,
      'original_name': originalName,
      'storage_path': storagePath,
      'file_size': fileSize,
      if (pageCount != null) 'page_count': pageCount,
      'is_favorite': isFavorite,
      'description': description,
      'last_opened': lastOpened?.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PdfModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? fileName,
    String? originalName,
    String? storagePath,
    int? fileSize,
    int? pageCount,
    bool? isFavorite,
    String? description,
    DateTime? lastOpened,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PdfModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      lastOpened: lastOpened ?? this.lastOpened,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfModel &&
        other.id == id &&
        other.userId == userId &&
        other.subjectId == subjectId &&
        other.fileName == fileName &&
        other.originalName == originalName &&
        other.storagePath == storagePath &&
        other.fileSize == fileSize &&
        other.pageCount == pageCount &&
        other.description == description &&
        other.lastOpened == lastOpened &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      subjectId,
      fileName,
      originalName,
      storagePath,
      fileSize,
      pageCount,
      description,
      lastOpened,
      isFavorite,
    );
  }
}

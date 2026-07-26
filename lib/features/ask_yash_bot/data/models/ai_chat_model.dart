import 'package:flutter/foundation.dart';

@immutable
class AiChatModel {
  const AiChatModel({
    required this.id,
    required this.userId,
    required this.question,
    required this.response,
    this.createdAt,
    this.updatedAt,
  });

  factory AiChatModel.fromJson(Map<String, dynamic> json) {
    return AiChatModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      question: json['question'] as String,
      response: json['response'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String id;
  final String userId;
  final String question;
  final String response;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question': question,
      'response': response,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  AiChatModel copyWith({
    String? id,
    String? userId,
    String? question,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiChatModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      question: question ?? this.question,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiChatModel &&
        other.id == id &&
        other.userId == userId &&
        other.question == question &&
        other.response == response;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, question, response);
  }
}

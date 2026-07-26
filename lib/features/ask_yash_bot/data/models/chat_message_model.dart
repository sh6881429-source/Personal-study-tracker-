import 'package:flutter/foundation.dart';

enum MessageRole { user, assistant, system }

class ChatMessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? pdfName;
  final String? pdfTextSnippet;
  final bool isError;
  final bool isStreaming;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.pdfName,
    this.pdfTextSnippet,
    this.isError = false,
    this.isStreaming = false,
  });

  ChatMessageModel copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    String? pdfName,
    String? pdfTextSnippet,
    bool? isError,
    bool? isStreaming,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      pdfName: pdfName ?? this.pdfName,
      pdfTextSnippet: pdfTextSnippet ?? this.pdfTextSnippet,
      isError: isError ?? this.isError,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'pdfName': pdfName,
      'pdfTextSnippet': pdfTextSnippet,
      'isError': isError,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      role: MessageRole.values.firstWhere(
        (r) => r.name == (json['role'] as String?),
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      pdfName: json['pdfName'] as String?,
      pdfTextSnippet: json['pdfTextSnippet'] as String?,
      isError: json['isError'] as bool? ?? false,
    );
  }
}

class ChatSessionModel {
  final String id;
  final String userId;
  final String title;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessageModel> messages;

  ChatSessionModel({
    required this.id,
    required this.userId,
    required this.title,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  ChatSessionModel copyWith({
    String? id,
    String? userId,
    String? title,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessageModel>? messages,
  }) {
    return ChatSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    List<ChatMessageModel> msgs = [];
    if (json['messages'] != null && json['messages'] is List) {
      msgs = (json['messages'] as List)
          .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return ChatSessionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'New Conversation',
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      messages: msgs,
    );
  }
}

import 'package:flutter/foundation.dart';

/// ── Profile Model ──
/// Immutable model representing a user profile synced with Supabase.
@immutable
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    this.username,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
  });

  /// Map JSON to ProfileModel
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photo_url'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLogin: DateTime.parse(json['last_login'] as String),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final String? username;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLogin;

  /// Convert ProfileModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'username': username,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  ProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? photoUrl,
    String? username,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.username == username &&
        other.bio == bio &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLogin == lastLogin;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      email,
      photoUrl,
      username,
      bio,
      createdAt,
      updatedAt,
      lastLogin,
    );
  }
}

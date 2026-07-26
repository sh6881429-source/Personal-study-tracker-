import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/features/profile/data/models/profile_model.dart';
import 'package:prep_tracker/features/profile/data/services/profile_service.dart';
import 'package:prep_tracker/features/profile/domain/repositories/profile_repository.dart';

/// Provider for ProfileService.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Provider for ProfileRepository implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileRepositoryImpl(service);
});

/// ── Profile Repository Implementation ──
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._service);

  final ProfileService _service;

  @override
  Future<ProfileModel?> getProfile(String userId) async {
    final row = await _service.fetchProfileRow(userId);
    if (row == null) return null;
    return ProfileModel.fromJson(row);
  }

  @override
  Future<ProfileModel> createProfile(ProfileModel profile) async {
    final row = await _service.insertProfileRow(profile.toJson());
    return ProfileModel.fromJson(row);
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final row = await _service.updateProfileRow(profile.userId, profile.toJson());
    return ProfileModel.fromJson(row);
  }

  @override
  Future<ProfileModel> syncProfile({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final existing = await getProfile(userId);
    final now = DateTime.now();

    if (existing == null) {
      // First login: create a new profile row — use Google avatar as default
      final newProfile = ProfileModel(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        email: email,
        photoUrl: photoUrl,
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      );
      return createProfile(newProfile);
    } else {
      // Returning user: preserve the user's custom photo_url from the DB.
      // Only update name/email/lastLogin — never overwrite their uploaded avatar.
      final updated = existing.copyWith(
        name: existing.name.isNotEmpty ? existing.name : name,
        email: email,
        lastLogin: now,
        updatedAt: now,
      );
      return updateProfile(updated);
    }
  }
}

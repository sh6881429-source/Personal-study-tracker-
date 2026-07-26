import 'package:prep_tracker/features/profile/data/models/profile_model.dart';

/// ── Profile Repository Interface ──
/// Defines contract for syncing and retrieving user profiles.
abstract interface class ProfileRepository {
  /// Fetches a user profile by Supabase user ID.
  Future<ProfileModel?> getProfile(String userId);

  /// Creates a new user profile.
  Future<ProfileModel> createProfile(ProfileModel profile);

  /// Updates an existing profile's details (e.g. last login timestamp).
  Future<ProfileModel> updateProfile(ProfileModel profile);

  /// Synchronizes user information from auth session to the profiles database table.
  /// Inserts a new row if first login, otherwise updates last login.
  Future<ProfileModel> syncProfile({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
  });
}

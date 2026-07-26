import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';

/// ── Production Profile Service ──
/// Robust service for profiles database operations and Supabase Storage uploads.
class ProfileService {
  SupabaseClient get _client => SupabaseService.client;
  static const String bucketName = 'profile-images';

  /// Supported image file extensions
  static const Set<String> supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Fetches raw JSON row from `profiles` table matching [userId].
  Future<Map<String, dynamic>?> fetchProfileRow(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      debugPrint('❌ [ProfileService] fetchProfileRow Postgrest error: ${e.message}');
      throw Exception('Postgrest query failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ [ProfileService] fetchProfileRow error: $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Inserts a new JSON profile row into `profiles` table.
  Future<Map<String, dynamic>> insertProfileRow(Map<String, dynamic> row) async {
    try {
      final response = await _client
          .from('profiles')
          .insert(row)
          .select()
          .single();
      return response;
    } on PostgrestException catch (e) {
      debugPrint('❌ [ProfileService] insertProfileRow Postgrest error: ${e.message}');
      throw Exception('Failed to insert profile row: ${e.message}');
    } catch (e) {
      debugPrint('❌ [ProfileService] insertProfileRow error: $e');
      throw Exception('Failed to create profile row: $e');
    }
  }

  /// Updates an existing profile row in `profiles` table.
  Future<Map<String, dynamic>> updateProfileRow(
    String userId,
    Map<String, dynamic> row,
  ) async {
    try {
      debugPrint('🔄 [ProfileService] Updating DB row for user: $userId with data: $row');
      final response = await _client
          .from('profiles')
          .update(row)
          .eq('user_id', userId)
          .select()
          .single();
      debugPrint('✅ [ProfileService] DB row update success for $userId');
      return response;
    } on PostgrestException catch (e) {
      debugPrint('❌ [ProfileService] updateProfileRow Postgrest error: ${e.message}');
      throw Exception('Failed to update profile row: ${e.message}');
    } catch (e) {
      debugPrint('❌ [ProfileService] updateProfileRow error: $e');
      throw Exception('Failed to update profile row: $e');
    }
  }

  /// Maps file extension to strict MIME content type.
  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  /// Deletes all existing files in `users/{userId}/` folder to avoid orphan files.
  Future<void> deleteOldAvatars(String userId) async {
    try {
      debugPrint('🧹 [ProfileService] Cleaning old avatars for user: $userId');
      final files = await _client.storage.from(bucketName).list(path: 'users/$userId');
      if (files.isNotEmpty) {
        final filePaths = files.map((f) => 'users/$userId/${f.name}').toList();
        await _client.storage.from(bucketName).remove(filePaths);
        debugPrint('✅ [ProfileService] Deleted old files: $filePaths');
      }
    } catch (e) {
      debugPrint('⚠️ [ProfileService] Delete old avatars warning (non-fatal): $e');
      // Fallback cleanup attempt on legacy avatars bucket
      try {
        final legacyFiles = await _client.storage.from('avatars').list(path: 'users/$userId');
        if (legacyFiles.isNotEmpty) {
          final paths = legacyFiles.map((f) => 'users/$userId/${f.name}').toList();
          await _client.storage.from('avatars').remove(paths);
        }
      } catch (_) {}
    }
  }

  /// Uploads avatar image bytes to Supabase Storage bucket.
  /// Standard path: `users/{userId}/avatar_{timestamp}.{ext}`
  Future<String> uploadAvatar(String userId, Uint8List bytes, String fileExt) async {
    final ext = fileExt.toLowerCase().replaceAll('.', '');
    
    // Step 4: Validate extension
    if (!supportedExtensions.contains(ext)) {
      throw Exception('Unsupported image format ".$ext". Supported formats: JPG, PNG, WEBP.');
    }

    // Step 11: Delete old avatar files first
    await deleteOldAvatars(userId);

    // Step 3: Structured filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'users/$userId/avatar_$timestamp.$ext';
    final mime = _mimeType(ext);

    debugPrint('📤 [ProfileService] Uploading avatar bytes (${bytes.length} bytes) to path: $storagePath (MIME: $mime)');

    try {
      // Step 5: Upload via Supabase Storage
      await _client.storage.from(bucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mime,
              upsert: true,
            ),
          );

      // Step 6: Retrieve public URL + Step 9: Cache invalidation query parameter
      final baseUrl = _client.storage.from(bucketName).getPublicUrl(storagePath);
      final cacheBustUrl = '$baseUrl?t=$timestamp';
      debugPrint('✅ [ProfileService] Public URL generated: $cacheBustUrl');

      return cacheBustUrl;
    } catch (e) {
      debugPrint('❌ [ProfileService] Upload failed on $bucketName, trying fallback bucket: $e');
      // Fallback to 'avatars' bucket if 'profile-images' fails
      try {
        await _client.storage.from('avatars').uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(
                contentType: mime,
                upsert: true,
              ),
            );
        final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
        final cacheBustUrl = '$baseUrl?t=$timestamp';
        debugPrint('✅ [ProfileService] Fallback bucket upload success: $cacheBustUrl');
        return cacheBustUrl;
      } catch (fallbackErr) {
        debugPrint('❌ [ProfileService] Storage upload failed completely: $fallbackErr');
        throw Exception('Storage upload failed: $fallbackErr');
      }
    }
  }

  /// Removes profile picture from storage and resets `photo_url` in profiles table.
  Future<void> removeAvatar(String userId) async {
    debugPrint('🗑️ [ProfileService] Removing avatar for user: $userId');
    await deleteOldAvatars(userId);
    await updateProfileRow(userId, {
      'photo_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ [ProfileService] Avatar removed successfully for user: $userId');
  }
}

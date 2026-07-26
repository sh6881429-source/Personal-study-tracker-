import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';

/// ── Settings Database Service ──
/// Handles direct database transactions with Supabase `user_settings` table.
class SettingsService {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetches raw JSON row from `user_settings` table matching [userId].
  Future<Map<String, dynamic>?> fetchSettingsRow(String userId) async {
    try {
      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      throw Exception('Postgrest query failed: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch settings: $e');
    }
  }

  /// Inserts a new JSON settings row into `user_settings` table.
  Future<Map<String, dynamic>> insertSettingsRow(Map<String, dynamic> row) async {
    try {
      final response = await _client
          .from('user_settings')
          .insert(row)
          .select()
          .single();
      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to insert settings row: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create settings row: $e');
    }
  }

  /// Updates an existing settings row in `user_settings` table.
  Future<Map<String, dynamic>> updateSettingsRow(
    String userId,
    Map<String, dynamic> row,
  ) async {
    try {
      final response = await _client
          .from('user_settings')
          .update(row)
          .eq('user_id', userId)
          .select()
          .single();
      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to update settings row: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update settings row: $e');
    }
  }
}

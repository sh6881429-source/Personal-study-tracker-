import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/reminders/data/models/reminder_model.dart';

/// ── Reminder Database Service ──
/// Handles direct CRUD queries with Supabase `reminders` table.
class ReminderService {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetches all reminders for given [userId].
  Future<List<ReminderModel>> fetchReminders(String userId) async {
    try {
      final response = await _client
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .order('scheduled_at', ascending: true);

      final list = response as List<dynamic>;
      return list.map((json) => ReminderModel.fromJson(json as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch reminders: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load reminders: $e');
    }
  }

  /// Inserts a new reminder into Supabase `reminders` table.
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      final response = await _client
          .from('reminders')
          .insert(reminder.toJson())
          .select()
          .single();

      return ReminderModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create reminder: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save reminder: $e');
    }
  }

  /// Updates an existing reminder in Supabase `reminders` table.
  Future<ReminderModel> updateReminder(ReminderModel reminder) async {
    try {
      final response = await _client
          .from('reminders')
          .update(reminder.toJson())
          .eq('id', reminder.id)
          .eq('user_id', reminder.userId)
          .select()
          .single();

      return ReminderModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update reminder: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  /// Toggles `is_enabled` status for a reminder.
  Future<void> toggleReminder(String reminderId, String userId, bool isEnabled) async {
    try {
      await _client
          .from('reminders')
          .update({
            'is_enabled': isEnabled,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', reminderId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle reminder status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  /// Deletes a reminder from Supabase `reminders` table.
  Future<void> deleteReminder(String reminderId, String userId) async {
    try {
      await _client
          .from('reminders')
          .delete()
          .eq('id', reminderId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete reminder: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }
}

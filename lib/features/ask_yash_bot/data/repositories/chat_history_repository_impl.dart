import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/chat_message_model.dart';

const String _localChatSessionsKey = 'yash_bot_chat_sessions_v1';

class ChatHistoryRepositoryImpl {
  /// Loads all chat sessions for the current user (local + Supabase)
  static Future<List<ChatSessionModel>> loadSessions() async {
    final List<ChatSessionModel> localSessions = _loadLocalSessions();

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final dbResponse = await SupabaseService.client
            .from('ai_chat_history')
            .select()
            .eq('user_id', user.id)
            .order('updated_at', ascending: false);

        if (dbResponse is List && dbResponse.isNotEmpty) {
          final dbSessions = dbResponse.map((row) {
            final jsonMap = row as Map<String, dynamic>;
            return ChatSessionModel.fromJson(jsonMap);
          }).toList();

          // Merge db and local sessions cleanly
          final Map<String, ChatSessionModel> merged = {};
          for (var s in dbSessions) {
            merged[s.id] = s;
          }
          for (var s in localSessions) {
            if (!merged.containsKey(s.id) || s.updatedAt.isAfter(merged[s.id]!.updatedAt)) {
              merged[s.id] = s;
            }
          }
          final result = merged.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          await _saveLocalSessions(result);
          return result;
        }
      }
    } catch (e) {
      debugPrint('Supabase load ai_chat_history error: $e');
    }

    return localSessions;
  }

  /// Saves or updates a session locally and on Supabase
  static Future<void> saveSession(ChatSessionModel session) async {
    final sessions = _loadLocalSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }

    await _saveLocalSessions(sessions);

    // Sync to Supabase in background
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client.from('ai_chat_history').upsert({
          'id': session.id,
          'user_id': user.id,
          'question': session.messages.isNotEmpty ? session.messages.first.content : session.title,
          'response': session.messages.length > 1 ? session.messages.last.content : '',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Background Supabase ai_chat_history sync error: $e');
    }
  }

  /// Deletes a session
  static Future<void> deleteSession(String sessionId) async {
    final sessions = _loadLocalSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveLocalSessions(sessions);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client.from('ai_chat_history').delete().eq('id', sessionId);
      }
    } catch (_) {}
  }

  /// Toggles pinned status of a session
  static Future<void> togglePinSession(String sessionId) async {
    final sessions = _loadLocalSessions();
    final idx = sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      final updated = sessions[idx].copyWith(isPinned: !sessions[idx].isPinned);
      sessions[idx] = updated;
      await _saveLocalSessions(sessions);
    }
  }

  /// Renames a session
  static Future<void> renameSession(String sessionId, String newTitle) async {
    final sessions = _loadLocalSessions();
    final idx = sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      final updated = sessions[idx].copyWith(title: newTitle, updatedAt: DateTime.now());
      sessions[idx] = updated;
      await _saveLocalSessions(sessions);
    }
  }

  // ── Local Storage Helpers ──
  static List<ChatSessionModel> _loadLocalSessions() {
    try {
      final jsonStr = StorageService.getString(_localChatSessionsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        return list.map((item) => ChatSessionModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error reading local chat sessions: $e');
    }
    return [];
  }

  static Future<void> _saveLocalSessions(List<ChatSessionModel> sessions) async {
    try {
      final jsonStr = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await StorageService.setString(_localChatSessionsKey, jsonStr);
    } catch (e) {
      debugPrint('Error writing local chat sessions: $e');
    }
  }
}

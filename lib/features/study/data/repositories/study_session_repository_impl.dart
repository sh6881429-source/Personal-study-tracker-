import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/domain/repositories/study_session_repository.dart';

/// Provider for StudySessionRepository implementation.
final studySessionRepositoryProvider = Provider<StudySessionRepository>((ref) {
  return StudySessionRepositoryImpl();
});

/// ── Study Session Repository Implementation ──
/// Supports offline caching using StorageService (SharedPreferences) and real-time Supabase syncing.
class StudySessionRepositoryImpl implements StudySessionRepository {
  SupabaseClient get _supabase => SupabaseService.client;
  static const String _offlineKey = 'offline_study_sessions';

  @override
  Stream<List<StudySessionModel>> watchSessions(String userId, DateTime start, DateTime end) {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);

    return _supabase
        .from('study_sessions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
          final sessions = rows.map((row) => StudySessionModel.fromJson(row)).toList();
          return sessions.where((s) {
            final dateStr = s.studyDate.toIso8601String().substring(0, 10);
            return dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0;
          }).toList();
        });
  }

  @override
  Future<List<StudySessionModel>> getSessions(String userId) async {
    // Return combined network sessions and pending local offline sessions
    final localSessions = _getLocalOfflineSessions();
    try {
      final rows = await _supabase
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final networkSessions = rows.map((row) => StudySessionModel.fromJson(row)).toList();
      return [...localSessions, ...networkSessions];
    } catch (_) {
      return localSessions;
    }
  }

  @override
  Future<StudySessionModel> logSession(StudySessionModel session) async {
    try {
      // 1. Attempt upload to Supabase
      final response = await _supabase
          .from('study_sessions')
          .insert(session.toJson())
          .select()
          .single();

      // Try syncing any previously cached sessions since connection is healthy
      await syncOfflineSessions();

      return StudySessionModel.fromJson(response);
    } catch (e) {
      // 2. Offline Fallback: Cache locally in SharedPreferences
      final localList = _getLocalOfflineSessions();
      localList.add(session);
      await _saveLocalOfflineSessions(localList);
      return session;
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    // 1. Check if the session is in offline cache
    final localList = _getLocalOfflineSessions();
    final index = localList.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      localList.removeAt(index);
      await _saveLocalOfflineSessions(localList);
      return;
    }

    // 2. Otherwise delete from Supabase
    await _supabase.from('study_sessions').delete().eq('id', sessionId);
  }

  @override
  Future<double> getStudyHours(String userId, DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);

    try {
      final double hours = await _supabase.rpc(
        'calculate_study_hours',
        params: {
          'user_id_param': userId,
          'start_date': startStr,
          'end_date': endStr,
        },
      );
      return hours;
    } catch (_) {
      // Fallback: sum duration locally
      final sessions = await getSessions(userId);
      final double localSum = sessions
          .where((s) {
            final dateStr = s.studyDate.toIso8601String().substring(0, 10);
            return dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0;
          })
          .fold(0.0, (sum, s) => sum + s.durationMinutes);
      return localSum / 60.0;
    }
  }

  @override
  Future<int> getStudyStreak(String userId) async {
    try {
      final int streak = await _supabase.rpc(
        'calculate_study_streak',
        params: {'user_id_param': userId},
      );
      return streak;
    } catch (_) {
      return 0;
    }
  }

  /// ── Offline Sync Logic ──
  /// Reads locally stored sessions and pushes them to Supabase in order.
  Future<void> syncOfflineSessions() async {
    final localSessions = _getLocalOfflineSessions();
    if (localSessions.isEmpty) return;

    final failedList = <StudySessionModel>[];

    for (final session in localSessions) {
      try {
        await _supabase.from('study_sessions').insert(session.toJson());
      } catch (_) {
        failedList.add(session); // Keep in cache if sync fails again
      }
    }

    await _saveLocalOfflineSessions(failedList);
  }

  // ── Helper Local Cache Methods ──

  List<StudySessionModel> _getLocalOfflineSessions() {
    final jsonStr = StorageService.getString(_offlineKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded.map((item) => StudySessionModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalOfflineSessions(List<StudySessionModel> list) async {
    final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
    await StorageService.setString(_offlineKey, encoded);
  }
}

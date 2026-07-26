import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/gym/domain/repositories/gym_attendance_repository.dart';

/// Provider for GymAttendanceRepository implementation.
final gymAttendanceRepositoryProvider = Provider<GymAttendanceRepository>((ref) {
  return GymAttendanceRepositoryImpl();
});

/// ── Gym Attendance Repository Implementation ──
/// Implements offline-first caching and automatic synchronization.
class GymAttendanceRepositoryImpl implements GymAttendanceRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  static String _cacheKey(String userId) => 'cached_gym_attendance_$userId';
  static String _queueKey(String userId) => 'pending_gym_sync_$userId';

  // ── Local Cache Helpers ──
  List<GymAttendanceModel> _getLocalCache(String userId) {
    final cachedData = StorageService.getString(_cacheKey(userId));
    if (cachedData == null) return [];
    try {
      final decoded = jsonDecode(cachedData) as List;
      return decoded.map((item) => GymAttendanceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _setLocalCache(String userId, List<GymAttendanceModel> list) async {
    final encoded = jsonEncode(list.map((item) => item.toJson()).toList());
    await StorageService.setString(_cacheKey(userId), encoded);
  }

  // ── Offline Operations Queue Helpers ──
  List<Map<String, dynamic>> _getSyncQueue(String userId) {
    final queueData = StorageService.getString(_queueKey(userId));
    if (queueData == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(queueData) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _setSyncQueue(String userId, List<Map<String, dynamic>> queue) async {
    await StorageService.setString(_queueKey(userId), jsonEncode(queue));
  }

  Future<void> _addToQueue(String userId, String action, GymAttendanceModel attendance) async {
    final queue = _getSyncQueue(userId);
    // Remove existing queue actions for the same record ID to avoid redundant requests
    queue.removeWhere((item) => item['attendance']['id'] == attendance.id);
    queue.add({
      'action': action,
      'attendance': attendance.toJson(),
    });
    await _setSyncQueue(userId, queue);
  }

  // ── Realtime Stream ──
  @override
  Stream<List<GymAttendanceModel>> watchGymAttendance(String userId, DateTime start, DateTime end) {
    final controller = StreamController<List<GymAttendanceModel>>();

    // Emit cached values immediately
    final cached = _getLocalCache(userId);
    final inRangeCached = cached.where((item) =>
        item.attendanceDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
        item.attendanceDate.isBefore(end.add(const Duration(seconds: 1)))).toList();
    controller.add(inRangeCached);

    // Initial fetch and synchronization runner
    _syncWithRemote(userId, start, end, controller).catchError((Object err) {
      if (!controller.isClosed) {
        controller.addError(err);
      }
    });

    // Setup Supabase realtime subscriptions
    final channel = _supabase
        .channel('public:gym_attendance:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'gym_attendance',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _syncWithRemote(userId, start, end, controller).catchError((_) {});
          },
        );
    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _syncWithRemote(
    String userId,
    DateTime start,
    DateTime end,
    StreamController<List<GymAttendanceModel>> controller,
  ) async {
    // Process offline sync queue if anything is pending
    await syncQueue(userId);

    // Fetch latest logs from server
    try {
      final remoteList = await _fetchFromRemoteRange(userId, start, end);
      if (!controller.isClosed) {
        controller.add(remoteList);
      }
    } catch (e) {
      // If network fails, re-emit cached to prevent error states
      final cached = _getLocalCache(userId);
      final inRangeCached = cached.where((item) =>
          item.attendanceDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          item.attendanceDate.isBefore(end.add(const Duration(seconds: 1)))).toList();
      if (!controller.isClosed) {
        controller.add(inRangeCached);
      }
    }
  }

  Future<List<GymAttendanceModel>> _fetchFromRemoteRange(String userId, DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);

    final rows = await _supabase
        .from('gym_attendance')
        .select()
        .eq('user_id', userId)
        .gte('attendance_date', startStr)
        .lte('attendance_date', endStr)
        .order('attendance_date', ascending: true);

    final list = rows.map((row) => GymAttendanceModel.fromJson(row)).toList();

    // Update the local cache for these items while keeping other months intact
    final cached = _getLocalCache(userId);
    final cachedMap = {for (final item in cached) item.id: item};
    for (final item in list) {
      cachedMap[item.id] = item;
    }
    // Clean up cache of any items in this date range that are NOT in the remote list (meaning they were deleted)
    cached.removeWhere((item) =>
        item.attendanceDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
        item.attendanceDate.isBefore(end.add(const Duration(seconds: 1))) &&
        !list.any((remote) => remote.id == item.id));

    // Re-add actual values
    for (final item in list) {
      if (!cached.any((c) => c.id == item.id)) {
        cached.add(item);
      } else {
        final index = cached.indexWhere((c) => c.id == item.id);
        if (index != -1) {
          cached[index] = item;
        }
      }
    }

    await _setLocalCache(userId, cached);
    return list;
  }

  @override
  Future<List<GymAttendanceModel>> getAllAttendance(String userId) async {
    try {
      final rows = await _supabase
          .from('gym_attendance')
          .select()
          .eq('user_id', userId)
          .order('attendance_date', ascending: true);

      final list = rows.map((row) => GymAttendanceModel.fromJson(row)).toList();
      await _setLocalCache(userId, list);
      return list;
    } catch (e) {
      final cached = _getLocalCache(userId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<GymAttendanceModel?> getAttendanceForDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    // Try from cache first
    final cached = _getLocalCache(userId);
    final match = cached.cast<GymAttendanceModel?>().firstWhere(
      (item) => item!.attendanceDate.toIso8601String().substring(0, 10) == dateStr,
      orElse: () => null,
    );
    if (match != null) return match;

    try {
      final row = await _supabase
          .from('gym_attendance')
          .select()
          .eq('user_id', userId)
          .eq('attendance_date', dateStr)
          .maybeSingle();

      if (row == null) return null;
      final record = GymAttendanceModel.fromJson(row);
      // Update cache
      cached.add(record);
      await _setLocalCache(userId, cached);
      return record;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GymAttendanceModel> logAttendance(GymAttendanceModel attendance) async {
    final userId = attendance.userId;
    // Optimistic UI updates
    final localList = _getLocalCache(userId);
    final index = localList.indexWhere((item) => item.id == attendance.id);
    if (index != -1) {
      localList[index] = attendance;
    } else {
      localList.add(attendance);
    }
    await _setLocalCache(userId, localList);

    try {
      final response = await _supabase
          .from('gym_attendance')
          .upsert(attendance.toJson())
          .select()
          .single();
      final saved = GymAttendanceModel.fromJson(response);

      // Update cache with server details
      final currentList = _getLocalCache(userId);
      final idx = currentList.indexWhere((item) => item.id == attendance.id);
      if (idx != -1) {
        currentList[idx] = saved;
        await _setLocalCache(userId, currentList);
      }
      return saved;
    } catch (e) {
      // Add to offline sync queue
      await _addToQueue(userId, 'upsert', attendance);
      return attendance;
    }
  }

  @override
  Future<void> deleteAttendance(String attendanceId) async {
    final authUser = _supabase.auth.currentUser;
    final userId = authUser?.id ?? '';
    if (userId.isNotEmpty) {
      final localList = _getLocalCache(userId);
      localList.removeWhere((item) => item.id == attendanceId);
      await _setLocalCache(userId, localList);
    }

    try {
      await _supabase.from('gym_attendance').delete().eq('id', attendanceId);
    } catch (e) {
      if (userId.isNotEmpty) {
        // Queue the deletion offline
        final dummyModel = GymAttendanceModel(
          id: attendanceId,
          userId: userId,
          attendanceDate: DateTime.now(),
          status: 'Absent',
        );
        await _addToQueue(userId, 'delete', dummyModel);
      }
    }
  }

  @override
  Future<double> getGymAttendancePercentage(String userId, DateTime start, DateTime end) async {
    try {
      // We can calculate it directly from range.
      // Since direct calculation is highly offline-resilient, let's use the local cache/fetched logs.
      final logs = await _fetchFromRemoteRange(userId, start, end);
      if (logs.isEmpty) return 0.0;
      
      final presentCount = logs.where((log) => log.status == 'Present').length;
      return (presentCount / logs.length) * 100.0;
    } catch (_) {
      // Fallback to cache calculation
      final cached = _getLocalCache(userId);
      final inRange = cached.where((item) =>
          item.attendanceDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          item.attendanceDate.isBefore(end.add(const Duration(seconds: 1)))).toList();
      if (inRange.isEmpty) return 0.0;
      final presentCount = inRange.where((log) => log.status == 'Present').length;
      return (presentCount / inRange.length) * 100.0;
    }
  }

  // ── Sync Queue Processor ──
  @override
  Future<void> syncQueue(String userId) async {
    final queue = _getSyncQueue(userId);
    if (queue.isEmpty) return;

    final failedList = <Map<String, dynamic>>[];

    for (final item in queue) {
      final action = item['action'] as String;
      final attendanceJson = item['attendance'] as Map<String, dynamic>;
      final attendance = GymAttendanceModel.fromJson(attendanceJson);

      try {
        if (action == 'upsert') {
          await _supabase.from('gym_attendance').upsert(attendance.toJson());
        } else if (action == 'delete') {
          await _supabase.from('gym_attendance').delete().eq('id', attendance.id);
        }
      } catch (_) {
        failedList.add(item);
      }
    }

    await _setSyncQueue(userId, failedList);
  }
}

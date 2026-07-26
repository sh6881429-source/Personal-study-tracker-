import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/home/data/models/dashboard_data.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';
import 'package:prep_tracker/features/home/data/models/exam_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/home/domain/repositories/home_repository.dart';

/// Provider for HomeRepository implementation.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl();
});

/// ── Home Repository Implementation ──
/// Performs optimized query operations. Attempts a single-trip RPC aggregation call first,
/// falling back to concurrent table queries if RPC is unavailable.
class HomeRepositoryImpl implements HomeRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  @override
  Future<DashboardData> getDashboardData(String userId) async {
    try {
      // 1. Single network round-trip call using postgres json builder (Ultra Fast)
      final response = await _supabase.rpc(
        'get_dashboard_data',
        params: {'user_id_param': userId},
      );

      final data = response as Map<String, dynamic>;

      return DashboardData(
        studyMinutesToday: (data['study_minutes_today'] as num?)?.toDouble() ?? 0.0,
        dailyGoal: data['daily_goal'] != null
            ? DailyGoalModel.fromJson(data['daily_goal'] as Map<String, dynamic>)
            : null,
        pendingChaptersCount: data['pending_chapters_count'] as int? ?? 0,
        completedChaptersCount: data['completed_chapters_count'] as int? ?? 0,
        revisionProgressPercentage: (data['revision_progress_percentage'] as num?)?.toDouble() ?? 0.0,
        studyStreak: data['study_streak'] as int? ?? 0,
        gymAttendanceToday: data['gym_attendance_today'] != null
            ? GymAttendanceModel.fromJson(data['gym_attendance_today'] as Map<String, dynamic>)
            : null,
        totalBookmarksCount: data['total_bookmarks_count'] as int? ?? 0,
        nearestExam: data['nearest_exam'] != null
            ? ExamModel.fromJson(data['nearest_exam'] as Map<String, dynamic>)
            : null,
        lastSession: data['last_session'] != null
            ? StudySessionModel.fromJson(data['last_session'] as Map<String, dynamic>)
            : null,
        lastBookmark: data['last_bookmark'] != null
            ? BookmarkModel.fromJson(data['last_bookmark'] as Map<String, dynamic>)
            : null,
        lastPdf: data['last_pdf'] != null
            ? PdfModel.fromJson(data['last_pdf'] as Map<String, dynamic>)
            : null,
        lastGymAttendance: data['last_gym_attendance'] != null
            ? GymAttendanceModel.fromJson(data['last_gym_attendance'] as Map<String, dynamic>)
            : null,
      );
    } catch (_) {
      // 2. Fallback to concurrent queries in case the RPC is missing or fails (Robust)
      return _fallbackGetDashboardData(userId);
    }
  }

  /// Fallback parallel tables query dispatcher.
  Future<DashboardData> _fallbackGetDashboardData(String userId) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    final futures = await Future.wait<dynamic>([
      // 0: Today's study minutes
      _supabase
          .from('study_sessions')
          .select('duration_minutes')
          .eq('user_id', userId)
          .eq('study_date', todayStr)
          .then((rows) {
            return rows.fold<double>(0.0, (sum, row) => sum + ((row['duration_minutes'] as num?)?.toDouble() ?? 0.0));
          }).catchError((_) => 0.0),

      // 1: Daily Goal
      _supabase
          .from('daily_goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .then((row) => row != null ? DailyGoalModel.fromJson(row) : null)
          .catchError((_) => null),

      // 2: Pending Chapters Count
      _supabase
          .rpc('calculate_pending_chapters', params: {'user_id_param': userId})
          .then((value) => (value as int?) ?? 0)
          .catchError((_) => 0),

      // 3: Completed Chapters Count
      _supabase
          .from('chapters')
          .select('id')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .then((res) => res.length)
          .catchError((_) => 0),

      // 4: Revision Progress
      _supabase
          .rpc('calculate_revision_progress', params: {'user_id_param': userId})
          .then((value) => (value as num?)?.toDouble() ?? 0.0)
          .catchError((_) => 0.0),

      // 5: Study Streak
      _supabase
          .rpc('calculate_study_streak', params: {'user_id_param': userId})
          .then((value) => (value as int?) ?? 0)
          .catchError((_) => 0),

      // 6: Today's Gym Attendance
      _supabase
          .from('gym_attendance')
          .select()
          .eq('user_id', userId)
          .eq('attendance_date', todayStr)
          .maybeSingle()
          .then((row) => row != null ? GymAttendanceModel.fromJson(row) : null)
          .catchError((_) => null),

      // 7: Total Bookmarks Count
      _supabase
          .from('bookmarks')
          .select('id')
          .eq('user_id', userId)
          .then((res) => res.length)
          .catchError((_) => 0),

      // 8: Nearest Exam
      _supabase
          .from('exams')
          .select()
          .eq('user_id', userId)
          .gte('exam_date', now.toIso8601String())
          .order('exam_date', ascending: true)
          .limit(1)
          .maybeSingle()
          .then((row) => row != null ? ExamModel.fromJson(row) : null)
          .catchError((_) => null),

      // 9: Last Study Session
      _supabase
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .then((row) => row != null ? StudySessionModel.fromJson(row) : null)
          .catchError((_) => null),

      // 10: Last Bookmark
      _supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .then((row) => row != null ? BookmarkModel.fromJson(row) : null)
          .catchError((_) => null),

      // 11: Last PDF Uploaded
      _supabase
          .from('pdf_library')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .then((row) => row != null ? PdfModel.fromJson(row) : null)
          .catchError((_) => null),

      // 12: Last Gym Attendance
      _supabase
          .from('gym_attendance')
          .select()
          .eq('user_id', userId)
          .order('attendance_date', ascending: false)
          .limit(1)
          .maybeSingle()
          .then((row) => row != null ? GymAttendanceModel.fromJson(row) : null)
          .catchError((_) => null),
    ]);

    return DashboardData(
      studyMinutesToday: futures[0] as double,
      dailyGoal: futures[1] as DailyGoalModel?,
      pendingChaptersCount: futures[2] as int,
      completedChaptersCount: futures[3] as int,
      revisionProgressPercentage: futures[4] as double,
      studyStreak: futures[5] as int,
      gymAttendanceToday: futures[6] as GymAttendanceModel?,
      totalBookmarksCount: futures[7] as int,
      nearestExam: futures[8] as ExamModel?,
      lastSession: futures[9] as StudySessionModel?,
      lastBookmark: futures[10] as BookmarkModel?,
      lastPdf: futures[11] as PdfModel?,
      lastGymAttendance: futures[12] as GymAttendanceModel?,
    );
  }
}

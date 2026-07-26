import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/features/study/domain/repositories/study_session_repository.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/chapter_repository_impl.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';

enum TimerStatus { stopped, running, paused }

/// ── Study Timer State ──
@immutable
class StudyTimerState {
  const StudyTimerState({
    this.status = TimerStatus.stopped,
    this.durationSeconds = 0,
    this.startTime,
    this.pauseTime,
    this.accumulatedPausedSeconds = 0,
    this.selectedSubject,
    this.selectedChapter,
    this.sessionType = 'Normal Study',
    this.sessionNotes = '',
  });

  final TimerStatus status;
  final int durationSeconds;
  final DateTime? startTime;
  final DateTime? pauseTime;
  final int accumulatedPausedSeconds;
  final SubjectModel? selectedSubject;
  final ChapterModel? selectedChapter;
  final String sessionType;
  final String sessionNotes;

  StudyTimerState copyWith({
    TimerStatus? status,
    int? durationSeconds,
    DateTime? startTime,
    DateTime? pauseTime,
    int? accumulatedPausedSeconds,
    SubjectModel? selectedSubject,
    ChapterModel? selectedChapter,
    String? sessionType,
    String? sessionNotes,
    bool clearSubject = false,
    bool clearChapter = false,
  }) {
    return StudyTimerState(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startTime: startTime ?? this.startTime,
      pauseTime: pauseTime ?? this.pauseTime,
      accumulatedPausedSeconds: accumulatedPausedSeconds ?? this.accumulatedPausedSeconds,
      selectedSubject: clearSubject ? null : (selectedSubject ?? this.selectedSubject),
      selectedChapter: clearChapter ? null : (selectedChapter ?? this.selectedChapter),
      sessionType: sessionType ?? this.sessionType,
      sessionNotes: sessionNotes ?? this.sessionNotes,
    );
  }
}

/// ── Study Timer Notifier ──
/// Handles background lifecycle updates, persistent states, ticks, and saves.
class StudyTimerNotifier extends StateNotifier<StudyTimerState> {
  StudyTimerNotifier(this._repository, this._ref) : super(const StudyTimerState()) {
    _restoreTimerState();
  }

  final StudySessionRepository _repository;
  final Ref _ref;
  Timer? _timer;

  // Storage preference keys
  static const String _statusKey = 'timer_status';
  static const String _durationKey = 'timer_duration';
  static const String _startKey = 'timer_start_time';
  static const String _pauseKey = 'timer_pause_time';
  static const String _pausedSecsKey = 'timer_paused_secs';
  static const String _subjectIdKey = 'timer_subject_id';
  static const String _chapterIdKey = 'timer_chapter_id';
  static const String _typeKey = 'timer_session_type';
  static const String _notesKey = 'timer_notes';

  /// Restores active sessions after app restarts or minimizations.
  Future<void> _restoreTimerState() async {
    final statusStr = StorageService.getString(_statusKey);
    if (statusStr == null || statusStr == 'stopped') return;

    final status = statusStr == 'paused' ? TimerStatus.paused : TimerStatus.running;
    final startStr = StorageService.getString(_startKey);
    final startTime = startStr != null ? DateTime.parse(startStr) : null;
    final pauseStr = StorageService.getString(_pauseKey);
    final pauseTime = pauseStr != null ? DateTime.parse(pauseStr) : null;
    final pausedSecs = StorageService.getInt(_pausedSecsKey) ?? 0;
    final duration = StorageService.getInt(_durationKey) ?? 0;

    final subjectId = StorageService.getString(_subjectIdKey);
    final chapterId = StorageService.getString(_chapterIdKey);
    final type = StorageService.getString(_typeKey) ?? 'Normal Study';
    final notes = StorageService.getString(_notesKey) ?? '';

    // Load subjects and chapters to map back selected models
    SubjectModel? selectedSubject;
    ChapterModel? selectedChapter;

    final auth = _ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';

    if (userId.isNotEmpty) {
      if (subjectId != null) {
        try {
          final subjects = await _ref.read(subjectRepositoryProvider).getActiveSubjects(userId);
          selectedSubject = subjects.firstWhere((s) => s.id == subjectId);
        } catch (_) {}
      }
      if (chapterId != null && selectedSubject != null) {
        try {
          final chapters = await _ref.read(chapterRepositoryProvider).getChapters(selectedSubject.id);
          selectedChapter = chapters.firstWhere((c) => c.id == chapterId);
        } catch (_) {}
      }
    }

    state = StudyTimerState(
      status: status,
      durationSeconds: duration,
      startTime: startTime,
      pauseTime: pauseTime,
      accumulatedPausedSeconds: pausedSecs,
      selectedSubject: selectedSubject,
      selectedChapter: selectedChapter,
      sessionType: type,
      sessionNotes: notes,
    );

    if (status == TimerStatus.running && startTime != null) {
      // Calculate elapsed offset including time app was closed
      final diff = DateTime.now().difference(startTime).inSeconds;
      final actualDuration = diff - pausedSecs;
      state = state.copyWith(durationSeconds: actualDuration > 0 ? actualDuration : 0);
      _startTicker();
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.startTime == null) return;
      final diff = DateTime.now().difference(state.startTime!).inSeconds;
      final actualDuration = diff - state.accumulatedPausedSeconds;
      state = state.copyWith(durationSeconds: actualDuration > 0 ? actualDuration : 0);
      StorageService.setInt(_durationKey, state.durationSeconds);
    });
  }

  void selectSubject(SubjectModel? subject) {
    state = state.copyWith(selectedSubject: subject, clearSubject: subject == null, clearChapter: true);
    if (subject != null) {
      StorageService.setString(_subjectIdKey, subject.id);
    } else {
      StorageService.remove(_subjectIdKey);
    }
    StorageService.remove(_chapterIdKey);
  }

  void selectChapter(ChapterModel? chapter) {
    state = state.copyWith(selectedChapter: chapter, clearChapter: chapter == null);
    if (chapter != null) {
      StorageService.setString(_chapterIdKey, chapter.id);
    } else {
      StorageService.remove(_chapterIdKey);
    }
  }

  void setSessionType(String type) {
    state = state.copyWith(sessionType: type);
    StorageService.setString(_typeKey, type);
  }

  void setSessionNotes(String notes) {
    state = state.copyWith(sessionNotes: notes);
    StorageService.setString(_notesKey, notes);
  }

  void startTimer() {
    if (state.selectedSubject == null) {
      throw StateError('Please select a subject before starting the timer.');
    }

    final now = DateTime.now();
    state = state.copyWith(
      status: TimerStatus.running,
      durationSeconds: 0,
      startTime: now,
      accumulatedPausedSeconds: 0,
      pauseTime: null,
    );

    StorageService.setString(_statusKey, 'running');
    StorageService.setString(_startKey, now.toIso8601String());
    StorageService.setInt(_durationKey, 0);
    StorageService.setInt(_pausedSecsKey, 0);
    StorageService.remove(_pauseKey);

    _startTicker();
  }

  void pauseTimer() {
    if (state.status != TimerStatus.running) return;
    _timer?.cancel();

    final now = DateTime.now();
    state = state.copyWith(
      status: TimerStatus.paused,
      pauseTime: now,
    );

    StorageService.setString(_statusKey, 'paused');
    StorageService.setString(_pauseKey, now.toIso8601String());
  }

  void resumeTimer() {
    if (state.status != TimerStatus.paused || state.pauseTime == null || state.startTime == null) return;

    final now = DateTime.now();
    final pauseDuration = now.difference(state.pauseTime!).inSeconds;
    final newAccumulated = state.accumulatedPausedSeconds + pauseDuration;

    state = state.copyWith(
      status: TimerStatus.running,
      accumulatedPausedSeconds: newAccumulated,
      pauseTime: null,
    );

    StorageService.setString(_statusKey, 'running');
    StorageService.setInt(_pausedSecsKey, newAccumulated);
    StorageService.remove(_pauseKey);

    _startTicker();
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
      status: TimerStatus.stopped,
      durationSeconds: 0,
      startTime: null,
      pauseTime: null,
      accumulatedPausedSeconds: 0,
      sessionNotes: '',
    );

    // Clear local storage configs
    StorageService.setString(_statusKey, 'stopped');
    StorageService.remove(_startKey);
    StorageService.remove(_durationKey);
    StorageService.remove(_pauseKey);
    StorageService.remove(_pausedSecsKey);
    StorageService.remove(_notesKey);
  }

  /// Stop study session and return final session model data (to be saved).
  StudySessionModel? stopSession() {
    if (state.status == TimerStatus.stopped || state.startTime == null || state.selectedSubject == null) return null;
    _timer?.cancel();

    final auth = _ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    final endTime = DateTime.now();
    final finalDurationMinutes = (state.durationSeconds / 60).round();

    final session = StudySessionModel(
      id: const Uuid().v4(),
      userId: userId,
      subjectId: state.selectedSubject!.id,
      chapterId: state.selectedChapter?.id,
      startTime: state.startTime!,
      endTime: endTime,
      durationMinutes: finalDurationMinutes > 0 ? finalDurationMinutes : 1, // Ensure min 1 min is logged
      sessionNotes: state.sessionNotes.isNotEmpty ? state.sessionNotes : null,
      sessionType: state.sessionType,
      studyDate: DateTime.now(),
    );

    resetTimer();
    return session;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for StudyTimerState notifier.
final studyTimerProvider = StateNotifierProvider<StudyTimerNotifier, StudyTimerState>((ref) {
  final repository = ref.watch(studySessionRepositoryProvider);
  return StudyTimerNotifier(repository, ref);
});

/// ── Study Session History Provider ──
/// Watches the logged sessions list for today.
final todaySessionsProvider = FutureProvider<List<StudySessionModel>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return [];

  final repository = ref.watch(studySessionRepositoryProvider);
  final sessions = await repository.getSessions(userId);

  // Filter for today's sessions locally
  final now = DateTime.now();
  return sessions.where((s) {
    return s.studyDate.year == now.year &&
        s.studyDate.month == now.month &&
        s.studyDate.day == now.day;
  }).toList();
});

/// ── Study Statistics Provider ──
/// Groups calculations for study summary blocks.
@immutable
class StudyStats {
  const StudyStats({
    required this.todayMinutes,
    required this.weeklyHours,
    required this.monthlyHours,
    required this.dailyAverageHours,
    required this.longestSessionMinutes,
  });

  final int todayMinutes;
  final double weeklyHours;
  final double monthlyHours;
  final double dailyAverageHours;
  final int longestSessionMinutes;
}

final studyStatsProvider = FutureProvider<StudyStats>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) {
    return const StudyStats(
      todayMinutes: 0,
      weeklyHours: 0.0,
      monthlyHours: 0.0,
      dailyAverageHours: 0.0,
      longestSessionMinutes: 0,
    );
  }

  final repository = ref.watch(studySessionRepositoryProvider);
  final now = DateTime.now();

  // Load all sessions
  final sessions = await repository.getSessions(userId);

  // Today
  final todayDate = now.toIso8601String().substring(0, 10);
  final todayMinutes = sessions
      .where((s) => s.studyDate.toIso8601String().substring(0, 10) == todayDate)
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);

  // Weekly (last 7 days)
  final startOfWeek = now.subtract(const Duration(days: 7));
  final weeklyMinutes = sessions
      .where((s) => s.studyDate.isAfter(startOfWeek))
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);

  // Monthly (last 30 days)
  final startOfMonth = now.subtract(const Duration(days: 30));
  final monthlyMinutes = sessions
      .where((s) => s.studyDate.isAfter(startOfMonth))
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);

  // Longest Session
  final longestSession = sessions.isEmpty
      ? 0
      : sessions.map((s) => s.durationMinutes).reduce((curr, next) => curr > next ? curr : next);

  // Daily Average (over 30 days, or unique study days)
  final uniqueDays = sessions.map((s) => s.studyDate.toIso8601String().substring(0, 10)).toSet().length;
  final totalHours = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) / 60.0;
  final dailyAverage = uniqueDays > 0 ? totalHours / uniqueDays : 0.0;

  return StudyStats(
    todayMinutes: todayMinutes,
    weeklyHours: weeklyMinutes / 60.0,
    monthlyHours: monthlyMinutes / 60.0,
    dailyAverageHours: dailyAverage,
    longestSessionMinutes: longestSession,
  );
});

/// ── All Logged Sessions Provider ──
final allSessionsProvider = FutureProvider<List<StudySessionModel>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return [];

  final repository = ref.watch(studySessionRepositoryProvider);
  return repository.getSessions(userId);
});

/// Helper to refresh all reactive UI screens upon logging a new study session.
void refreshDashboardAndStats(WidgetRef ref) {
  ref.invalidate(todaySessionsProvider);
  ref.invalidate(allSessionsProvider);
  ref.invalidate(studyStatsProvider);
  ref.invalidate(homeControllerProvider); // Instantly updates Home Dashboard progress percentages!
}

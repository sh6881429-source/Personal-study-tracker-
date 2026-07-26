import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/gym/domain/repositories/gym_attendance_repository.dart';
import 'package:prep_tracker/features/gym/data/repositories/gym_attendance_repository_impl.dart';

/// Class to hold computed gym statistics
class GymStats {
  const GymStats({
    required this.totalLogged,
    required this.presentCount,
    required this.absentCount,
    required this.restDaysCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyAttendancePercentage,
    required this.overallAttendancePercentage,
  });

  final int totalLogged;
  final int presentCount;
  final int absentCount;
  final int restDaysCount;
  final int currentStreak;
  final int longestStreak;
  final double monthlyAttendancePercentage;
  final double overallAttendancePercentage;

  factory GymStats.empty() {
    return const GymStats(
      totalLogged: 0,
      presentCount: 0,
      absentCount: 0,
      restDaysCount: 0,
      currentStreak: 0,
      longestStreak: 0,
      monthlyAttendancePercentage: 0.0,
      overallAttendancePercentage: 0.0,
    );
  }
}

/// Provider for the currently active calendar month
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Raw stream provider of gym logs for the selected calendar month
final rawGymAttendanceProvider = StreamProvider<List<GymAttendanceModel>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return Stream.value([]);

  final repository = ref.watch(gymAttendanceRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);

  // Start is 1st of month, end is last day of month
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

  return repository.watchGymAttendance(userId, start, end);
});

/// Map provider for O(1) day attendance lookup in calendar (key: 'YYYY-MM-DD')
final gymAttendanceMapProvider = Provider<Map<String, GymAttendanceModel>>((ref) {
  final list = ref.watch(rawGymAttendanceProvider).value ?? [];
  final map = <String, GymAttendanceModel>{};
  for (final item in list) {
    final key = item.attendanceDate.toIso8601String().substring(0, 10);
    map[key] = item;
  }
  return map;
});

/// Future provider that fetches all logs and calculates statistics
final gymStatsProvider = FutureProvider<GymStats>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return GymStats.empty();

  final repository = ref.watch(gymAttendanceRepositoryProvider);
  // Fetch all attendance data to compute streaks correctly
  final allLogs = await repository.getAllAttendance(userId);

  if (allLogs.isEmpty) return GymStats.empty();

  // Sort logs by date ascending
  allLogs.sort((a, b) => a.attendanceDate.compareTo(b.attendanceDate));

  int present = 0;
  int absent = 0;
  int rest = 0;

  for (final log in allLogs) {
    if (log.status == 'Present') {
      present++;
    } else if (log.status == 'Absent') {
      absent++;
    } else if (log.status == 'Rest Day') {
      rest++;
    }
  }

  // Calculate streaks
  final logMap = {
    for (final log in allLogs)
      log.attendanceDate.toIso8601String().substring(0, 10): log.status
  };

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // 1. Current Streak Calculation
  int currentStreak = 0;
  DateTime checkDate = today;

  // If today isn't logged yet, check if yesterday was logged to continue streak
  final todayStr = today.toIso8601String().substring(0, 10);
  if (!logMap.containsKey(todayStr)) {
    checkDate = today.subtract(const Duration(days: 1));
  }

  while (true) {
    final key = checkDate.toIso8601String().substring(0, 10);
    final status = logMap[key];
    if (status == 'Present' || status == 'Rest Day') {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  // 2. Longest Streak Calculation
  int longestStreak = 0;
  int tempStreak = 0;

  // We walk through sorted logs day by day.
  // Note: if there is a gap between two logged dates, the streak breaks.
  if (allLogs.isNotEmpty) {
    DateTime? prevDate;
    for (final log in allLogs) {
      final date = DateTime(log.attendanceDate.year, log.attendanceDate.month, log.attendanceDate.day);
      final status = log.status;

      if (status == 'Present' || status == 'Rest Day') {
        if (prevDate == null) {
          tempStreak = 1;
        } else {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            // Gap in logging, reset streak
            if (tempStreak > longestStreak) {
              longestStreak = tempStreak;
            }
            tempStreak = 1;
          }
        }
        prevDate = date;
      } else {
        // 'Absent' breaks streak
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 0;
        prevDate = null;
      }
    }
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }
  }

  // Monthly Attendance %
  final currentMonth = ref.watch(selectedMonthProvider);
  final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
  final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);

  final monthlyLogs = allLogs.where((log) =>
      log.attendanceDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
      log.attendanceDate.isBefore(endOfMonth.add(const Duration(seconds: 1))));

  double monthlyPct = 0.0;
  if (monthlyLogs.isNotEmpty) {
    final monthlyPresent = monthlyLogs.where((log) => log.status == 'Present').length;
    monthlyPct = (monthlyPresent / monthlyLogs.length) * 100.0;
  }

  // Overall Attendance %
  double overallPct = 0.0;
  if (allLogs.isNotEmpty) {
    overallPct = (present / allLogs.length) * 100.0;
  }

  return GymStats(
    totalLogged: allLogs.length,
    presentCount: present,
    absentCount: absent,
    restDaysCount: rest,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    monthlyAttendancePercentage: monthlyPct,
    overallAttendancePercentage: overallPct,
  );
});

/// ── Gym Controller StateNotifier ──
/// Manages actions like logging attendance, deleting attendance, and syncing queue.
class GymController extends StateNotifier<bool> {
  GymController(this._repository, this._ref) : super(false);

  final GymAttendanceRepository _repository;
  final Ref _ref;

  Future<void> logAttendance({
    required DateTime date,
    required String status,
    String? notes,
  }) async {
    final auth = _ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    state = true;
    try {
      // Check if there is already an entry for this date to update it
      final existing = await _repository.getAttendanceForDate(userId, date);

      final attendance = GymAttendanceModel(
        id: existing?.id ?? const Uuid().v4(),
        userId: userId,
        attendanceDate: date,
        status: status,
        notes: notes,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.logAttendance(attendance);

      _ref.invalidate(rawGymAttendanceProvider);
      _ref.invalidate(gymStatsProvider);
      _ref.invalidate(homeControllerProvider);
    } finally {
      state = false;
    }
  }

  Future<void> deleteAttendance(String attendanceId) async {
    state = true;
    try {
      await _repository.deleteAttendance(attendanceId);

      _ref.invalidate(rawGymAttendanceProvider);
      _ref.invalidate(gymStatsProvider);
      _ref.invalidate(homeControllerProvider);
    } finally {
      state = false;
    }
  }

  Future<void> syncOfflineQueue() async {
    final auth = _ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    state = true;
    try {
      await _repository.syncQueue(userId);
      _ref.invalidate(rawGymAttendanceProvider);
      _ref.invalidate(gymStatsProvider);
      _ref.invalidate(homeControllerProvider);
    } finally {
      state = false;
    }
  }
}

/// Provider for GymController
final gymControllerProvider = StateNotifierProvider<GymController, bool>((ref) {
  final repo = ref.watch(gymAttendanceRepositoryProvider);
  return GymController(repo, ref);
});

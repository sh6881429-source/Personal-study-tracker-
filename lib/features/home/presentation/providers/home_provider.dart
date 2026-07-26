import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/home/data/models/dashboard_data.dart';
import 'package:prep_tracker/features/home/data/repositories/home_repository_impl.dart';
import 'package:prep_tracker/features/home/domain/repositories/home_repository.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';

/// ── Home Controller (Dashboard Notifier) ──
/// Manages the async loading, error, and data states of the dashboard data.
class HomeController extends StateNotifier<AsyncValue<DashboardData>> {
  HomeController(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  final HomeRepository _repository;
  final String _userId;

  /// Loads/Reloads the dashboard metrics.
  Future<void> loadDashboard() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getDashboardData(_userId);
      if (mounted) {
        state = AsyncValue.data(data);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Silently refreshes the dashboard without showing a loading block.
  Future<void> refreshDashboard() async {
    try {
      final data = await _repository.getDashboardData(_userId);
      if (mounted) {
        state = AsyncValue.data(data);
      }
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

/// Provider for HomeController, keyed by the current user ID.
final homeControllerProvider = StateNotifierProvider<HomeController, AsyncValue<DashboardData>>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';

  if (userId.isEmpty) {
    return HomeController(repository, '');
  }

  return HomeController(repository, userId);
});

/// ── Weekly Study Days Provider ──
/// Returns a set of weekday integers (1 to 7) representing days the user studied this week.
final weeklyStudyDaysProvider = FutureProvider<Set<int>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return {};

  final repository = ref.watch(studySessionRepositoryProvider);
  final sessions = await repository.getSessions(userId);

  final now = DateTime.now();
  // Find Monday of the current week
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  final endOfWeek = startOfDay.add(const Duration(days: 7));

  final weeklySessions = sessions.where((s) {
    return s.studyDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
        s.studyDate.isBefore(endOfWeek);
  });

  return weeklySessions.map((s) => s.studyDate.weekday).toSet();
});

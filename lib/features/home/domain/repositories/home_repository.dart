import 'package:prep_tracker/features/home/data/models/dashboard_data.dart';

/// ── Home Repository Contract ──
/// Exposes operations to load unified dashboard metrics and data models.
abstract interface class HomeRepository {
  /// Loads aggregated user stats, targets, streaks, and recent activity logs.
  Future<DashboardData> getDashboardData(String userId);
}

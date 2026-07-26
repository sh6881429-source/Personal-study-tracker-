import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';

/// ── Gym Attendance Repository Contract ──
abstract interface class GymAttendanceRepository {
  /// Stream of gym logs in a specific date range.
  Stream<List<GymAttendanceModel>> watchGymAttendance(String userId, DateTime start, DateTime end);

  /// Fetch gym attendance record for a specific date.
  Future<GymAttendanceModel?> getAttendanceForDate(String userId, DateTime date);

  /// Log gym attendance (Present, Absent, Rest Day) for a date.
  Future<GymAttendanceModel> logAttendance(GymAttendanceModel attendance);

  /// Fetch gym attendance statistics percentage.
  Future<double> getGymAttendancePercentage(String userId, DateTime start, DateTime end);

  /// Fetch all gym attendance logs for a user.
  Future<List<GymAttendanceModel>> getAllAttendance(String userId);

  /// Delete a specific gym attendance record.
  Future<void> deleteAttendance(String attendanceId);

  /// Process any pending offline operations.
  Future<void> syncQueue(String userId);
}


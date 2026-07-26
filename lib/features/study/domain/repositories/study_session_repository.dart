import 'package:prep_tracker/features/study/data/models/study_session_model.dart';

/// ── Study Session Repository Contract ──
abstract interface class StudySessionRepository {
  /// Stream of study sessions within a specified date range.
  Stream<List<StudySessionModel>> watchSessions(String userId, DateTime start, DateTime end);

  /// Fetch all sessions for a user.
  Future<List<StudySessionModel>> getSessions(String userId);

  /// Log a completed study session.
  Future<StudySessionModel> logSession(StudySessionModel session);

  /// Delete a logged session.
  Future<void> deleteSession(String sessionId);

  /// Fetch total study hours between dates using database functions.
  Future<double> getStudyHours(String userId, DateTime start, DateTime end);

  /// Fetch the user's active study streak count.
  Future<int> getStudyStreak(String userId);
}

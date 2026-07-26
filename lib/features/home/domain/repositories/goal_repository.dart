import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';
import 'package:prep_tracker/features/home/data/models/exam_model.dart';

/// ── Goals & Exams Repository Contract ──
abstract interface class GoalRepository {
  // ── Daily Goals ──

  /// Stream of user daily goals.
  Stream<DailyGoalModel?> watchDailyGoal(String userId);

  /// Fetch user daily goals.
  Future<DailyGoalModel?> getDailyGoal(String userId);

  /// Create or update user daily goal values.
  Future<DailyGoalModel> saveDailyGoal(DailyGoalModel goal);

  // ── Exams ──

  /// Fetch user exams sorted by date.
  Future<List<ExamModel>> getExams(String userId);

  /// Add a target exam countdown.
  Future<ExamModel> createExam(ExamModel exam);

  /// Update an exam definition.
  Future<ExamModel> updateExam(ExamModel exam);

  /// Delete an exam.
  Future<void> deleteExam(String examId);
}

import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';

/// ── Subject Repository Contract ──
abstract interface class SubjectRepository {
  /// Stream of subjects belonging to the currently logged in user.
  Stream<List<SubjectModel>> watchSubjects(String userId);

  /// Fetch list of all subjects (active & archived).
  Future<List<SubjectModel>> getSubjects(String userId);

  /// Fetch active subjects only.
  Future<List<SubjectModel>> getActiveSubjects(String userId);

  /// Create a new subject.
  Future<SubjectModel> createSubject(SubjectModel subject);

  /// Update subject properties (color, icon, order, archiving).
  Future<SubjectModel> updateSubject(SubjectModel subject);

  /// Delete a subject permanently.
  Future<void> deleteSubject(String subjectId);
}

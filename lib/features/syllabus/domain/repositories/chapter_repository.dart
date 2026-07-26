import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';

/// ── Chapter Repository Contract ──
abstract interface class ChapterRepository {
  /// Stream of chapters belonging to a specific subject.
  Stream<List<ChapterModel>> watchChapters(String subjectId);

  /// Fetch all chapters for a subject.
  Future<List<ChapterModel>> getChapters(String subjectId);

  /// Fetch pending/uncompleted chapters for the user.
  Future<List<ChapterModel>> getPendingChapters(String userId);

  /// Create a new chapter.
  Future<ChapterModel> createChapter(ChapterModel chapter);

  /// Update chapter progress, completion state, revision counts.
  Future<ChapterModel> updateChapter(ChapterModel chapter);

  /// Delete a chapter.
  Future<void> deleteChapter(String chapterId);
}

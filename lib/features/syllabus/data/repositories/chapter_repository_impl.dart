import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/syllabus/domain/repositories/chapter_repository.dart';

/// Provider for ChapterRepository implementation.
final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return ChapterRepositoryImpl();
});

/// ── Chapter Repository Implementation ──
class ChapterRepositoryImpl implements ChapterRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  @override
  Stream<List<ChapterModel>> watchChapters(String subjectId) {
    return _supabase
        .from('chapters')
        .stream(primaryKey: ['id'])
        .eq('subject_id', subjectId)
        .order('display_order', ascending: true)
        .map((rows) => rows.map((row) => ChapterModel.fromJson(row)).toList());
  }

  @override
  Future<List<ChapterModel>> getChapters(String subjectId) async {
    final rows = await _supabase
        .from('chapters')
        .select()
        .eq('subject_id', subjectId)
        .order('display_order', ascending: true);
    return rows.map((row) => ChapterModel.fromJson(row)).toList();
  }

  @override
  Future<List<ChapterModel>> getPendingChapters(String userId) async {
    final rows = await _supabase
        .from('chapters')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('display_order', ascending: true);
    return rows.map((row) => ChapterModel.fromJson(row)).toList();
  }

  @override
  Future<ChapterModel> createChapter(ChapterModel chapter) async {
    final response = await _supabase
        .from('chapters')
        .insert(chapter.toJson())
        .select()
        .single();
    return ChapterModel.fromJson(response);
  }

  @override
  Future<ChapterModel> updateChapter(ChapterModel chapter) async {
    final response = await _supabase
        .from('chapters')
        .update(chapter.toJson())
        .eq('id', chapter.id)
        .select()
        .single();
    return ChapterModel.fromJson(response);
  }

  @override
  Future<void> deleteChapter(String chapterId) async {
    await _supabase.from('chapters').delete().eq('id', chapterId);
  }
}

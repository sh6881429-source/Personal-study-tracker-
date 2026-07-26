import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/domain/repositories/subject_repository.dart';

/// Provider for SubjectRepository implementation.
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl();
});

/// ── Subject Repository Implementation ──
class SubjectRepositoryImpl implements SubjectRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  @override
  Stream<List<SubjectModel>> watchSubjects(String userId) {
    return _supabase
        .from('subjects')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('display_order', ascending: true)
        .map((rows) => rows.map((row) => SubjectModel.fromJson(row)).toList());
  }

  @override
  Future<List<SubjectModel>> getSubjects(String userId) async {
    final rows = await _supabase
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .order('display_order', ascending: true);
    return rows.map((row) => SubjectModel.fromJson(row)).toList();
  }

  @override
  Future<List<SubjectModel>> getActiveSubjects(String userId) async {
    final rows = await _supabase
        .from('subjects')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('display_order', ascending: true);
    return rows.map((row) => SubjectModel.fromJson(row)).toList();
  }

  @override
  Future<SubjectModel> createSubject(SubjectModel subject) async {
    final response = await _supabase
        .from('subjects')
        .insert(subject.toJson())
        .select()
        .single();
    return SubjectModel.fromJson(response);
  }

  @override
  Future<SubjectModel> updateSubject(SubjectModel subject) async {
    final response = await _supabase
        .from('subjects')
        .update(subject.toJson())
        .eq('id', subject.id)
        .select()
        .single();
    return SubjectModel.fromJson(response);
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    await _supabase.from('subjects').delete().eq('id', subjectId);
  }
}

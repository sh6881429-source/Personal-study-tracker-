import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/chapter_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/domain/repositories/subject_repository.dart';
import 'package:prep_tracker/features/syllabus/domain/repositories/chapter_repository.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';

// ── Syllabus Stats ──

class SyllabusStats {
  const SyllabusStats({
    this.totalSubjects = 0,
    this.totalChapters = 0,
    this.completedChapters = 0,
    this.pendingChapters = 0,
    this.completionPercent = 0.0,
    this.revisionPercent = 0.0,
  });

  final int totalSubjects;
  final int totalChapters;
  final int completedChapters;
  final int pendingChapters;
  final double completionPercent;
  final double revisionPercent;
}

// ── Subjects Notifier ──

class SubjectsNotifier extends AsyncNotifier<List<SubjectModel>> {
  late SubjectRepository _repo;

  @override
  Future<List<SubjectModel>> build() async {
    _repo = ref.watch(subjectRepositoryProvider);
    final auth = ref.watch(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isEmpty) return [];
    return _repo.getSubjects(userId);
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authProvider);
      final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
      return _repo.getSubjects(userId);
    });
    _refreshDashboard();
  }

  Future<void> createSubject(SubjectModel subject) async {
    await AsyncValue.guard(() async {
      await _repo.createSubject(subject);
    });
    await reload();
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _repo.updateSubject(subject);
    await reload();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _repo.deleteSubject(subjectId);
    await reload();
  }

  Future<void> archiveSubject(SubjectModel subject) async {
    await _repo.updateSubject(subject.copyWith(isArchived: !subject.isArchived));
    await reload();
  }

  Future<void> reorderSubjects(List<SubjectModel> reordered) async {
    // Optimistic update
    state = AsyncValue.data(reordered);
    for (int i = 0; i < reordered.length; i++) {
      await _repo.updateSubject(reordered[i].copyWith(displayOrder: i));
    }
  }

  void _refreshDashboard() {
    ref.invalidate(homeControllerProvider);
  }
}

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<SubjectModel>>(
  SubjectsNotifier.new,
);

// ── Chapters Notifier ──

class ChaptersNotifier extends FamilyAsyncNotifier<List<ChapterModel>, String> {
  late ChapterRepository _repo;

  @override
  Future<List<ChapterModel>> build(String subjectId) async {
    _repo = ref.watch(chapterRepositoryProvider);
    if (subjectId.isEmpty) return [];
    return _repo.getChapters(subjectId);
  }

  Future<void> reload(String subjectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getChapters(subjectId));
    _refreshDashboard();
  }

  Future<void> addChapter(ChapterModel chapter) async {
    await _repo.createChapter(chapter);
    await reload(chapter.subjectId);
  }

  Future<void> updateChapter(ChapterModel chapter) async {
    await _repo.updateChapter(chapter);
    await reload(chapter.subjectId);
  }

  Future<void> deleteChapter(ChapterModel chapter) async {
    await _repo.deleteChapter(chapter.id);
    await reload(chapter.subjectId);
  }

  Future<void> toggleComplete(ChapterModel chapter) async {
    final updated = chapter.copyWith(
      isCompleted: !chapter.isCompleted,
      completedAt: !chapter.isCompleted ? DateTime.now() : null,
    );
    await _repo.updateChapter(updated);
    await reload(chapter.subjectId);
  }

  Future<void> incrementRevision(ChapterModel chapter) async {
    if (chapter.currentRevisions >= chapter.targetRevisions) return;
    await _repo.updateChapter(
      chapter.copyWith(currentRevisions: chapter.currentRevisions + 1),
    );
    await reload(chapter.subjectId);
  }

  Future<void> decrementRevision(ChapterModel chapter) async {
    if (chapter.currentRevisions <= 0) return;
    await _repo.updateChapter(
      chapter.copyWith(currentRevisions: chapter.currentRevisions - 1),
    );
    await reload(chapter.subjectId);
  }

  Future<void> reorderChapters(String subjectId, List<ChapterModel> reordered) async {
    state = AsyncValue.data(reordered);
    for (int i = 0; i < reordered.length; i++) {
      await _repo.updateChapter(reordered[i].copyWith(displayOrder: i));
    }
  }

  void _refreshDashboard() {
    ref.invalidate(homeControllerProvider);
    ref.invalidate(subjectsProvider);
  }
}

final chaptersProvider =
    AsyncNotifierProviderFamily<ChaptersNotifier, List<ChapterModel>, String>(
  ChaptersNotifier.new,
);

// ── Syllabus Stats Provider ──

final syllabusStatsProvider = Provider<SyllabusStats>((ref) {
  final subjectsAsync = ref.watch(subjectsProvider);
  return subjectsAsync.when(
    data: (subjects) {
      final active = subjects.where((s) => !s.isArchived).toList();
      return SyllabusStats(
        totalSubjects: active.length,
        totalChapters: 0, // Updated dynamically per screen
        completedChapters: 0,
        pendingChapters: 0,
        completionPercent: 0.0,
        revisionPercent: 0.0,
      );
    },
    loading: () => const SyllabusStats(),
    error: (_, __) => const SyllabusStats(),
  );
});

// ── Subject Search / Filter Provider ──

enum SubjectFilter { all, archived, recentlyUpdated, alphabetical }

final subjectSearchQueryProvider = StateProvider<String>((ref) => '');
final subjectFilterProvider = StateProvider<SubjectFilter>((ref) => SubjectFilter.all);

final filteredSubjectsProvider = Provider<List<SubjectModel>>((ref) {
  final subjectsAsync = ref.watch(subjectsProvider);
  final query = ref.watch(subjectSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(subjectFilterProvider);

  return subjectsAsync.when(
    data: (subjects) {
      List<SubjectModel> list;

      switch (filter) {
        case SubjectFilter.archived:
          list = subjects.where((s) => s.isArchived).toList();
          break;
        case SubjectFilter.alphabetical:
          list = subjects.where((s) => !s.isArchived).toList()
            ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
          break;
        case SubjectFilter.recentlyUpdated:
          list = subjects.where((s) => !s.isArchived).toList()
            ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
          break;
        case SubjectFilter.all:
        default:
          list = subjects.where((s) => !s.isArchived).toList();
      }

      if (query.isNotEmpty) {
        list = list.where((s) => s.subjectName.toLowerCase().contains(query)).toList();
      }

      return list;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ── Chapter Search / Filter Provider ──

enum ChapterFilter { all, completed, pending, mostRevised, leastRevised, alphabetical }

final chapterSearchQueryProvider = StateProvider.family<String, String>((ref, _) => '');
final chapterFilterProvider =
    StateProvider.family<ChapterFilter, String>((ref, _) => ChapterFilter.all);

final filteredChaptersProvider = Provider.family<List<ChapterModel>, String>((ref, subjectId) {
  final chaptersAsync = ref.watch(chaptersProvider(subjectId));
  final query = ref.watch(chapterSearchQueryProvider(subjectId)).trim().toLowerCase();
  final filter = ref.watch(chapterFilterProvider(subjectId));

  return chaptersAsync.when(
    data: (chapters) {
      List<ChapterModel> list;

      switch (filter) {
        case ChapterFilter.completed:
          list = chapters.where((c) => c.isCompleted).toList();
          break;
        case ChapterFilter.pending:
          list = chapters.where((c) => !c.isCompleted).toList();
          break;
        case ChapterFilter.mostRevised:
          list = List.from(chapters)
            ..sort((a, b) => b.currentRevisions.compareTo(a.currentRevisions));
          break;
        case ChapterFilter.leastRevised:
          list = List.from(chapters)
            ..sort((a, b) => a.currentRevisions.compareTo(b.currentRevisions));
          break;
        case ChapterFilter.alphabetical:
          list = List.from(chapters)
            ..sort((a, b) => a.chapterName.compareTo(b.chapterName));
          break;
        case ChapterFilter.all:
        default:
          list = chapters;
      }

      if (query.isNotEmpty) {
        list = list.where((c) => c.chapterName.toLowerCase().contains(query)).toList();
      }

      return list;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

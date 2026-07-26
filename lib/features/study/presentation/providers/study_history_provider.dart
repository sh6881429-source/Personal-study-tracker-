import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/domain/repositories/study_session_repository.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_timer_provider.dart';

@immutable
class StudyHistoryFilterState {
  const StudyHistoryFilterState({
    this.selectedSubjectId,
    this.selectedChapterId,
    this.selectedSessionType,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  final String? selectedSubjectId;
  final String? selectedChapterId;
  final String? selectedSessionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  StudyHistoryFilterState copyWith({
    String? selectedSubjectId,
    String? selectedChapterId,
    String? selectedSessionType,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearSubject = false,
    bool clearChapter = false,
    bool clearType = false,
    bool clearDates = false,
  }) {
    return StudyHistoryFilterState(
      selectedSubjectId: clearSubject ? null : (selectedSubjectId ?? this.selectedSubjectId),
      selectedChapterId: clearChapter ? null : (selectedChapterId ?? this.selectedChapterId),
      selectedSessionType: clearType ? null : (selectedSessionType ?? this.selectedSessionType),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class StudyHistoryFilterNotifier extends StateNotifier<StudyHistoryFilterState> {
  StudyHistoryFilterNotifier() : super(const StudyHistoryFilterState());

  void setSubjectId(String? id) => state = state.copyWith(selectedSubjectId: id, clearSubject: id == null, clearChapter: true);
  void setChapterId(String? id) => state = state.copyWith(selectedChapterId: id, clearChapter: id == null);
  void setSessionType(String? type) => state = state.copyWith(selectedSessionType: type, clearType: type == null);
  void setDateRange(DateTime? start, DateTime? end) => state = state.copyWith(startDate: start, endDate: end, clearDates: start == null);
  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void resetFilters() => state = const StudyHistoryFilterState();
}

final studyHistoryFilterProvider = StateNotifierProvider<StudyHistoryFilterNotifier, StudyHistoryFilterState>((ref) {
  return StudyHistoryFilterNotifier();
});

/// Returns list of all sessions filtered according to current filter state.
final filteredSessionsProvider = Provider<List<StudySessionModel>>((ref) {
  final asyncSessions = ref.watch(allSessionsProvider);
  final filter = ref.watch(studyHistoryFilterProvider);

  return asyncSessions.maybeWhen(
    data: (sessions) {
      return sessions.where((session) {
        if (filter.selectedSubjectId != null && session.subjectId != filter.selectedSubjectId) {
          return false;
        }
        if (filter.selectedChapterId != null && session.chapterId != filter.selectedChapterId) {
          return false;
        }
        if (filter.selectedSessionType != null && session.sessionType != filter.selectedSessionType) {
          return false;
        }
        if (filter.startDate != null) {
          if (session.studyDate.isBefore(filter.startDate!)) return false;
        }
        if (filter.endDate != null) {
          final endOfDay = filter.endDate!.add(const Duration(days: 1));
          if (session.studyDate.isAfter(endOfDay)) return false;
        }
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final notesMatch = session.sessionNotes?.toLowerCase().contains(query) ?? false;
          final typeMatch = session.sessionType.toLowerCase().contains(query);
          if (!notesMatch && !typeMatch) return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

/// Deletes a study session by ID and refreshes all study providers.
Future<void> deleteStudySession(WidgetRef ref, String sessionId) async {
  final repo = ref.read(studySessionRepositoryProvider);
  await repo.deleteSession(sessionId);
  refreshDashboardAndStats(ref);
  ref.invalidate(allSessionsProvider);
}

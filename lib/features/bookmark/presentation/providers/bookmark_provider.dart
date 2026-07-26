import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:prep_tracker/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';

/// ── Filter Option State ──
class BookmarkFilterState {
  const BookmarkFilterState({
    this.searchQuery = '',
    this.statusFilter = 'All', // 'All', 'Completed', 'Pending', 'Archived'
    this.pinnedOnly = false,
    this.highPriorityOnly = false,
    this.subjectId,
    this.date,
  });

  final String searchQuery;
  final String statusFilter;
  final bool pinnedOnly;
  final bool highPriorityOnly;
  final String? subjectId;
  final DateTime? date;

  BookmarkFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    bool? pinnedOnly,
    bool? highPriorityOnly,
    String? subjectId,
    DateTime? date,
    bool clearSubject = false,
    bool clearDate = false,
  }) {
    return BookmarkFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      pinnedOnly: pinnedOnly ?? this.pinnedOnly,
      highPriorityOnly: highPriorityOnly ?? this.highPriorityOnly,
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      date: clearDate ? null : (date ?? this.date),
    );
  }
}

/// Filter provider
final bookmarkFilterProvider = StateProvider<BookmarkFilterState>((ref) {
  return const BookmarkFilterState();
});

/// ── Sort Option State ──
enum BookmarkSortOption { newest, oldest, priority, alphabetical, pinnedFirst }

/// Sort provider
final bookmarkSortProvider = StateProvider<BookmarkSortOption>((ref) {
  return BookmarkSortOption.pinnedFirst;
});

/// ── Watch Stream Provider ──
/// Exposes the live stream of bookmarks from repository cache/remote.
final rawBookmarksProvider = StreamProvider<List<BookmarkModel>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return Stream.value([]);

  final repository = ref.watch(bookmarkRepositoryProvider);
  return repository.watchBookmarks(userId);
});

/// ── Filtered & Sorted Bookmarks Provider ──
/// Connects filters and sort states with the raw stream provider.
final filteredBookmarksProvider = Provider<List<BookmarkModel>>((ref) {
  final raw = ref.watch(rawBookmarksProvider).value ?? [];
  final filter = ref.watch(bookmarkFilterProvider);
  final sort = ref.watch(bookmarkSortProvider);

  var list = List<BookmarkModel>.from(raw);

  // Apply Search
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    list = list.where((item) {
      return item.title.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Apply Archive / Completion Status Filter
  if (filter.statusFilter == 'Archived') {
    list = list.where((item) => item.isArchived).toList();
  } else {
    // Hide archived by default for All, Completed, Pending
    list = list.where((item) => !item.isArchived).toList();

    if (filter.statusFilter == 'Completed') {
      list = list.where((item) => item.isCompleted).toList();
    } else if (filter.statusFilter == 'Pending') {
      list = list.where((item) => !item.isCompleted).toList();
    }
  }

  // Apply Pinned
  if (filter.pinnedOnly) {
    list = list.where((item) => item.isPinned).toList();
  }

  // Apply High Priority
  if (filter.highPriorityOnly) {
    list = list.where((item) => item.priority == 'High').toList();
  }

  // Apply Subject
  if (filter.subjectId != null) {
    list = list.where((item) => item.subjectId == filter.subjectId).toList();
  }

  // Apply Date
  if (filter.date != null) {
    final filterDay = DateTime(filter.date!.year, filter.date!.month, filter.date!.day);
    list = list.where((item) {
      if (item.createdAt == null) return false;
      final createdDay = DateTime(item.createdAt!.year, item.createdAt!.month, item.createdAt!.day);
      return createdDay.isAtSameMomentAs(filterDay);
    }).toList();
  }

  // Apply Sorting
  switch (sort) {
    case BookmarkSortOption.newest:
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      break;
    case BookmarkSortOption.oldest:
      list.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
      break;
    case BookmarkSortOption.alphabetical:
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case BookmarkSortOption.priority:
      // Map priority weights: High (3), Medium (2), Low (1)
      int weight(String priority) {
        if (priority == 'High') return 3;
        if (priority == 'Medium') return 2;
        return 1;
      }
      list.sort((a, b) => weight(b.priority).compareTo(weight(a.priority)));
      break;
    case BookmarkSortOption.pinnedFirst:
      // Pins first, then newest
      list.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
      });
      break;
  }

  return list;
});

/// ── Bookmark Controller (CRUD Actions Notifier) ──
class BookmarkController extends StateNotifier<bool> {
  BookmarkController(this._repository, this._ref) : super(false);

  final BookmarkRepository _repository;
  final Ref _ref;

  Future<void> addBookmark(BookmarkModel bookmark) async {
    state = true;
    try {
      await _repository.createBookmark(bookmark);
      if (mounted) {
        _ref.invalidate(rawBookmarksProvider);
        _ref.invalidate(homeControllerProvider); // update home count
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }

  Future<void> updateBookmark(BookmarkModel bookmark) async {
    state = true;
    try {
      await _repository.updateBookmark(bookmark);
      if (mounted) {
        _ref.invalidate(rawBookmarksProvider);
        _ref.invalidate(homeControllerProvider);
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }

  Future<void> togglePin(BookmarkModel bookmark) async {
    final updated = bookmark.copyWith(isPinned: !bookmark.isPinned);
    await updateBookmark(updated);
  }

  Future<void> toggleComplete(BookmarkModel bookmark) async {
    final updated = bookmark.copyWith(isCompleted: !bookmark.isCompleted);
    await updateBookmark(updated);
  }

  Future<void> toggleArchive(BookmarkModel bookmark) async {
    final updated = bookmark.copyWith(isArchived: !bookmark.isArchived);
    await updateBookmark(updated);
  }

  Future<void> deleteBookmark(String id) async {
    state = true;
    try {
      await _repository.deleteBookmark(id);
      if (mounted) {
        _ref.invalidate(rawBookmarksProvider);
        _ref.invalidate(homeControllerProvider);
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }

  Future<void> duplicateBookmark(BookmarkModel bookmark) async {
    final copy = bookmark.copyWith(
      id: const Uuid().v4(),
      title: '${bookmark.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await addBookmark(copy);
  }

  Future<void> syncOfflineQueue() async {
    final auth = _ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isNotEmpty) {
      await _repository.syncQueue(userId);
      _ref.invalidate(rawBookmarksProvider);
    }
  }
}

/// Provider for controller actions
final bookmarkControllerProvider = StateNotifierProvider<BookmarkController, bool>((ref) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return BookmarkController(repo, ref);
});

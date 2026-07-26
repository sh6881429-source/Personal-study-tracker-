import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';

/// ── Bookmark Repository Contract ──
abstract interface class BookmarkRepository {
  /// Stream of bookmarks for a user, sorted by priority and pinned state.
  Stream<List<BookmarkModel>> watchBookmarks(String userId);

  /// Fetch all bookmarks.
  Future<List<BookmarkModel>> getBookmarks(String userId);

  /// Fetch bookmarks tagged to a specific subject.
  Future<List<BookmarkModel>> getBookmarksBySubject(String subjectId);

  /// Create a bookmark link/reference.
  Future<BookmarkModel> createBookmark(BookmarkModel bookmark);

  /// Update bookmark values (pinned, completion, details).
  Future<BookmarkModel> updateBookmark(BookmarkModel bookmark);

  /// Delete a bookmark.
  Future<void> deleteBookmark(String bookmarkId);

  /// Synchronizes any pending offline modifications with Supabase.
  Future<void> syncQueue(String userId);
}

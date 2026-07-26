import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Provider for BookmarkRepository implementation.
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepositoryImpl();
});

/// ── Bookmark Repository Implementation ──
/// Implements offline-first caching and automatic synchronization.
class BookmarkRepositoryImpl implements BookmarkRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  static String _cacheKey(String userId) => 'cached_bookmarks_$userId';
  static String _queueKey(String userId) => 'pending_bookmark_sync_$userId';

  // ── Local Cache Helpers ──
  List<BookmarkModel> _getLocalCache(String userId) {
    final cachedData = StorageService.getString(_cacheKey(userId));
    if (cachedData == null) return [];
    try {
      final decoded = jsonDecode(cachedData) as List;
      return decoded.map((item) => BookmarkModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _setLocalCache(String userId, List<BookmarkModel> list) async {
    final encoded = jsonEncode(list.map((item) => item.toJson()).toList());
    await StorageService.setString(_cacheKey(userId), encoded);
  }

  // ── Offline Operations Queue Helpers ──
  List<Map<String, dynamic>> _getSyncQueue(String userId) {
    final queueData = StorageService.getString(_queueKey(userId));
    if (queueData == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(queueData) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _setSyncQueue(String userId, List<Map<String, dynamic>> queue) async {
    await StorageService.setString(_queueKey(userId), jsonEncode(queue));
  }

  Future<void> _addToQueue(String userId, String action, BookmarkModel bookmark) async {
    final queue = _getSyncQueue(userId);
    // Remove existing queue actions for the same bookmark ID to avoid redundant requests
    queue.removeWhere((item) => item['bookmark']['id'] == bookmark.id);
    queue.add({
      'action': action,
      'bookmark': bookmark.toJson(),
    });
    await _setSyncQueue(userId, queue);
  }

  // ── Realtime Stream ──
  @override
  Stream<List<BookmarkModel>> watchBookmarks(String userId) {
    final controller = StreamController<List<BookmarkModel>>();

    // Emit cached values immediately
    final cached = _getLocalCache(userId);
    controller.add(cached);

    // Initial fetch and synchronization runner
    _syncWithRemote(userId, controller).catchError((err) {
      if (!controller.isClosed) {
        controller.addError(err);
      }
    });

    // Setup Supabase realtime subscriptions
    final channel = _supabase
        .channel('public:bookmarks:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookmarks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _syncWithRemote(userId, controller).catchError((_) {});
          },
        );
    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _syncWithRemote(String userId, StreamController<List<BookmarkModel>> controller) async {
    // Process offline sync queue if anything is pending
    await syncQueue(userId);

    // Fetch latest bookmarks from server
    try {
      final remoteList = await getBookmarks(userId);
      if (!controller.isClosed) {
        controller.add(remoteList);
      }
    } catch (e) {
      // If network fails, re-emit cached to prevent error states
      final cached = _getLocalCache(userId);
      if (!controller.isClosed) {
        controller.add(cached);
      }
    }
  }

  @override
  Future<List<BookmarkModel>> getBookmarks(String userId) async {
    try {
      final rows = await _supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      final list = rows.map((row) => BookmarkModel.fromJson(row)).toList();
      await _setLocalCache(userId, list);
      return list;
    } catch (e) {
      // Return cached version when offline
      final cached = _getLocalCache(userId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<List<BookmarkModel>> getBookmarksBySubject(String subjectId) async {
    final rows = await _supabase
        .from('bookmarks')
        .select()
        .eq('subject_id', subjectId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => BookmarkModel.fromJson(row)).toList();
  }

  @override
  Future<BookmarkModel> createBookmark(BookmarkModel bookmark) async {
    final userId = bookmark.userId;
    // Optimistic UI updates
    final localList = _getLocalCache(userId);
    final updatedList = [bookmark, ...localList];
    await _setLocalCache(userId, updatedList);

    try {
      final response = await _supabase
          .from('bookmarks')
          .insert(bookmark.toJson())
          .select()
          .single();
      final saved = BookmarkModel.fromJson(response);
      
      // Update cache with server details
      final currentList = _getLocalCache(userId);
      final index = currentList.indexWhere((item) => item.id == bookmark.id);
      if (index != -1) {
        currentList[index] = saved;
        await _setLocalCache(userId, currentList);
      }
      return saved;
    } catch (e) {
      // Add to offline sync queue
      await _addToQueue(userId, 'create', bookmark);
      return bookmark;
    }
  }

  @override
  Future<BookmarkModel> updateBookmark(BookmarkModel bookmark) async {
    final userId = bookmark.userId;
    // Optimistic UI updates
    final localList = _getLocalCache(userId);
    final index = localList.indexWhere((item) => item.id == bookmark.id);
    if (index != -1) {
      localList[index] = bookmark;
      await _setLocalCache(userId, localList);
    }

    try {
      final response = await _supabase
          .from('bookmarks')
          .update(bookmark.toJson())
          .eq('id', bookmark.id)
          .select()
          .single();
      final saved = BookmarkModel.fromJson(response);
      return saved;
    } catch (e) {
      // Add to offline sync queue
      await _addToQueue(userId, 'update', bookmark);
      return bookmark;
    }
  }

  @override
  Future<void> deleteBookmark(String bookmarkId) async {
    final authUser = _supabase.auth.currentUser;
    final userId = authUser?.id ?? '';
    if (userId.isNotEmpty) {
      final localList = _getLocalCache(userId);
      localList.removeWhere((item) => item.id == bookmarkId);
      await _setLocalCache(userId, localList);
    }

    try {
      await _supabase.from('bookmarks').delete().eq('id', bookmarkId);
    } catch (e) {
      if (userId.isNotEmpty) {
        // Queue the deletion offline
        final dummyBookmark = BookmarkModel(id: bookmarkId, userId: userId, title: '');
        await _addToQueue(userId, 'delete', dummyBookmark);
      }
    }
  }

  // ── Sync Queue Processor ──
  @override
  Future<void> syncQueue(String userId) async {
    final queue = _getSyncQueue(userId);
    if (queue.isEmpty) return;

    final failedList = <Map<String, dynamic>>[];

    for (final item in queue) {
      final action = item['action'] as String;
      final bookmarkJson = item['bookmark'] as Map<String, dynamic>;
      final bookmark = BookmarkModel.fromJson(bookmarkJson);

      try {
        if (action == 'create') {
          await _supabase.from('bookmarks').insert(bookmark.toJson());
        } else if (action == 'update') {
          await _supabase.from('bookmarks').update(bookmark.toJson()).eq('id', bookmark.id);
        } else if (action == 'delete') {
          await _supabase.from('bookmarks').delete().eq('id', bookmark.id);
        }
      } catch (_) {
        failedList.add(item);
      }
    }

    await _setSyncQueue(userId, failedList);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/pdf/domain/repositories/pdf_repository.dart';

/// Provider for PdfRepository implementation.
final pdfRepositoryProvider = Provider<PdfRepository>((ref) {
  return PdfRepositoryImpl();
});

/// ── PDF Repository Implementation ──
/// Handles file storage operations and offline caching.
class PdfRepositoryImpl implements PdfRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  static String _cacheKey(String userId) => 'cached_pdfs_$userId';

  // ── Cache Helpers ──
  List<PdfModel> _getLocalCache(String userId) {
    final data = StorageService.getString(_cacheKey(userId));
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map((item) => PdfModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _setLocalCache(String userId, List<PdfModel> list) async {
    final encoded = jsonEncode(list.map((item) => item.toJson()).toList());
    await StorageService.setString(_cacheKey(userId), encoded);
  }

  // Helper to resolve local cached file path for offline use
  Future<String> getLocalPath(String storagePath) async {
    if (kIsWeb) {
      return storagePath; // Web doesn't use path_provider filesystem
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$storagePath';
  }

  Future<bool> isDownloaded(String storagePath) async {
    if (kIsWeb) return false; // Web doesn't support local download cache files
    final path = await getLocalPath(storagePath);
    return File(path).existsSync();
  }

  @override
  Stream<List<PdfModel>> watchPdfs(String userId) {
    final controller = StreamController<List<PdfModel>>();

    // Emit cached values immediately
    final cached = _getLocalCache(userId);
    controller.add(cached);

    // Initial fetch from DB
    _syncRemote(userId, controller).catchError((Object err) {
      if (!controller.isClosed) {
        controller.addError(err);
      }
    });

    // Supabase realtime listener
    final channel = _supabase
        .channel('public:pdf_library:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pdf_library',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _syncRemote(userId, controller).catchError((_) {});
          },
        );
    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _syncRemote(String userId, StreamController<List<PdfModel>> controller) async {
    try {
      final remoteList = await getPdfs(userId);
      if (!controller.isClosed) {
        controller.add(remoteList);
      }
    } catch (_) {
      final cached = _getLocalCache(userId);
      if (!controller.isClosed) {
        controller.add(cached);
      }
    }
  }

  @override
  Future<List<PdfModel>> getPdfs(String userId) async {
    try {
      final rows = await _supabase
          .from('pdf_library')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = rows.map((row) => PdfModel.fromJson(row)).toList();
      await _setLocalCache(userId, list);
      return list;
    } catch (_) {
      final cached = _getLocalCache(userId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<PdfModel> uploadPdf({
    required String userId,
    required String subjectId,
    required List<int> fileBytes,
    required String originalName,
    int? pageCount,
  }) async {
    final fileExtension = originalName.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${originalName.split('.').first}_$timestamp.$fileExtension';
    final storagePath = '$userId/$subjectId/$fileName';

    // 1. Upload binary data to Supabase Storage
    await _supabase.storage.from('study-pdfs').uploadBinary(
          storagePath,
          Uint8List.fromList(fileBytes),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // 2. Insert record in DB
    final jsonRecord = {
      'user_id': userId,
      'subject_id': subjectId,
      'file_name': fileName,
      'original_name': originalName,
      'storage_path': storagePath,
      'file_size': fileBytes.length,
      if (pageCount != null) 'page_count': pageCount,
      'is_favorite': false,
    };

    final response = await _supabase
        .from('pdf_library')
        .insert(jsonRecord)
        .select()
        .single();

    final saved = PdfModel.fromJson(response);

    // 3. Save copy to local file cache (Mobile/Desktop only)
    if (!kIsWeb) {
      try {
        final localPath = await getLocalPath(storagePath);
        final localFile = File(localPath);
        if (!localFile.parent.existsSync()) {
          localFile.parent.createSync(recursive: true);
        }
        await localFile.writeAsBytes(fileBytes);
      } catch (_) {}
    }

    return saved;
  }

  @override
  Future<File?> downloadPdf(String storagePath) async {
    if (kIsWeb) {
      // Trigger Web browser download via signed URL
      final signedUrl = await _supabase.storage.from('study-pdfs').createSignedUrl(storagePath, 60);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return null;
    }

    final localPath = await getLocalPath(storagePath);
    final localFile = File(localPath);

    // If already downloaded, return it immediately
    if (localFile.existsSync()) {
      return localFile;
    }

    // Otherwise download from bucket
    final bytes = await _supabase.storage.from('study-pdfs').download(storagePath);
    if (!localFile.parent.existsSync()) {
      localFile.parent.createSync(recursive: true);
    }
    await localFile.writeAsBytes(bytes);
    return localFile;
  }

  @override
  Future<List<int>> downloadBytes(String storagePath) async {
    return await _supabase.storage.from('study-pdfs').download(storagePath);
  }

  @override
  Future<PdfModel> updatePdf(PdfModel pdf) async {
    final response = await _supabase
        .from('pdf_library')
        .update(pdf.toJson())
        .eq('id', pdf.id)
        .select()
        .single();
    return PdfModel.fromJson(response);
  }

  @override
  Future<void> deletePdf(String pdfId, String storagePath) async {
    // 1. Delete from DB
    await _supabase.from('pdf_library').delete().eq('id', pdfId);

    // 2. Delete from Supabase Storage
    try {
      await _supabase.storage.from('study-pdfs').remove([storagePath]);
    } catch (_) {}

    // 3. Delete local cache file if exists (Mobile/Desktop only)
    if (!kIsWeb) {
      try {
        final path = await getLocalPath(storagePath);
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
  }
}

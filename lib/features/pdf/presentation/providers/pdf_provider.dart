import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/pdf/data/repositories/pdf_repository_impl.dart';
import 'package:prep_tracker/features/pdf/domain/repositories/pdf_repository.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';

/// ── Filter Option State ──
class PdfFilterState {
  const PdfFilterState({
    this.searchQuery = '',
    this.favoritesOnly = false,
    this.recentlyOpenedOnly = false,
    this.subjectId,
  });

  final String searchQuery;
  final bool favoritesOnly;
  final bool recentlyOpenedOnly;
  final String? subjectId;

  PdfFilterState copyWith({
    String? searchQuery,
    bool? favoritesOnly,
    bool? recentlyOpenedOnly,
    String? subjectId,
    bool clearSubject = false,
  }) {
    return PdfFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      recentlyOpenedOnly: recentlyOpenedOnly ?? this.recentlyOpenedOnly,
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
    );
  }
}

/// Filter provider
final pdfFilterProvider = StateProvider<PdfFilterState>((ref) {
  return const PdfFilterState();
});

/// ── Sort Option State ──
enum PdfSortOption {
  newest,
  oldest,
  alphabetical,
  fileSize,
  fileSizeSmallest,
  favorites,
  recentlyOpened,
}

/// Sort provider
final pdfSortProvider = StateProvider<PdfSortOption>((ref) {
  return PdfSortOption.newest;
});

/// ── Watch Stream Provider ──
final rawPdfsProvider = StreamProvider<List<PdfModel>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
  if (userId.isEmpty) return Stream.value([]);

  final repository = ref.watch(pdfRepositoryProvider);
  return repository.watchPdfs(userId);
});

/// ── Filtered & Sorted PDFs Provider ──
final filteredPdfsProvider = Provider<List<PdfModel>>((ref) {
  final raw = ref.watch(rawPdfsProvider).value ?? [];
  final filter = ref.watch(pdfFilterProvider);
  final sort = ref.watch(pdfSortProvider);

  var list = List<PdfModel>.from(raw);

  // Apply Search
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    list = list.where((item) {
      return item.originalName.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Apply Favorite Filter
  if (filter.favoritesOnly) {
    list = list.where((item) => item.isFavorite).toList();
  }

  // Apply Recently Opened Filter
  if (filter.recentlyOpenedOnly) {
    list = list.where((item) => item.lastOpened != null).toList();
  }

  // Apply Subject Filter
  if (filter.subjectId != null) {
    list = list.where((item) => item.subjectId == filter.subjectId).toList();
  }

  // Apply Sorting
  switch (sort) {
    case PdfSortOption.newest:
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      break;
    case PdfSortOption.oldest:
      list.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      break;
    case PdfSortOption.alphabetical:
      list.sort((a, b) => a.originalName.toLowerCase().compareTo(b.originalName.toLowerCase()));
      break;
    case PdfSortOption.fileSize:
      // Largest first
      list.sort((a, b) => b.fileSize.compareTo(a.fileSize));
      break;
    case PdfSortOption.fileSizeSmallest:
      // Smallest first
      list.sort((a, b) => a.fileSize.compareTo(b.fileSize));
      break;
    case PdfSortOption.favorites:
      list.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
      });
      break;
    case PdfSortOption.recentlyOpened:
      list.sort((a, b) {
        if (a.lastOpened == null && b.lastOpened == null) return 0;
        if (a.lastOpened == null) return 1;
        if (b.lastOpened == null) return -1;
        return b.lastOpened!.compareTo(a.lastOpened!);
      });
      break;
  }

  return list;
});

/// ── Download Status Model ──
enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadProgress {
  const DownloadProgress({
    required this.status,
    required this.progress, // value between 0.0 and 1.0
    this.localPath,
    this.errorMessage,
  });

  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final String? errorMessage;
}

/// Active downloads progress notifier map.
class PdfDownloadsNotifier extends StateNotifier<Map<String, DownloadProgress>> {
  PdfDownloadsNotifier(this._repository) : super({});

  final PdfRepository _repository;

  Future<void> downloadFile(PdfModel pdf) async {
    final pdfId = pdf.id;
    final repo = _repository as PdfRepositoryImpl;

    // Check if already downloaded
    final exists = await repo.isDownloaded(pdf.storagePath);
    if (exists) {
      final path = await repo.getLocalPath(pdf.storagePath);
      if (mounted) {
        state = {
          ...state,
          pdfId: DownloadProgress(
            status: DownloadStatus.downloaded,
            progress: 1.0,
            localPath: path,
          ),
        };
      }
      return;
    }

    // Set downloading state
    if (mounted) {
      state = {
        ...state,
        pdfId: const DownloadProgress(
          status: DownloadStatus.downloading,
          progress: 0.1,
        ),
      };
    }

    try {
      // Simulate download increments
      for (double i = 0.2; i < 0.9; i += 0.15) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          state = {
            ...state,
            pdfId: DownloadProgress(
              status: DownloadStatus.downloading,
              progress: i,
            ),
          };
        }
      }

      final file = await _repository.downloadPdf(pdf.storagePath);

      if (mounted) {
        state = {
          ...state,
          pdfId: DownloadProgress(
            status: DownloadStatus.downloaded,
            progress: 1.0,
            localPath: file?.path ?? 'web',
          ),
        };
      }
    } catch (e) {
      if (mounted) {
        state = {
          ...state,
          pdfId: DownloadProgress(
            status: DownloadStatus.failed,
            progress: 0.0,
            errorMessage: e.toString(),
          ),
        };
      }
    }
  }

  Future<void> checkDownloadStatus(PdfModel pdf) async {
    final pdfId = pdf.id;
    final repo = _repository as PdfRepositoryImpl;
    final exists = await repo.isDownloaded(pdf.storagePath);

    if (exists) {
      final path = await repo.getLocalPath(pdf.storagePath);
      if (mounted) {
        state = {
          ...state,
          pdfId: DownloadProgress(
            status: DownloadStatus.downloaded,
            progress: 1.0,
            localPath: path,
          ),
        };
      }
    } else {
      if (mounted) {
        state = {
          ...state,
          pdfId: const DownloadProgress(
            status: DownloadStatus.notDownloaded,
            progress: 0.0,
          ),
        };
      }
    }
  }
}

/// Provider for PDF downloading states
final pdfDownloadsProvider =
    StateNotifierProvider<PdfDownloadsNotifier, Map<String, DownloadProgress>>((ref) {
  final repo = ref.watch(pdfRepositoryProvider);
  return PdfDownloadsNotifier(repo);
});

/// ── PDF Library Controller (Upload, Favorites, Delete, Edits) ──
class PdfController extends StateNotifier<bool> {
  PdfController(this._repository, this._ref) : super(false);

  final PdfRepository _repository;
  final Ref _ref;

  Future<void> uploadPdf({
    required String subjectId,
    required List<int> fileBytes,
    required String originalName,
    int? pageCount,
    String? description,
  }) async {
    state = true;
    try {
      final auth = _ref.read(authProvider);
      final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
      if (userId.isEmpty) return;

      final response = await _repository.uploadPdf(
        userId: userId,
        subjectId: subjectId,
        fileBytes: fileBytes,
        originalName: originalName,
        pageCount: pageCount,
      );

      // Save description if provided
      if (description != null && description.isNotEmpty) {
        await updatePdf(response.copyWith(description: description));
      }

      if (mounted) {
        _ref.invalidate(rawPdfsProvider);
        _ref.invalidate(homeControllerProvider); // sync recent pdf counts
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }

  Future<void> updatePdf(PdfModel pdf) async {
    state = true;
    try {
      await _repository.updatePdf(pdf);
      if (mounted) {
        _ref.invalidate(rawPdfsProvider);
        _ref.invalidate(homeControllerProvider);
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }

  Future<void> toggleFavorite(PdfModel pdf) async {
    final updated = pdf.copyWith(isFavorite: !pdf.isFavorite);
    await updatePdf(updated);
  }

  Future<void> renamePdf(PdfModel pdf, String newName) async {
    final name = newName.endsWith('.pdf') ? newName : '$newName.pdf';
    final updated = pdf.copyWith(originalName: name);
    await updatePdf(updated);
  }

  Future<void> editDescription(PdfModel pdf, String desc) async {
    final updated = pdf.copyWith(description: desc.trim().isEmpty ? null : desc.trim());
    await updatePdf(updated);
  }

  Future<void> moveSubject(PdfModel pdf, String subjectId) async {
    final updated = pdf.copyWith(subjectId: subjectId);
    await updatePdf(updated);
  }

  Future<void> markOpened(PdfModel pdf) async {
    final updated = pdf.copyWith(lastOpened: DateTime.now());
    await updatePdf(updated);
  }

  Future<void> deletePdf(PdfModel pdf) async {
    state = true;
    try {
      await _repository.deletePdf(pdf.id, pdf.storagePath);
      if (mounted) {
        _ref.invalidate(rawPdfsProvider);
        _ref.invalidate(homeControllerProvider);
      }
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }
}

/// Controller provider
final pdfControllerProvider = StateNotifierProvider<PdfController, bool>((ref) {
  final repo = ref.watch(pdfRepositoryProvider);
  return PdfController(repo, ref);
});

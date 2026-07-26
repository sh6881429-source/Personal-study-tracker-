import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/pdf/data/repositories/pdf_repository_impl.dart';
import 'package:prep_tracker/features/pdf/presentation/providers/pdf_provider.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({super.key, required this.pdf});
  final PdfModel pdf;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late PdfViewerController _pdfController;
  PdfTextSearchResult? _searchResult;
  final TextEditingController _searchFieldController = TextEditingController();
  final TextEditingController _pageInputController = TextEditingController();

  bool _isLoading = true;
  Uint8List? _pdfBytes;
  String? _errorMessage;
  bool _isFullscreen = false;
  bool _isSearchActive = false;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _loadPdfBytes();
  }

  Future<void> _loadPdfBytes() async {
    final repo = ref.read(pdfRepositoryProvider) as PdfRepositoryImpl;

    try {
      // 1. Check if the file is cached locally
      final localExists = await repo.isDownloaded(widget.pdf.storagePath);
      if (localExists) {
        final path = await repo.getLocalPath(widget.pdf.storagePath);
        final file = File(path);
        final bytes = await file.readAsBytes();
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
        // Update last opened timestamp in remote db
        ref.read(pdfControllerProvider.notifier).markOpened(widget.pdf);
        return;
      }

      // 2. Otherwise download bytes directly from Supabase storage
      final bytesList = await repo.downloadBytes(widget.pdf.storagePath);
      setState(() {
        _pdfBytes = bytesList is Uint8List ? bytesList : Uint8List.fromList(bytesList);
        _isLoading = false;
      });
      // Update last opened timestamp in remote db
      ref.read(pdfControllerProvider.notifier).markOpened(widget.pdf);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF file: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _searchFieldController.dispose();
    _pageInputController.dispose();
    // Restore system UI on close
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
  }

  void _jumpToPage() {
    final page = int.tryParse(_pageInputController.text);
    if (page != null && page > 0 && page <= _totalPages) {
      _pdfController.jumpToPage(page);
    }
    _pageInputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Read last page index from persistent SharedPreferences
    final lastReadPageKey = 'last_read_page_${widget.pdf.id}';
    final initialPage = StorageService.getInt(lastReadPageKey) ?? 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                _isSearchActive ? '' : widget.pdf.originalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.text,
                ),
              ),
              centerTitle: false,
              actions: [
                // Text Search Toggle
                if (_isSearchActive)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 48, right: 8),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchFieldController,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Search text...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (text) {
                                  if (text.trim().isNotEmpty) {
                                    setState(() {
                                      _searchResult = _pdfController.searchText(text.trim());
                                    });
                                  }
                                },
                              ),
                            ),
                            if (_searchResult != null) ...[
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.keyboard_arrow_left_rounded),
                                onPressed: () => _searchResult?.previousInstance(),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.keyboard_arrow_right_rounded),
                                onPressed: () => _searchResult?.nextInstance(),
                              ),
                            ],
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                setState(() {
                                  _isSearchActive = false;
                                  _searchResult?.clear();
                                  _searchResult = null;
                                  _searchFieldController.clear();
                                });
                                _pdfController.clearSelection();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppColors.text),
                    onPressed: () {
                      setState(() {
                        _isSearchActive = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      color: AppColors.text,
                    ),
                    onPressed: _toggleFullscreen,
                  ),
                ],
              ],
            ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Opening document...',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFFF5C8A)),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD93D),
                              foregroundColor: AppColors.text,
                              elevation: 0,
                              side: const BorderSide(color: AppColors.border, width: 2),
                            ),
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _loadPdfBytes();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : () {
                    final isImage = widget.pdf.originalName.toLowerCase().endsWith('.jpg') ||
                        widget.pdf.originalName.toLowerCase().endsWith('.jpeg') ||
                        widget.pdf.originalName.toLowerCase().endsWith('.png') ||
                        widget.pdf.originalName.toLowerCase().endsWith('.webp');

                    if (isImage) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.memory(
                              _pdfBytes!,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image_rounded, size: 64, color: AppColors.error),
                                    const SizedBox(height: 12),
                                    Text('Unable to display image document: $err'),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        // PDF Render
                        SfPdfViewer.memory(
                          _pdfBytes!,
                          controller: _pdfController,
                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            setState(() {
                              _totalPages = details.document.pages.count;
                            });
                            // Restore last read page if valid
                            if (initialPage > 1 && initialPage <= _totalPages) {
                              _pdfController.jumpToPage(initialPage);
                            }
                          },
                          onPageChanged: (PdfPageChangedDetails details) {
                            setState(() {
                              _currentPage = details.newPageNumber;
                            });
                            // Cache current page number locally
                            StorageService.setInt(lastReadPageKey, details.newPageNumber);
                          },
                        ),

                        // Floating Page Jump & Zoom HUD panel at the bottom center
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Page counter
                                  Text(
                                    '$_currentPage / $_totalPages',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Container(width: 1.5, height: 18, color: AppColors.border),
                                  const SizedBox(width: 14),

                                  // Page Input Form
                                  SizedBox(
                                    width: 40,
                                    height: 28,
                                    child: TextField(
                                      controller: _pageInputController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Go',
                                        hintStyle: GoogleFonts.inter(fontSize: 10),
                                        contentPadding: EdgeInsets.zero,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                                        ),
                                      ),
                                      onSubmitted: (_) => _jumpToPage(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Zoom Controls
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.zoom_in_rounded, size: 20),
                                    onPressed: () => _pdfController.zoomLevel = (_pdfController.zoomLevel + 0.25).clamp(1.0, 3.0),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.zoom_out_rounded, size: 20),
                                    onPressed: () => _pdfController.zoomLevel = (_pdfController.zoomLevel - 0.25).clamp(1.0, 3.0),
                                  ),

                                  // Fullscreen toggler in HUD when fullscreen
                                  if (_isFullscreen) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                                      onPressed: _toggleFullscreen,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/pdf/presentation/providers/pdf_provider.dart';
import 'package:prep_tracker/features/pdf/presentation/widgets/pdf_widgets.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';

class PdfScreen extends ConsumerStatefulWidget {
  const PdfScreen({super.key});

  @override
  ConsumerState<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends ConsumerState<PdfScreen> {
  final TextEditingController _searchController = TextEditingController();
  SubjectModel? _activeSubjectFolder; // if null, show folder directories. Otherwise list documents inside.
  List<SubjectModel> _subjectsList = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final auth = ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isNotEmpty) {
      final list = await ref.read(subjectRepositoryProvider).getActiveSubjects(userId);
      setState(() {
        _subjectsList = list;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet() {
    final activeSort = ref.read(pdfSortProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border, width: 3),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sort Documents By',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                _SortOptionItem(
                  label: 'Newest Uploaded First',
                  selected: activeSort == PdfSortOption.newest,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.newest;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Oldest Uploaded First',
                  selected: activeSort == PdfSortOption.oldest,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.oldest;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Alphabetical A-Z',
                  selected: activeSort == PdfSortOption.alphabetical,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.alphabetical;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'File Size (Largest)',
                  selected: activeSort == PdfSortOption.fileSize,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.fileSize;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'File Size (Smallest)',
                  selected: activeSort == PdfSortOption.fileSizeSmallest,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.fileSizeSmallest;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Recently Opened First',
                  selected: activeSort == PdfSortOption.recentlyOpened,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.recentlyOpened;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Favorites First',
                  selected: activeSort == PdfSortOption.favorites,
                  onTap: () {
                    ref.read(pdfSortProvider.notifier).state = PdfSortOption.favorites;
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfList = ref.watch(filteredPdfsProvider);
    final rawAsync = ref.watch(rawPdfsProvider);
    final filter = ref.watch(pdfFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6E8), // Warm beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _activeSubjectFolder != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text),
                onPressed: () {
                  setState(() {
                    _activeSubjectFolder = null;
                  });
                  ref.read(pdfFilterProvider.notifier).state = filter.copyWith(subjectId: null, clearSubject: true);
                },
              )
            : null,
        title: Text(
          _activeSubjectFolder != null ? _activeSubjectFolder!.subjectName : 'PDF Library',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.text,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.text),
            onPressed: () => ref.invalidate(rawPdfsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.text),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.text, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search documents by title...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.text.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) {
                        ref.read(pdfFilterProvider.notifier).state =
                            filter.copyWith(searchQuery: val.trim());
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref.read(pdfFilterProvider.notifier).state =
                            filter.copyWith(searchQuery: '');
                      },
                      child: const Icon(Icons.clear_rounded, color: AppColors.text, size: 18),
                    ),
                ],
              ),
            ),
          ),

          // ── Horizontal Filter Row ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _StatusChip(
                  label: 'All Documents',
                  isSelected: !filter.favoritesOnly && !filter.recentlyOpenedOnly,
                  onTap: () => ref.read(pdfFilterProvider.notifier).state =
                      filter.copyWith(favoritesOnly: false, recentlyOpenedOnly: false),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: '⭐ Favorites',
                  isSelected: filter.favoritesOnly,
                  onTap: () => ref.read(pdfFilterProvider.notifier).state =
                      filter.copyWith(favoritesOnly: true, recentlyOpenedOnly: false),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: '🕒 Recently Opened',
                  isSelected: filter.recentlyOpenedOnly,
                  onTap: () => ref.read(pdfFilterProvider.notifier).state =
                      filter.copyWith(recentlyOpenedOnly: true, favoritesOnly: false),
                ),
              ],
            ),
          ),

          // ── Folders or Documents view ──
          Expanded(
            child: rawAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (pdfs) {
                // If search query is typed, or favorite/recentlyOpened is toggled, bypass folders layout to show flat list search
                final isSearching = filter.searchQuery.isNotEmpty ||
                    filter.favoritesOnly ||
                    filter.recentlyOpenedOnly;

                if (_activeSubjectFolder == null && !isSearching) {
                  // Render directories list (folders)
                  if (_subjectsList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 64, color: AppColors.text),
                            SizedBox(height: 12),
                            Text(
                              'No subject folders!',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Create subjects in the Syllabus tab first to seed PDF folders.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: _subjectsList.length,
                    itemBuilder: (context, idx) {
                      final sub = _subjectsList[idx];
                      final count = pdfs.where((pdf) => pdf.subjectId == sub.id).length;

                      return SubjectFolderCard(
                        subject: sub,
                        pdfCount: count,
                        onTap: () {
                          setState(() {
                            _activeSubjectFolder = sub;
                          });
                          ref.read(pdfFilterProvider.notifier).state =
                              filter.copyWith(subjectId: sub.id);
                        },
                        onDeletePressed: () {
                          _loadSubjects();
                        },
                      );
                    },
                  );
                } else {
                  // Render specific subject document tiles
                  final folderPdfs = pdfList;

                  if (folderPdfs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.text),
                            SizedBox(height: 12),
                            Text(
                              'Folder is empty!',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Click the FAB below to upload reference books and study materials to this folder.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: folderPdfs.length,
                    itemBuilder: (context, idx) {
                      return PdfFileTile(pdf: folderPdfs[idx]);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _subjectsList.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFFD93D),
              foregroundColor: AppColors.text,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 3),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const PdfUploadDialog(),
                );
              },
              child: const Icon(Icons.upload_file_rounded, size: 28),
            )
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD93D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _SortOptionItem extends StatelessWidget {
  const _SortOptionItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFC7D2FE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ListTile(
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.text,
          ),
        ),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.text) : null,
        onTap: onTap,
      ),
    );
  }
}

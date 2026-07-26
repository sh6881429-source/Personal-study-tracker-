import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/bookmark/presentation/providers/bookmark_provider.dart';
import 'package:prep_tracker/features/bookmark/presentation/widgets/bookmark_widgets.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key});

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SubjectModel> _subjectsList = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    // Run initial offline sync check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookmarkControllerProvider.notifier).syncOfflineQueue();
    });
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
    final activeSort = ref.read(bookmarkSortProvider);

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
                  'Sort Notes By',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                _SortOptionItem(
                  label: 'Pinned First (Default)',
                  selected: activeSort == BookmarkSortOption.pinnedFirst,
                  onTap: () {
                    ref.read(bookmarkSortProvider.notifier).state = BookmarkSortOption.pinnedFirst;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Newest First',
                  selected: activeSort == BookmarkSortOption.newest,
                  onTap: () {
                    ref.read(bookmarkSortProvider.notifier).state = BookmarkSortOption.newest;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Oldest First',
                  selected: activeSort == BookmarkSortOption.oldest,
                  onTap: () {
                    ref.read(bookmarkSortProvider.notifier).state = BookmarkSortOption.oldest;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Alphabetical Order',
                  selected: activeSort == BookmarkSortOption.alphabetical,
                  onTap: () {
                    ref.read(bookmarkSortProvider.notifier).state = BookmarkSortOption.alphabetical;
                    Navigator.pop(ctx);
                  },
                ),
                _SortOptionItem(
                  label: 'Priority Weight',
                  selected: activeSort == BookmarkSortOption.priority,
                  onTap: () {
                    ref.read(bookmarkSortProvider.notifier).state = BookmarkSortOption.priority;
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
    final bookmarksList = ref.watch(filteredBookmarksProvider);
    final rawAsync = ref.watch(rawBookmarksProvider);
    final filter = ref.watch(bookmarkFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6E8), // Warm beige background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sticky Notes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.text,
          ),
        ),
        centerTitle: false,
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.text),
            onPressed: () {
              ref.read(bookmarkControllerProvider.notifier).syncOfflineQueue();
              ref.invalidate(rawBookmarksProvider);
            },
          ),
          // Sorting Trigger
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.text),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Subject dropdown row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
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
                              hintText: 'Search title or desc...',
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
                              ref.read(bookmarkFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: val.trim());
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(bookmarkFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: '');
                            },
                            child: const Icon(Icons.clear_rounded, color: AppColors.text, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Subject filter box
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 2.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: filter.subjectId,
                      hint: Text(
                        'Subject',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: AppColors.text,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Subjects',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.text),
                          ),
                        ),
                        ..._subjectsList.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text(
                                s.subjectName,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.text),
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        ref.read(bookmarkFilterProvider.notifier).state =
                            filter.copyWith(subjectId: val, clearSubject: val == null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal Filter Row ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _StatusChip(
                  label: 'All',
                  isSelected: filter.statusFilter == 'All',
                  onTap: () => ref.read(bookmarkFilterProvider.notifier).state =
                      filter.copyWith(statusFilter: 'All'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Pending',
                  isSelected: filter.statusFilter == 'Pending',
                  onTap: () => ref.read(bookmarkFilterProvider.notifier).state =
                      filter.copyWith(statusFilter: 'Pending'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Completed',
                  isSelected: filter.statusFilter == 'Completed',
                  onTap: () => ref.read(bookmarkFilterProvider.notifier).state =
                      filter.copyWith(statusFilter: 'Completed'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Archived',
                  isSelected: filter.statusFilter == 'Archived',
                  onTap: () => ref.read(bookmarkFilterProvider.notifier).state =
                      filter.copyWith(statusFilter: 'Archived'),
                ),
                const SizedBox(width: 8),
                _ToggleChip(
                  label: '📌 Pinned Only',
                  active: filter.pinnedOnly,
                  onTap: () => ref.read(bookmarkFilterProvider.notifier).state =
                      filter.copyWith(pinnedOnly: !filter.pinnedOnly),
                ),
                const SizedBox(width: 8),
                _ToggleChip(
                  label: '🔥 High Priority',
                  active: filter.highPriorityOnly,
                  onTap: () => ref.read(bookmarkFilterProvider.notifier).state =
                      filter.copyWith(highPriorityOnly: !filter.highPriorityOnly),
                ),
              ],
            ),
          ),

          // ── Sticky Notes List Grid ──
          Expanded(
            child: rawAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Error loading notes: $err'),
              ),
              data: (_) {
                if (bookmarksList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 64, color: AppColors.text),
                          SizedBox(height: 12),
                          Text(
                            'No notes found!',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Create a sticky note to pin important details, formulas, or logs.',
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
                  itemCount: bookmarksList.length,
                  itemBuilder: (context, idx) {
                    final item = bookmarksList[idx];
                    final subject = _subjectsList.firstWhere(
                      (s) => s.id == item.subjectId,
                      orElse: () => SubjectModel(
                        id: '',
                        userId: '',
                        subjectName: 'General',
                        color: '#7C3AED',
                        icon: 'book',
                      ),
                    );

                    return BookmarkCard(
                      bookmark: item,
                      subject: item.subjectId != null ? subject : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
            builder: (_) => const BookmarkFormDialog(),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
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

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF8EAF) : Colors.white,
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

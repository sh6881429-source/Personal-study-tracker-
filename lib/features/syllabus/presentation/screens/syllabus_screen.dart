import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/presentation/providers/syllabus_provider.dart';
import 'package:prep_tracker/features/syllabus/presentation/screens/chapter_screen.dart';
import 'package:prep_tracker/features/syllabus/presentation/widgets/subject_folder_card.dart';

/// Main syllabus screen — redesigned for highly colorful Neo Brutalism.
class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  final _searchCtrl = TextEditingController();
  final _quickAddCtrl = TextEditingController();
  bool _isQuickAdding = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _quickAddCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final filteredSubjects = ref.watch(filteredSubjectsProvider);
    final filter = ref.watch(subjectFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6E8), // True Neo Brutalist Warm Sand/Cream page bg
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Box (Bold Orange/Yellow Card) ──
            _buildHeaderCard(subjectsAsync),

            // ── Search + Filter ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (q) =>
                          ref.read(subjectSearchQueryProvider.notifier).state = q,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    current: filter,
                    onChanged: (f) =>
                        ref.read(subjectFilterProvider.notifier).state = f,
                  ),
                ],
              ),
            ),

            // ── Quick-Add Subject Bar ──
            _QuickAddSubjectBar(
              controller: _quickAddCtrl,
              isAdding: _isQuickAdding,
              onAdd: () async {
                final name = _quickAddCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() => _isQuickAdding = true);
                try {
                  final auth = ref.read(authProvider);
                  final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
                  final existing = ref.read(subjectsProvider).value ?? [];
                  final newSubject = SubjectModel(
                    id: const Uuid().v4(),
                    userId: userId,
                    subjectName: name,
                    color: '5B5FEF',
                    icon: 'book',
                    displayOrder: existing.length,
                  );
                  await ref.read(subjectsProvider.notifier).createSubject(newSubject);
                  _quickAddCtrl.clear();
                } finally {
                  if (mounted) setState(() => _isQuickAdding = false);
                }
              },
            ),

            // ── List of subjects ──
            Expanded(
              child: subjectsAsync.when(
                loading: () => _buildShimmer(),
                error: (e, _) => _buildError(),
                data: (_) {
                  if (filteredSubjects.isEmpty) {
                    return _buildEmpty(
                      hasFilters: _searchCtrl.text.isNotEmpty ||
                          filter != SubjectFilter.all,
                    );
                  }
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filteredSubjects.length,
                    proxyDecorator: (child, index, animation) => child,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      final reordered =
                          List<SubjectModel>.from(filteredSubjects);
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      ref
                          .read(subjectsProvider.notifier)
                          .reorderSubjects(reordered);
                    },
                    itemBuilder: (context, index) {
                      final subject = filteredSubjects[index];
                      final chaptersAsync =
                          ref.watch(chaptersProvider(subject.id));
                      final chapters = chaptersAsync.value ?? [];
                      final total = chapters.length;
                      final completed =
                          chapters.where((c) => c.isCompleted).length;
                      final totalRevTarget = chapters.fold<int>(
                          0, (s, c) => s + c.targetRevisions);
                      final totalRevCurrent = chapters.fold<int>(
                          0, (s, c) => s + c.currentRevisions);
                      final revPercent = totalRevTarget > 0
                          ? totalRevCurrent / totalRevTarget
                          : 0.0;

                      return KeyedSubtree(
                        key: ValueKey(subject.id),
                        child: SubjectFolderCard(
                          subject: subject,
                          totalChapters: total,
                          completedChapters: completed,
                          revisionPercent: revPercent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChapterScreen(subject: subject),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const SubjectFormDialog(),
          ),
          backgroundColor: const Color(0xFFFFD93D), // Bright Yellow
          foregroundColor: AppColors.text,
          elevation: 0,
          icon: const Icon(Icons.add_box_rounded, size: 22, color: AppColors.text),
          label: Text(
            'New Subject',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            side: const BorderSide(color: AppColors.border, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AsyncValue<List<SubjectModel>> subjectsAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFB923C), // Bright Streak Orange
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syllabus',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Organize your study goals',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              subjectsAsync.when(
                data: (subjects) {
                  final active =
                      subjects.where((s) => !s.isArchived).length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$active',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            height: 1,
                          ),
                        ),
                        Text(
                          'Subjects',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.text),
          const SizedBox(height: 16),
          Text('Could not load subjects',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(subjectsProvider.notifier).reload(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD93D),
              foregroundColor: AppColors.text,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border, width: 2.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({required bool hasFilters}) {
    if (hasFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.text),
            const SizedBox(height: 16),
            Text('No subjects found',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.text)),
            const SizedBox(height: 6),
            Text('Try a different search or filter.',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED), // Purple studies signature
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.folder_open_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'No Subjects Yet',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first subject to start organizing your syllabus and tracking your revision progress.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SubjectFormDialog(),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text('Create First Subject',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border, width: 3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ──

class _SearchBar extends StatelessWidget {
  const _SearchBar(
      {required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Search subjects...',
          hintStyle:
              GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.text, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ──

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.current, required this.onChanged});
  final SubjectFilter current;
  final ValueChanged<SubjectFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = current != SubjectFilter.all;
    return PopupMenuButton<SubjectFilter>(
      initialValue: current,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 3)),
      elevation: 4,
      itemBuilder: (_) => [
        _item(SubjectFilter.all, 'All Subjects', Icons.apps_rounded),
        _item(SubjectFilter.archived, 'Archived', Icons.archive_rounded),
        _item(SubjectFilter.alphabetical, 'A → Z',
            Icons.sort_by_alpha_rounded),
        _item(SubjectFilter.recentlyUpdated, 'Recently Updated',
            Icons.update_rounded),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF5D73) : Colors.white, // Pink when active
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.tune_rounded,
          color: isActive ? Colors.white : AppColors.text,
          size: 20,
        ),
      ),
    );
  }

  PopupMenuItem<SubjectFilter> _item(
      SubjectFilter v, String label, IconData icon) {
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Quick Add Subject Bar ──

class _QuickAddSubjectBar extends StatefulWidget {
  const _QuickAddSubjectBar({
    required this.controller,
    required this.onAdd,
    required this.isAdding,
  });
  final TextEditingController controller;
  final VoidCallback onAdd;
  final bool isAdding;

  @override
  State<_QuickAddSubjectBar> createState() => _QuickAddSubjectBarState();
}

class _QuickAddSubjectBarState extends State<_QuickAddSubjectBar> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: _hasFocus ? const Color(0xFFF0EEFF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasFocus ? AppColors.primary : AppColors.border,
          width: _hasFocus ? 2.5 : 2,
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, offset: Offset(3, 3)),
        ],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _hasFocus = f),
        child: TextField(
          controller: widget.controller,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onAdd(),
          decoration: InputDecoration(
            hintText: '+ Type subject name to quick-add...',
            hintStyle: GoogleFonts.inter(
              color: AppColors.text.withOpacity(0.4),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(
              Icons.add_box_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            suffixIcon: widget.isAdding
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: widget.onAdd,
                      )
                    : null,
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 4,
            ),
          ),
        ),
      ),
    );
  }
}

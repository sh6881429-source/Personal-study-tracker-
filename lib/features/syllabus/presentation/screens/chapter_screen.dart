import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/syllabus/presentation/providers/syllabus_provider.dart';
import 'package:prep_tracker/features/syllabus/presentation/widgets/chapter_card.dart';

Color _hexColor(String hex) {
  try {
    final clean = hex.replaceFirst('#', '');
    return Color(0xFF000000 | int.parse(clean, radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}

Color _cardBackground(String hex) {
  final clean = hex.replaceFirst('#', '').toUpperCase();
  const map = {
    '5B5FEF': Color(0xFFC7D2FE), // Lavender-Blue
    'E11D48': Color(0xFFFECDD3), // Soft Rose Pink
    '16A34A': Color(0xFFBBF7D0), // Soft Mint Green
    'EA580C': Color(0xFFFED7AA), // Soft Orange
    '0284C7': Color(0xFFBAE6FD), // Sky Blue
    '7C3AED': Color(0xFFE9D5FF), // Soft Purple
    'D97706': Color(0xFFFEF08A), // Pastel Yellow
    '0F766E': Color(0xFF99F6E4), // Mint Teal
  };
  return map[clean] ?? Color(0xFFFFFBEB);
}

/// Chapter list screen for a specific subject — redesigning for vibrant Neo Brutalism.
class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({super.key, required this.subject});
  final SubjectModel subject;

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = widget.subject.id;
    final themeColor = _hexColor(widget.subject.color);
    final cardBg = _cardBackground(widget.subject.color);
    final chaptersAsync = ref.watch(chaptersProvider(subjectId));
    final filteredChapters = ref.watch(filteredChaptersProvider(subjectId));
    final filter = ref.watch(chapterFilterProvider(subjectId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6E8), // Neo Brutalist Cream page bg
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero Header Card ──
            _buildHeroHeader(chaptersAsync.value ?? [], themeColor, cardBg),

            // ── Search & Filter Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (q) => ref
                          .read(chapterSearchQueryProvider(subjectId).notifier)
                          .state = q,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ChapterFilterChip(
                    subjectId: subjectId,
                    current: filter,
                    onChanged: (f) =>
                        ref.read(chapterFilterProvider(subjectId).notifier).state = f,
                  ),
                ],
              ),
            ),

            // ── Chapter List ──
            Expanded(
              child: chaptersAsync.when(
                loading: () => _buildShimmer(),
                error: (e, _) => _buildError(subjectId),
                data: (_) {
                  if (filteredChapters.isEmpty) {
                    return _buildEmpty(subjectId, themeColor);
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filteredChapters.length,
                    proxyDecorator: (child, index, animation) => child,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      final reordered = List<ChapterModel>.from(filteredChapters);
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      ref
                          .read(chaptersProvider(subjectId).notifier)
                          .reorderChapters(subjectId, reordered);
                    },
                    itemBuilder: (context, index) {
                      final chapter = filteredChapters[index];
                      return KeyedSubtree(
                        key: ValueKey(chapter.id),
                        child: ChapterCard(
                          chapter: chapter,
                          subject: widget.subject,
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
            builder: (_) => ChapterFormDialog(subject: widget.subject),
          ),
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_box_rounded, size: 22, color: Colors.white),
          label: Text(
            'Add Chapter',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            side: const BorderSide(color: AppColors.border, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(List<ChapterModel> chapters, Color themeColor, Color cardBg) {
    final total = chapters.length;
    final completed = chapters.where((c) => c.isCompleted).length;
    final totalRevTarget = chapters.fold<int>(0, (s, c) => s + c.targetRevisions);
    final totalRevCurrent = chapters.fold<int>(0, (s, c) => s + c.currentRevisions);
    final completionPercent = total > 0 ? completed / total : 0.0;
    final revisionPercent = totalRevTarget > 0 ? totalRevCurrent / totalRevTarget : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.subject.subjectName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metric Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroMetricPill(
                label: '$completed/$total Chapters',
                color: Colors.white,
              ),
              _HeroMetricPill(
                label: '${(completionPercent * 100).toStringAsFixed(0)}% Done',
                color: const Color(0xFF86EFAC), // Bright Green
              ),
              _HeroMetricPill(
                label: '${(revisionPercent * 100).toStringAsFixed(0)}% Rev',
                color: const Color(0xFFFFD93D), // Yellow
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar track
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionPercent.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
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
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String subjectId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.text),
          const SizedBox(height: 16),
          Text(
            'Could not load chapters',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => ref
                .read(chaptersProvider(subjectId).notifier)
                .reload(subjectId),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD93D),
              foregroundColor: AppColors.text,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String subjectId, Color themeColor) {
    final query = ref.watch(chapterSearchQueryProvider(subjectId));
    final filter = ref.watch(chapterFilterProvider(subjectId));

    if (query.isNotEmpty || filter != ChapterFilter.all) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.text),
            const SizedBox(height: 16),
            Text(
              'No chapters found',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your filters or query.',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
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
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_book_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'No Chapters Yet',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Add chapters to start tracking your completion and revisions for this subject.',
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
                  builder: (_) => ChapterFormDialog(subject: widget.subject),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Add First Chapter',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
        ),
      ),
    );
  }
}

// ── Search bar ──

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
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
          hintText: 'Search chapters...',
          hintStyle:
              GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.text, size: 20),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
      ),
    );
  }
}

// ── Chapter Filter Chip ──

class _ChapterFilterChip extends StatelessWidget {
  const _ChapterFilterChip({
    required this.subjectId,
    required this.current,
    required this.onChanged,
  });
  final String subjectId;
  final ChapterFilter current;
  final ValueChanged<ChapterFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = current != ChapterFilter.all;
    return PopupMenuButton<ChapterFilter>(
      initialValue: current,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 3)),
      elevation: 4,
      itemBuilder: (_) => [
        _item(ChapterFilter.all, 'All Chapters', Icons.apps_rounded),
        _item(ChapterFilter.completed, 'Completed', Icons.check_circle_rounded),
        _item(ChapterFilter.pending, 'Pending', Icons.radio_button_unchecked_rounded),
        _item(ChapterFilter.mostRevised, 'Most Revised', Icons.trending_up_rounded),
        _item(ChapterFilter.leastRevised, 'Least Revised', Icons.trending_down_rounded),
        _item(ChapterFilter.alphabetical, 'Alphabetical', Icons.sort_by_alpha_rounded),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF5C8A) : Colors.white, // pink active
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

  PopupMenuItem<ChapterFilter> _item(ChapterFilter v, String label, IconData icon) {
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

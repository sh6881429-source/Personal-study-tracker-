import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/presentation/providers/syllabus_provider.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

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

Color _hexColor(String hex) {
  try {
    final clean = hex.replaceFirst('#', '');
    return Color(0xFF000000 | int.parse(clean, radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}

/// Chapter checklist card with bold Neo Brutalist completion and revision states.
class ChapterCard extends ConsumerStatefulWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.subject,
  });

  final ChapterModel chapter;
  final SubjectModel subject;

  @override
  ConsumerState<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends ConsumerState<ChapterCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final subjectColor = _hexColor(widget.subject.color);
    final cardBg = chapter.isCompleted
        ? const Color(0xFF86EFAC) // Bold Neo Brutalist Green on completion
        : _cardBackground(widget.subject.color);

    final revisionProgress =
        chapter.targetRevisions > 0 ? chapter.currentRevisions / chapter.targetRevisions : 0.0;

    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: AppColors.border,
          width: AppConstants.borderWidth,
        ),
        boxShadow: chapter.isCompleted
            ? [] // Press effect - shadow goes away when completed
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(4, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // ── Main Row ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Custom Checkbox
                GestureDetector(
                  onTap: () => ref
                      .read(chaptersProvider(chapter.subjectId).notifier)
                      .toggleComplete(chapter),
                  child: AnimatedContainer(
                    duration: AppConstants.animationDuration,
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: chapter.isCompleted ? AppColors.border : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border,
                        width: 2.5,
                      ),
                    ),
                    child: chapter.isCompleted
                        ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.chapterName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          decoration: chapter.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chapter.isCompleted && chapter.completedAt != null)
                        Text(
                          'Done on ${_formatDate(chapter.completedAt!)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                // Expanded arrow
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppConstants.animationDuration,
                    child: const Icon(Icons.expand_more_rounded, size: 24, color: AppColors.text),
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),

          // ── Revision Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Decrement Button
                _RevisionButton(
                  icon: Icons.remove_rounded,
                  onTap: () => ref
                      .read(chaptersProvider(chapter.subjectId).notifier)
                      .decrementRevision(chapter),
                  enabled: chapter.currentRevisions > 0,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            value: revisionProgress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                chapter.isCompleted ? const Color(0xFF16A34A) : subjectColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Center(
                        child: Text(
                          'Revision Count: ${chapter.currentRevisions}/${chapter.targetRevisions}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Increment Button
                _RevisionButton(
                  icon: Icons.add_rounded,
                  onTap: () => ref
                      .read(chaptersProvider(chapter.subjectId).notifier)
                      .incrementRevision(chapter),
                  enabled: chapter.currentRevisions < chapter.targetRevisions,
                  color: const Color(0xFFFFD93D), // Yellow accent
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Expanded section: Notes + Options ──
          if (_isExpanded) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes & Revision Details',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (chapter.description != null && chapter.description!.isNotEmpty)
                        ? chapter.description!
                        : 'No notes provided. Expand notes to add references here.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Edit Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD93D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: TextButton.icon(
                            onPressed: () => _showEditDialog(context),
                            icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.text),
                            label: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Delete Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5C8A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: TextButton.icon(
                            onPressed: () => _showDeleteConfirmation(context),
                            icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.white),
                            label: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ChapterFormDialog(
        subject: widget.subject,
        chapter: widget.chapter,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 3),
        ),
        title: Text('Delete Chapter?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: Text(
          'Delete "${widget.chapter.chapterName}"? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(chaptersProvider(widget.chapter.subjectId).notifier)
                  .deleteChapter(widget.chapter);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RevisionButton extends StatelessWidget {
  const _RevisionButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.color,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? (color ?? const Color(0xFF38BDF8))
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(2, 2),
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.text,
        ),
      ),
    );
  }
}

// ── Chapter Form Dialog ──

class ChapterFormDialog extends ConsumerStatefulWidget {
  const ChapterFormDialog({
    super.key,
    required this.subject,
    this.chapter,
  });
  final SubjectModel subject;
  final ChapterModel? chapter;

  @override
  ConsumerState<ChapterFormDialog> createState() => _ChapterFormDialogState();
}

class _ChapterFormDialogState extends ConsumerState<ChapterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _targetRevCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.chapter?.chapterName ?? '');
    _descCtrl = TextEditingController(text: widget.chapter?.description ?? '');
    _targetRevCtrl = TextEditingController(
      text: (widget.chapter?.targetRevisions ?? 3).toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetRevCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.chapter != null;
    final subjectColor = _hexColor(widget.subject.color);

    return Dialog(
      backgroundColor: const Color(0xFFFFFDF0), // Warm Cream background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 3),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: subjectColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadow, offset: Offset(2, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Edit Chapter' : 'New Chapter',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Chapter Name',
                  labelStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w800),
                  hintText: 'e.g. Chapter 1: Basics',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: subjectColor, width: 3),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Chapter name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _descCtrl,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Notes & References',
                  labelStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w800),
                  hintText: 'Add equations, key topics...',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: subjectColor, width: 3),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Target revisions
              TextFormField(
                controller: _targetRevCtrl,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Target Revisions',
                  labelStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w800),
                  hintText: 'e.g. 3',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: subjectColor, width: 3),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Minimum 1';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadow, offset: Offset(2, 2)),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadow, offset: Offset(3, 3)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                isEdit ? 'Update' : 'Add Chapter',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final auth = ref.read(authProvider);
      final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
      final targetRevisions = int.parse(_targetRevCtrl.text.trim());

      final existingChapters =
          ref.read(chaptersProvider(widget.subject.id)).value ?? [];
      final displayOrder = existingChapters.length;

      final model = ChapterModel(
        id: widget.chapter?.id ?? const Uuid().v4(),
        userId: userId,
        subjectId: widget.subject.id,
        chapterName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        targetRevisions: targetRevisions,
        currentRevisions: widget.chapter?.currentRevisions ?? 0,
        isCompleted: widget.chapter?.isCompleted ?? false,
        completedAt: widget.chapter?.completedAt,
        displayOrder: widget.chapter?.displayOrder ?? displayOrder,
      );

      final notifier = ref.read(chaptersProvider(widget.subject.id).notifier);
      if (widget.chapter != null) {
        await notifier.updateChapter(model);
      } else {
        await notifier.addChapter(model);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

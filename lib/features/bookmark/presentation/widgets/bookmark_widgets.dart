import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/bookmark/presentation/providers/bookmark_provider.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';

/// ── Bookmark Card (Sticky Note Card) ──
class BookmarkCard extends ConsumerWidget {
  const BookmarkCard({
    super.key,
    required this.bookmark,
    this.subject,
  });

  final BookmarkModel bookmark;
  final SubjectModel? subject;

  Color _getPriorityColor(String priority) {
    if (bookmark.isArchived) {
      return const Color(0xFFE5E7EB); // Muted gray for archived
    }
    switch (priority) {
      case 'High':
        return const Color(0xFFFF8EAF); // Soft Vibrant Pink
      case 'Medium':
        return const Color(0xFFFFD93D); // Bright Yellow
      case 'Low':
      default:
        return const Color(0xFFBAE6FD); // Sky Blue
    }
  }

  void _showActionsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border, width: 3),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                bookmark.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: Icons.edit_rounded,
                label: 'Edit Sticky Note',
                color: const Color(0xFFFFD93D),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => BookmarkFormDialog(bookmark: bookmark),
                  );
                },
              ),
              _SheetOption(
                icon: Icons.copy_all_rounded,
                label: 'Duplicate Sticky Note',
                color: const Color(0xFFBAE6FD),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(bookmarkControllerProvider.notifier).duplicateBookmark(bookmark);
                },
              ),
              _SheetOption(
                icon: bookmark.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                label: bookmark.isArchived ? 'Unarchive Note' : 'Archive Note',
                color: const Color(0xFFC7D2FE),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(bookmarkControllerProvider.notifier).toggleArchive(bookmark);
                },
              ),
              _SheetOption(
                icon: bookmark.isPinned ? Icons.pin_drop_rounded : Icons.pin_invoke_rounded,
                label: bookmark.isPinned ? 'Unpin Note' : 'Pin Note',
                color: const Color(0xFFFED7AA),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(bookmarkControllerProvider.notifier).togglePin(bookmark);
                },
              ),
              _SheetOption(
                icon: Icons.delete_rounded,
                label: 'Delete Note Permanently',
                color: const Color(0xFFFF8EAF),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 3),
        ),
        title: Text(
          'Delete Sticky Note?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppColors.text),
        ),
        content: Text(
          'This sticky note will be deleted permanently. Are you sure?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8EAF),
              foregroundColor: AppColors.text,
              elevation: 0,
              side: const BorderSide(color: AppColors.border, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(bookmarkControllerProvider.notifier).deleteBookmark(bookmark.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteColor = _getPriorityColor(bookmark.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: noteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _showActionsMenu(context, ref),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 120,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Subject written on top & Pin status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 1.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: () {
                                    if (subject == null) return const Color(0xFF5B5FEF);
                                    try {
                                      final hex = subject!.color.replaceFirst('#', '');
                                      return Color(int.parse('0xFF$hex'));
                                    } catch (_) {
                                      return const Color(0xFF5B5FEF);
                                    }
                                  }(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                subject != null ? subject!.subjectName : 'General',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (bookmark.isPinned)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFFFF5C8A)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Checkbox & Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => ref.read(bookmarkControllerProvider.notifier).toggleComplete(bookmark),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: bookmark.isCompleted ? AppColors.border : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border, width: 2.2),
                            ),
                            child: bookmark.isCompleted
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bookmark.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              decoration: bookmark.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Row 3: Description text
                    if (bookmark.description != null && bookmark.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          bookmark.description!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text.withValues(alpha: 0.8),
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Footer Row: Created Date, Priority and Notification indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bookmark.createdAt != null
                          ? 'Created: ${DateFormat('dd MMM, hh:mm a').format(bookmark.createdAt!)}'
                          : '',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Text(
                            bookmark.priority,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (bookmark.reminderDate != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: const Icon(Icons.notifications_active_rounded,
                                size: 11, color: AppColors.text),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(2.5, 2.5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1.8),
          ),
          child: Icon(icon, color: AppColors.text, size: 18),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.text,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─── BOOKMARK FORM DIALOG ───────────────────────────────────────────────────

class BookmarkFormDialog extends ConsumerStatefulWidget {
  const BookmarkFormDialog({super.key, this.bookmark});
  final BookmarkModel? bookmark;

  @override
  ConsumerState<BookmarkFormDialog> createState() => _BookmarkFormDialogState();
}

class _BookmarkFormDialogState extends ConsumerState<BookmarkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String? _selectedSubjectId;
  String _priority = 'Medium';
  DateTime? _reminderDate;
  List<SubjectModel> _subjectsList = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookmark?.title ?? '');
    _descController = TextEditingController(text: widget.bookmark?.description ?? '');
    _selectedSubjectId = widget.bookmark?.subjectId;
    _priority = widget.bookmark?.priority ?? 'Medium';
    _reminderDate = widget.bookmark?.reminderDate;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final auth = ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isNotEmpty) {
      final list = await ref.read(subjectRepositoryProvider).getActiveSubjects(userId);
      setState(() {
        _subjectsList = list;
        if (_selectedSubjectId == null && list.isNotEmpty) {
          _selectedSubjectId = list.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';

    final model = BookmarkModel(
      id: widget.bookmark?.id ?? const Uuid().v4(),
      userId: userId,
      subjectId: _selectedSubjectId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      priority: _priority,
      isCompleted: widget.bookmark?.isCompleted ?? false,
      isPinned: widget.bookmark?.isPinned ?? false,
      reminderDate: _reminderDate,
      createdAt: widget.bookmark?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final controller = ref.read(bookmarkControllerProvider.notifier);
    if (widget.bookmark != null) {
      controller.updateBookmark(model);
    } else {
      controller.addBookmark(model);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 3),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bookmark != null ? 'Edit Sticky Note' : 'Add Sticky Note',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),

              // Title Field
              Text(
                'Title',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(color: AppColors.text, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter title...',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border, width: 3),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),

              // Description Field
              Text(
                'Description (Optional)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: GoogleFonts.inter(color: AppColors.text, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Add description / details...',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border, width: 3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Subject Picker
              Text(
                'Subject Folder',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 2.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubjectId,
                    isExpanded: true,
                    hint: Text(
                      'Select subject...',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    items: _subjectsList.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub.id,
                        child: Text(
                          sub.subjectName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Priority Selector
              Text(
                'Priority Weight',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _priorityChip('Low', const Color(0xFFBAE6FD)),
                  const SizedBox(width: 8),
                  _priorityChip('Medium', const Color(0xFFFFD93D)),
                  const SizedBox(width: 8),
                  _priorityChip('High', const Color(0xFFFF8EAF)),
                ],
              ),
              const SizedBox(height: 14),

              // Reminder Date Selector
              Text(
                'Reminder Date & Time',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selectReminderDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 2.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.text, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _reminderDate != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(_reminderDate!)
                            : 'Set Reminder...',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _reminderDate != null ? AppColors.text : AppColors.text.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      if (_reminderDate != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _reminderDate = null;
                            });
                          },
                          child: const Icon(Icons.clear_rounded, color: AppColors.text, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD93D),
                      foregroundColor: AppColors.text,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.border, width: 2.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _save,
                    child: Text(
                      widget.bookmark != null ? 'Save Changes' : 'Create Note',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
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

  Widget _priorityChip(String label, Color chipColor) {
    final isSelected = _priority == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _priority = label;
          });
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border,
              width: isSelected ? 2.5 : 1.8,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(1.5, 1.5),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

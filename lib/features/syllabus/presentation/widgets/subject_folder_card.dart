import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/presentation/providers/syllabus_provider.dart';
import 'package:uuid/uuid.dart';

// ─── Color palette for subjects ───────────────────────────────────────────────
const _subjectColors = [
  '5B5FEF', // Lavender-Blue
  'E11D48', // Rose Pink
  '16A34A', // Mint Green
  'EA580C', // Orange
  '0284C7', // Sky Blue
  '7C3AED', // Violet Purple
  'D97706', // Amber Yellow
  '0F766E', // Teal
];

const _subjectIconData = {
  'book':      {'icon': Icons.menu_book_rounded, 'label': 'Books'},
  'math':      {'icon': Icons.calculate_rounded, 'label': 'Math'},
  'science':   {'icon': Icons.science_rounded, 'label': 'Science'},
  'physics':   {'icon': Icons.bolt_rounded, 'label': 'Physics'},
  'biology':   {'icon': Icons.biotech_rounded, 'label': 'Biology'},
  'history':   {'icon': Icons.account_balance_rounded, 'label': 'History'},
  'geography': {'icon': Icons.public_rounded, 'label': 'Geo'},
  'english':   {'icon': Icons.translate_rounded, 'label': 'English'},
  'computer':  {'icon': Icons.computer_rounded, 'label': 'Comp'},
  'art':       {'icon': Icons.palette_rounded, 'label': 'Art'},
  'music':     {'icon': Icons.music_note_rounded, 'label': 'Music'},
  'chemistry': {'icon': Icons.water_drop_rounded, 'label': 'Chem'},
};

// Translates selected hex values into vibrant, high-contrast, flat Neo Brutalist background colors.
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

// ─── Subject Folder Card ──────────────────────────────────────────────────────

class SubjectFolderCard extends ConsumerWidget {
  const SubjectFolderCard({
    super.key,
    required this.subject,
    required this.onTap,
    required this.totalChapters,
    required this.completedChapters,
    required this.revisionPercent,
  });

  final SubjectModel subject;
  final VoidCallback onTap;
  final int totalChapters;
  final int completedChapters;
  final double revisionPercent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBg = _cardBackground(subject.color);
    final themeColor = _hexColor(subject.color);
    final completionPercent =
        totalChapters > 0 ? completedChapters / totalChapters : 0.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptionsMenu(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: AppColors.border,
            width: AppConstants.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon badge on white with black border
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 2.5),
                        ),
                        child: Icon(
                          _subjectIconFlutter(subject.icon),
                          color: themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.subjectName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subject.description != null &&
                                subject.description!.isNotEmpty)
                              Text(
                                subject.description!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Chapter badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Text(
                          '$completedChapters/$totalChapters',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Discoverable options/delete button
                      GestureDetector(
                        onTap: () => _showOptionsMenu(context, ref),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                offset: Offset(1.5, 1.5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress & revision info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completion',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${(completionPercent * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Neo Brutalist Progress Bar
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.border, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: completionPercent.clamp(0.0, 1.0),
                                  minHeight: 12,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Revision Pill - Vibrant Coral/Amber
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD93D), // Yellow accent
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.replay_rounded,
                                size: 14, color: AppColors.text),
                            const SizedBox(width: 4),
                            Text(
                              '${(revisionPercent * 100).toStringAsFixed(0)}% Rev',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _subjectIconFlutter(String icon) {
    return _subjectIconData[icon.toLowerCase()]?['icon'] as IconData? ??
        Icons.book_rounded;
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
              subject.subjectName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.edit_rounded,
              label: 'Edit Subject',
              color: const Color(0xFFFFD93D), // Yellow accent
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => SubjectFormDialog(subject: subject),
                );
              },
            ),
            _SheetOption(
              icon: subject.isArchived
                  ? Icons.unarchive_rounded
                  : Icons.archive_rounded,
              label: subject.isArchived ? 'Unarchive' : 'Archive Subject',
              color: const Color(0xFF38BDF8), // Sky blue
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(subjectsProvider.notifier)
                    .archiveSubject(subject);
              },
            ),
            _SheetOption(
              icon: Icons.delete_rounded,
              label: 'Delete Subject',
              color: const Color(0xFFFF5C8A), // Pink/danger
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 3),
        ),
        title: Text('Delete Subject?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: Text(
          'Delete "${subject.subjectName}" and all its chapters permanently?',
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
              ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
            },
            child: const Text('Delete'),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 2),
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

// ─── Subject Form Dialog ──────────────────────────────────────────────────────

class SubjectFormDialog extends ConsumerStatefulWidget {
  const SubjectFormDialog({super.key, this.subject});
  final SubjectModel? subject;

  @override
  ConsumerState<SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends ConsumerState<SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedColor;
  late String _selectedIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.subject?.subjectName ?? '');
    _descCtrl =
        TextEditingController(text: widget.subject?.description ?? '');
    _selectedColor = widget.subject?.color ?? _subjectColors.first;
    _selectedIcon = widget.subject?.icon ?? _subjectIconData.keys.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subject != null;
    final selectedColorVal = _hexColor(_selectedColor);

    return Dialog(
      backgroundColor: const Color(0xFFFFFDF0), // Warm Cream Neo background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 3),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header banner style
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: selectedColorVal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isEdit ? 'Edit Subject' : 'New Subject',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  labelStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w800),
                  hintText: 'e.g. Mathematics',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(Icons.book_outlined, color: AppColors.border),
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
                    borderSide:
                        BorderSide(color: selectedColorVal, width: 3),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 2.5),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Subject name is required';
                  if (v.trim().length > 50) return 'Max 50 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description field
              TextFormField(
                controller: _descCtrl,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: GoogleFonts.poppins(color: AppColors.text, fontWeight: FontWeight.w800),
                  hintText: 'e.g. NCERT Class 12',
                  hintStyle: GoogleFonts.inter(color: AppColors.text.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.border),
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
                    borderSide:
                        BorderSide(color: selectedColorVal, width: 3),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Color picker
              Text('Pick Colour Accent',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _subjectColors.map((hex) {
                  final c = _hexColor(hex);
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : AppColors.border,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                    color: AppColors.shadow,
                                    offset: Offset(2, 2))
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Icon picker
              Text('Pick Icon',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjectIconData.entries.map((entry) {
                  final isSelected = _selectedIcon == entry.key;
                  final iconData = entry.value['icon'] as IconData;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColorVal
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  offset: Offset(2, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconData,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.text,
                              size: 20),
                          const SizedBox(height: 2),
                          Text(
                            (entry.value['label'] as String?) ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Action buttons with Neo Brutalist offset shadow
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            offset: Offset(2, 2),
                          ),
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
                        color: selectedColorVal,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            offset: Offset(3, 3),
                          ),
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
                                isEdit ? 'Update' : 'Create',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15),
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
      final existing = ref.read(subjectsProvider).value ?? [];

      final id = (widget.subject?.id != null && widget.subject!.id.isNotEmpty)
          ? widget.subject!.id
          : const Uuid().v4();

      final model = SubjectModel(
        id: id,
        userId: userId,
        subjectName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        color: _selectedColor,
        icon: _selectedIcon,
        displayOrder: widget.subject?.displayOrder ?? existing.length,
        isArchived: widget.subject?.isArchived ?? false,
      );

      if (widget.subject != null) {
        await ref.read(subjectsProvider.notifier).updateSubject(model);
      } else {
        await ref.read(subjectsProvider.notifier).createSubject(model);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

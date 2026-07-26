import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/pdf/presentation/providers/pdf_provider.dart';
import 'package:prep_tracker/features/pdf/presentation/screens/pdf_viewer_screen.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';

/// ── Subject Folder Card ──
class SubjectFolderCard extends ConsumerWidget {
  const SubjectFolderCard({
    super.key,
    required this.subject,
    required this.pdfCount,
    required this.onTap,
    this.onDeletePressed,
  });

  final SubjectModel subject;
  final int pdfCount;
  final VoidCallback onTap;
  final VoidCallback? onDeletePressed;

  void _deleteFolder(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 3),
        ),
        title: Text(
          'Delete Folder?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppColors.text),
        ),
        content: Text(
          'This will permanently delete the folder "${subject.subjectName}" and all of its PDF files and syllabus content. This action cannot be undone.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(subjectRepositoryProvider).deleteSubject(subject.id);
              // Invalidate providers
              ref.invalidate(rawPdfsProvider);
              if (onDeletePressed != null) {
                onDeletePressed!();
              }
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

  void _showFolderActions(BuildContext context, WidgetRef ref) {
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
                subject.subjectName,
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
                icon: Icons.delete_rounded,
                label: 'Delete Subject Folder',
                color: const Color(0xFFFF8EAF),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteFolder(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderColor = () {
      try {
        final hex = subject.color.replaceFirst('#', '');
        return Color(int.parse('0xFF$hex'));
      } catch (_) {
        return const Color(0xFFBAE6FD);
      }
    }();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Folder icon with subject color
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: folderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Icon(Icons.folder_copy_rounded, color: folderColor, size: 24),
                    ),
                    const SizedBox(height: 14),

                    // Subject Name
                    Text(
                      subject.subjectName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Total files count
                    Text(
                      '$pdfCount PDFs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.text, size: 20),
              onPressed: () => _showFolderActions(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PDF FILE TILE ──────────────────────────────────────────────────────────

class PdfFileTile extends ConsumerStatefulWidget {
  const PdfFileTile({
    super.key,
    required this.pdf,
    this.onViewClick,
  });

  final PdfModel pdf;
  final VoidCallback? onViewClick;

  @override
  ConsumerState<PdfFileTile> createState() => _PdfFileTileState();
}

class _PdfFileTileState extends ConsumerState<PdfFileTile> {
  @override
  void initState() {
    super.initState();
    // Refresh download status dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pdfDownloadsProvider.notifier).checkDownloadStatus(widget.pdf);
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
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
                widget.pdf.originalName,
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
                icon: Icons.chrome_reader_mode_rounded,
                label: 'Open Document Viewer',
                color: const Color(0xFFC7D2FE),
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.onViewClick != null) {
                    widget.onViewClick!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerScreen(pdf: widget.pdf),
                      ),
                    );
                  }
                },
              ),
              _SheetOption(
                icon: Icons.share_rounded,
                label: 'Share Document Link',
                color: const Color(0xFFBAE6FD),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Share local path or file if downloaded
                  final dlProgress = ref.read(pdfDownloadsProvider)[widget.pdf.id];
                  if (dlProgress?.status == DownloadStatus.downloaded &&
                      dlProgress?.localPath != null) {
                    await Share.shareXFiles([XFile(dlProgress!.localPath!)]);
                  } else {
                    await Share.share('Checkout my PrepTracker PDF file: ${widget.pdf.originalName}');
                  }
                },
              ),
              _SheetOption(
                icon: Icons.edit_note_rounded,
                label: 'Edit Document Details',
                color: const Color(0xFFFFD93D),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => PdfEditDialog(pdf: widget.pdf),
                  );
                },
              ),
              _SheetOption(
                icon: Icons.delete_rounded,
                label: 'Delete Document Permanently',
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
          'Delete Document?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppColors.text),
        ),
        content: Text(
          'This PDF document will be deleted permanently. Are you sure?',
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
              ref.read(pdfControllerProvider.notifier).deletePdf(widget.pdf);
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
  Widget build(BuildContext context) {
    final downloads = ref.watch(pdfDownloadsProvider);
    final status = downloads[widget.pdf.id] ??
        const DownloadProgress(status: DownloadStatus.notDownloaded, progress: 0.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          // Open viewer
          if (widget.onViewClick != null) {
            widget.onViewClick!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PdfViewerScreen(pdf: widget.pdf)),
            );
          }
        },
        onLongPress: () => _showActionsMenu(context, ref),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (widget.pdf.originalName.toLowerCase().endsWith('.jpg') ||
                    widget.pdf.originalName.toLowerCase().endsWith('.jpeg') ||
                    widget.pdf.originalName.toLowerCase().endsWith('.png') ||
                    widget.pdf.originalName.toLowerCase().endsWith('.webp'))
                ? const Color(0xFFBAE6FD) // Sky Blue for images
                : const Color(0xFFFF8EAF), // Pink box for PDF
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.8),
          ),
          child: Icon(
            (widget.pdf.originalName.toLowerCase().endsWith('.jpg') ||
                    widget.pdf.originalName.toLowerCase().endsWith('.jpeg') ||
                    widget.pdf.originalName.toLowerCase().endsWith('.png') ||
                    widget.pdf.originalName.toLowerCase().endsWith('.webp'))
                ? Icons.image_rounded
                : Icons.picture_as_pdf_rounded,
            color: AppColors.text,
            size: 20,
          ),
        ),
        title: Text(
          widget.pdf.originalName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
            color: AppColors.text,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              _formatSize(widget.pdf.fileSize),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.pdf.pageCount != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.pdf.pageCount} Pages',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite Button
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                widget.pdf.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: widget.pdf.isFavorite ? const Color(0xFFFF5C8A) : AppColors.text,
                size: 20,
              ),
              onPressed: () => ref.read(pdfControllerProvider.notifier).toggleFavorite(widget.pdf),
            ),
            const SizedBox(width: 6),

            // Download Status icon
            _buildDownloadIcon(status),
            const SizedBox(width: 6),

            // Three-Dots Menu Button (Discoverable options/delete)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.text,
                size: 20,
              ),
              onPressed: () => _showActionsMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadIcon(DownloadProgress status) {
    switch (status.status) {
      case DownloadStatus.downloaded:
        return const Icon(Icons.offline_pin_rounded, color: Color(0xFF34D399), size: 20);
      case DownloadStatus.downloading:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: status.progress,
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        );
      case DownloadStatus.failed:
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5C8A), size: 20),
          onPressed: () => ref.read(pdfDownloadsProvider.notifier).downloadFile(widget.pdf),
        );
      case DownloadStatus.notDownloaded:
      default:
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.cloud_download_outlined, color: AppColors.text, size: 20),
          onPressed: () => ref.read(pdfDownloadsProvider.notifier).downloadFile(widget.pdf),
        );
    }
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

// ─── PDF UPLOAD DIALOG ───────────────────────────────────────────────────────

class PdfUploadDialog extends ConsumerStatefulWidget {
  const PdfUploadDialog({super.key});

  @override
  ConsumerState<PdfUploadDialog> createState() => _PdfUploadDialogState();
}

class _PdfUploadDialogState extends ConsumerState<PdfUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  List<int>? _pickedBytes;
  String? _pickedName;
  String? _selectedSubjectId;
  List<SubjectModel> _subjectsList = [];

  bool _createCustomSubject = false;
  final TextEditingController _customSubjectController = TextEditingController();
  String _selectedCustomColor = '5B5FEF';
  bool _isSaving = false;

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
        if (list.isNotEmpty) {
          _selectedSubjectId = list.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pagesController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final fileObj = result.files.single;
      setState(() {
        _pickedBytes = fileObj.bytes;
        _pickedName = fileObj.name;
        _titleController.text = fileObj.name.split('.').first;
      });
    }
  }

  Future<void> _upload() async {
    if (_pickedBytes == null || _pickedName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF or Image file first.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = ref.read(authProvider);
      final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
      if (userId.isEmpty) return;

      String targetSubjectId = _selectedSubjectId ?? '';

      if (_createCustomSubject) {
        final newSubject = SubjectModel(
          id: const Uuid().v4(),
          userId: userId,
          subjectName: _customSubjectController.text.trim(),
          color: _selectedCustomColor,
          icon: 'book',
        );
        await ref.read(subjectRepositoryProvider).createSubject(newSubject);
        targetSubjectId = newSubject.id;
      }

      final pageCount = int.tryParse(_pagesController.text);

      await ref.read(pdfControllerProvider.notifier).uploadPdf(
            subjectId: targetSubjectId,
            fileBytes: _pickedBytes!,
            originalName: _pickedName!,
            pageCount: pageCount,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 3),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxHeight: availableHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload PDF or Image',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),

                // File Selection Box
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_upload_rounded, color: AppColors.text, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          _pickedBytes != null && _pickedName != null
                              ? _pickedName!
                              : 'Choose File (PDF, JPG, PNG, WEBP)...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title Field
                Text(
                  'Document Title',
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
                    hintText: 'Enter book title...',
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

                // Subject selector dropdown
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
                      value: _createCustomSubject ? 'CREATE_NEW_SUBJECT' : _selectedSubjectId,
                      isExpanded: true,
                      hint: Text(
                        'Select subject...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      items: [
                        ..._subjectsList.map((s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                s.subjectName,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text),
                              ),
                            )),
                        DropdownMenuItem<String>(
                          value: 'CREATE_NEW_SUBJECT',
                          child: Row(
                            children: [
                              const Icon(Icons.create_new_folder_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '+ Create New Subject...',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val == 'CREATE_NEW_SUBJECT') {
                            _createCustomSubject = true;
                            _selectedSubjectId = null;
                          } else {
                            _createCustomSubject = false;
                            _selectedSubjectId = val;
                          }
                        });
                      },
                    ),
                  ),
                ),

                // Inline custom subject creator (shown when CREATE_NEW_SUBJECT is selected)
                if (_createCustomSubject) ...[  
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customSubjectController,
                    style: GoogleFonts.inter(
                        color: AppColors.text, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'New subject name...',
                      hintStyle: GoogleFonts.inter(
                          color: AppColors.text.withOpacity(0.4),
                          fontSize: 13),
                      prefixIcon: const Icon(Icons.folder_rounded,
                          color: AppColors.primary, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF0EEFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                    validator: (v) {
                      if (_createCustomSubject &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Subject name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pick Folder Colour',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      '5B5FEF',
                      'E11D48',
                      '16A34A',
                      'EA580C',
                      '0284C7',
                      '7C3AED',
                      'D97706',
                      '0F766E',
                    ].map((hex) {
                      final c = Color(int.parse('0xFF$hex'));
                      final selected = _selectedCustomColor == hex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCustomColor = hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.border
                                  : Colors.transparent,
                              width: selected ? 3 : 0,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),

                // Page count (optional)
                Text(
                  'Number of Pages (Optional)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pagesController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: AppColors.text, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter page count...',
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
                const SizedBox(height: 20),

                // Actions
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
                      onPressed: _upload,
                      child: Text(
                        'Upload Book',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                      ),
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

// ─── PDF EDIT DIALOG ──────────────────────────────────────────────────────────

class PdfEditDialog extends ConsumerStatefulWidget {
  const PdfEditDialog({super.key, required this.pdf});
  final PdfModel pdf;

  @override
  ConsumerState<PdfEditDialog> createState() => _PdfEditDialogState();
}

class _PdfEditDialogState extends ConsumerState<PdfEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  String? _selectedSubjectId;
  List<SubjectModel> _subjectsList = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.pdf.originalName.endsWith('.pdf')
          ? widget.pdf.originalName.substring(0, widget.pdf.originalName.length - 4)
          : widget.pdf.originalName,
    );
    _descController = TextEditingController(text: widget.pdf.description ?? '');
    _selectedSubjectId = widget.pdf.subjectId;
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
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newNameStr = _nameController.text.trim();
    final newName = newNameStr.endsWith('.pdf') ? newNameStr : '$newNameStr.pdf';
    final desc = _descController.text.trim();

    final updated = widget.pdf.copyWith(
      originalName: newName,
      description: desc.isEmpty ? null : desc,
      subjectId: _selectedSubjectId,
      updatedAt: DateTime.now(),
    );

    ref.read(pdfControllerProvider.notifier).updatePdf(updated);
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
                'Edit Document Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),

              // Title Field
              Text(
                'Document Title',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
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
                  hintText: 'Add description or notes...',
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

              // Subject selector dropdown
              Text(
                'Move to Subject Folder',
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
                    items: _subjectsList.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(
                          s.subjectName,
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
              const SizedBox(height: 20),

              // Actions
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
                      'Save Changes',
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
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/chat_message_model.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/services/ai_export_service.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class ExportPreviewDialog extends StatefulWidget {
  const ExportPreviewDialog({
    super.key,
    required this.session,
  });

  final ChatSessionModel session;

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog> {
  String _selectedFormat = 'PDF';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    final markdownText = AiExportService.exportToMarkdown(widget.session);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 550),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 3.5),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.file_download_rounded, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Export Conversation',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Format Selection Chips
            Row(
              children: ['PDF', 'Markdown', 'TXT'].map((fmt) {
                final isSel = _selectedFormat == fmt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFormat = fmt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF5B5FEF) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: isSel ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2))] : null,
                      ),
                      child: Text(
                        fmt,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isSel ? Colors.white : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Content Preview Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDF0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _selectedFormat == 'TXT'
                        ? AiExportService.exportToPlainText(widget.session)
                        : markdownText,
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : AppColors.text, height: 1.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Download Button
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  final title = widget.session.title.replaceAll(' ', '_');
                  if (_selectedFormat == 'PDF') {
                    await AiExportService.exportPdf(widget.session);
                  } else if (_selectedFormat == 'Markdown') {
                    AiExportService.downloadFileWeb(
                      markdownText,
                      '$title.md',
                      'text/markdown',
                    );
                  } else {
                    AiExportService.downloadFileWeb(
                      AiExportService.exportToPlainText(widget.session),
                      '$title.txt',
                      'text/plain',
                    );
                  }
                  if (context.mounted) {
                    AppSnackbar.showSuccess(context, 'Exported conversation as $_selectedFormat successfully!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackbar.showError(context, 'Failed to export conversation: $e');
                  }
                }
              },
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Download $_selectedFormat File',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

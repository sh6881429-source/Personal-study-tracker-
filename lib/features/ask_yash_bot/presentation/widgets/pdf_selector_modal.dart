import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/services/pdf_text_extractor_service.dart';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';
import 'package:prep_tracker/features/pdf/data/repositories/pdf_repository_impl.dart';
import 'package:prep_tracker/features/pdf/presentation/providers/pdf_provider.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class PdfSelectorModal extends ConsumerStatefulWidget {
  const PdfSelectorModal({
    super.key,
    required this.onPdfSelected,
  });

  final void Function(String name, String contentSnippet) onPdfSelected;

  @override
  ConsumerState<PdfSelectorModal> createState() => _PdfSelectorModalState();
}

class _PdfSelectorModalState extends ConsumerState<PdfSelectorModal> {
  String? _loadingPdfId;

  Future<void> _processAndAttachPdf(PdfModel pdf) async {
    setState(() => _loadingPdfId = pdf.id);

    try {
      final repo = ref.read(pdfRepositoryProvider);
      final bytes = await repo.downloadBytes(pdf.storagePath);

      final result = PdfTextExtractorService.extractText(bytes);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (result.isSuccess && result.text.isNotEmpty) {
        widget.onPdfSelected(pdf.originalName, result.text);
      } else {
        final errorText = result.errorMessage ??
            "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR.";
        widget.onPdfSelected(pdf.originalName, '[ERROR: $errorText]');
        AppSnackbar.showWarning(context, "Readable text missing in PDF. Sent warning to Yash Bot.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      final errorMsg =
          "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR.";
      widget.onPdfSelected(pdf.originalName, '[ERROR: $errorMsg]');
      AppSnackbar.showError(context, "Error extracting PDF text: $e");
    } finally {
      if (mounted) setState(() => _loadingPdfId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfs = ref.watch(filteredPdfsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        padding: const EdgeInsets.all(18),
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
                    color: const Color(0xFFFF5D73),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Attach PDF for Yash Bot Assistant',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select a PDF from your library to extract text and analyze contents with Yash Bot:',
              style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: pdfs.isEmpty
                  ? Center(
                      child: Text(
                        'No PDF documents uploaded yet.',
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: pdfs.length,
                      itemBuilder: (context, index) {
                        final PdfModel pdf = pdfs[index];
                        final sizeMb = (pdf.fileSize / (1024 * 1024)).toStringAsFixed(1);
                        final isLoading = _loadingPdfId == pdf.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDF0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF5D73)),
                            title: Text(
                              pdf.originalName,
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '$sizeMb MB • ${pdf.description ?? "PDF Document"}',
                              style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.black, width: 1.5),
                                ),
                              ),
                              onPressed: isLoading ? null : () => _processAndAttachPdf(pdf),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Attach', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

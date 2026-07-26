import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfTextExtractorResult {
  final bool isSuccess;
  final String text;
  final int pageCount;
  final String? errorMessage;
  final List<String> chunks;

  PdfTextExtractorResult({
    required this.isSuccess,
    required this.text,
    this.pageCount = 0,
    this.errorMessage,
    this.chunks = const [],
  });
}

class PdfTextExtractorService {
  static const int maxChunkCharLength = 3500;

  /// Extracts readable text from raw PDF bytes using Syncfusion PDF TextExtractor.
  static PdfTextExtractorResult extractText(List<int> bytes) {
    if (bytes.isEmpty) {
      return PdfTextExtractorResult(
        isSuccess: false,
        text: '',
        errorMessage:
            "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR.",
      );
    }

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String fullText = extractor.extractText().trim();
      document.dispose();

      if (fullText.isEmpty || fullText.length < 10) {
        return PdfTextExtractorResult(
          isSuccess: false,
          text: '',
          pageCount: pageCount,
          errorMessage:
              "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR.",
        );
      }

      // Large PDF Chunking Strategy: Split into chunks if large
      final List<String> chunks = _chunkText(fullText, maxChunkCharLength);

      return PdfTextExtractorResult(
        isSuccess: true,
        text: fullText,
        pageCount: pageCount,
        chunks: chunks,
      );
    } catch (e) {
      debugPrint('PDF Text Extraction Error: $e');
      return PdfTextExtractorResult(
        isSuccess: false,
        text: '',
        errorMessage:
            "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR.",
      );
    }
  }

  /// Splits long document text into readable chunks without breaking sentences.
  static List<String> _chunkText(String text, int chunkSize) {
    if (text.length <= chunkSize) return [text];

    final List<String> chunks = [];
    int start = 0;

    while (start < text.length) {
      int end = start + chunkSize;
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }

      int breakIndex = text.lastIndexOf('\n', end);
      if (breakIndex <= start) {
        breakIndex = text.lastIndexOf('. ', end);
      }
      if (breakIndex <= start) {
        breakIndex = end;
      }

      chunks.add(text.substring(start, breakIndex).trim());
      start = breakIndex + 1;
    }

    return chunks;
  }
}

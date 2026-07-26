import 'dart:io';
import 'package:prep_tracker/features/pdf/data/models/pdf_model.dart';

/// ── PDF Library Repository Contract ──
abstract interface class PdfRepository {
  /// Stream of all uploaded PDFs.
  Stream<List<PdfModel>> watchPdfs(String userId);

  /// Fetch PDF list.
  Future<List<PdfModel>> getPdfs(String userId);

  /// Uploads a PDF file to Supabase Storage ('study-pdfs' bucket) and logs record in DB.
  Future<PdfModel> uploadPdf({
    required String userId,
    required String subjectId,
    required List<int> fileBytes, // Use List<int> which is globally available and fully supported
    required String originalName,
    int? pageCount,
  });

  /// Downloads a PDF file from storage to local temporary device directory.
  Future<File?> downloadPdf(String storagePath);

  /// Downloads a PDF file raw bytes directly.
  Future<List<int>> downloadBytes(String storagePath);

  /// Update PDF metadata (favorites, page edits).
  Future<PdfModel> updatePdf(PdfModel pdf);

  /// Delete PDF file permanently from both storage and DB records.
  Future<void> deletePdf(String pdfId, String storagePath);
}

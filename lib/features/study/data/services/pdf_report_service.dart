import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:prep_tracker/core/services/export_service.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/data/models/study_goal_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';

class PdfReportService {
  /// Generates a PDF Document bytes for study report.
  static Future<Uint8List> generateStudyReport({
    required String userName,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
    required List<StudySessionModel> sessions,
    required StudyGoalModel goals,
    required List<SubjectModel> subjects,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('MMM dd, yyyy');
    final rangeText = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    final generatedDate = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());

    // Calculate metrics
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = totalMinutes / 60.0;
    final totalSessionsCount = sessions.length;

    final longestSessionMin = sessions.isEmpty
        ? 0
        : sessions.map((s) => s.durationMinutes).reduce((curr, next) => curr > next ? curr : next);
    final avgSessionMin = totalSessionsCount > 0 ? (totalMinutes / totalSessionsCount).round() : 0;

    // Subject breakdown
    final Map<String, int> subjectMinutesMap = {};
    for (final s in sessions) {
      final subjectName = subjects.firstWhere(
        (sub) => sub.id == s.subjectId,
        orElse: () => SubjectModel(id: s.subjectId, userId: '', subjectName: 'Subject ${s.subjectId.substring(0, 4)}', color: '5B5FEF', icon: 'book'),
      ).subjectName;
      subjectMinutesMap[subjectName] = (subjectMinutesMap[subjectName] ?? 0) + s.durationMinutes;
    }

    // Type breakdown
    final Map<String, int> typeMinutesMap = {};
    for (final s in sessions) {
      typeMinutesMap[s.sessionType] = (typeMinutesMap[s.sessionType] ?? 0) + s.durationMinutes;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Header Banner ──
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo900,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PREPTRACKER BY YASH',
                        style: pw.TextStyle(
                          color: PdfColors.yellow400,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official Study Performance Report — $reportTitle',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Student: $userName',
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date Range: $rangeText',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Key Metrics Grid ──
            pw.Row(
              children: [
                _buildStatTile('Total Study Time', '${totalHours.toStringAsFixed(1)} Hours', PdfColors.blue100, PdfColors.blue900),
                pw.SizedBox(width: 10),
                _buildStatTile('Total Sessions', '$totalSessionsCount Sessions', PdfColors.green100, PdfColors.green900),
                pw.SizedBox(width: 10),
                _buildStatTile('Avg Session', '$avgSessionMin Mins', PdfColors.orange100, PdfColors.orange900),
                pw.SizedBox(width: 10),
                _buildStatTile('Longest Session', '$longestSessionMin Mins', PdfColors.purple100, PdfColors.purple900),
              ],
            ),

            pw.SizedBox(height: 20),

            // ── Subject Breakdown Table ──
            pw.Text(
              'Subject-wise Time Allocation',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Subject', 'Duration (Mins)', 'Duration (Hours)', '% Share'],
              data: subjectMinutesMap.entries.map((entry) {
                final hrs = (entry.value / 60.0).toStringAsFixed(1);
                final pct = totalMinutes > 0 ? ((entry.value / totalMinutes) * 100).toStringAsFixed(1) : '0.0';
                return [entry.key, entry.value.toString(), '$hrs hrs', '$pct%'];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),

            pw.SizedBox(height: 20),

            // ── Study Type Breakdown ──
            pw.Text(
              'Study Mode Breakdown',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Study Type', 'Total Time', '% of Study Time'],
              data: typeMinutesMap.entries.map((entry) {
                final hrs = (entry.value / 60.0).toStringAsFixed(1);
                final pct = totalMinutes > 0 ? ((entry.value / totalMinutes) * 100).toStringAsFixed(1) : '0.0';
                return [entry.key, '$hrs hrs (${entry.value} mins)', '$pct%'];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),

            pw.SizedBox(height: 20),

            // ── Detailed Sessions Log ──
            pw.Text(
              'Detailed Session History',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Subject', 'Type', 'Duration', 'Notes'],
              data: sessions.map((s) {
                final subjectName = subjects.firstWhere(
                  (sub) => sub.id == s.subjectId,
                  orElse: () => SubjectModel(id: s.subjectId, userId: '', subjectName: 'Subject', color: '5B5FEF', icon: 'book'),
                ).subjectName;
                final dateStr = DateFormat('MMM dd, yyyy').format(s.studyDate);
                return [
                  dateStr,
                  subjectName,
                  s.sessionType,
                  '${s.durationMinutes} mins',
                  s.sessionNotes ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by PrepTracker By Yash on $generatedDate',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatTile(String label, String value, PdfColor bg, PdfColor text) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: text, width: 1),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: pw.TextStyle(color: text, fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(color: text, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Displays native PDF print/share or direct file download.
  static Future<void> printOrShareReport({
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    await ExportService.downloadFile(pdfBytes, '$fileName.pdf', 'application/pdf');
  }
}

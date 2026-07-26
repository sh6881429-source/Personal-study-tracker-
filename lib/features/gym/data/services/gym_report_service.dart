import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';

/// ── Gym Attendance Report Service ──
/// Handles PDF generation for gym attendance histories.
class GymReportService {
  static Future<Uint8List> generateReport({
    required String userName,
    required DateTime start,
    required DateTime end,
    required List<GymAttendanceModel> logs,
    required int currentStreak,
    required int longestStreak,
    required double attendancePercentage,
  }) async {
    final pdf = pw.Document();

    // Sort logs by date descending for report readability
    final sortedLogs = List<GymAttendanceModel>.from(logs)
      ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

    final dateFormat = DateFormat('yyyy-MM-dd');
    final rangeStr = "${dateFormat.format(start)} to ${dateFormat.format(end)}";

    final presentCount = logs.where((l) => l.status == 'Present').length;
    final absentCount = logs.where((l) => l.status == 'Absent').length;
    final restCount = logs.where((l) => l.status == 'Rest Day').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PrepTracker By Yash',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Gym Attendance & Consistency Report',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
                pw.Text(
                  dateFormat.format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            // Metadata Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('User Profile: $userName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Reporting Period: $rangeStr', style: pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Statistics Summary Blocks
            pw.Text(
              'Summary Statistics',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Days Tracked: ${logs.length}', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text('Present Days: $presentCount', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text('Absent Days: $absentCount', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text('Rest Days: $restCount', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Current Streak: $currentStreak days', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text('Longest Streak: $longestStreak days', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Attendance rate: ${attendancePercentage.toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Detailed Logs Table
            pw.Text(
              'Log Details',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(100),
                1: pw.FixedColumnWidth(80),
                2: pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Notes / Remarks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                ...sortedLogs.map((log) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(dateFormat.format(log.attendanceDate), style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(log.status, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(log.notes ?? '-', style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}

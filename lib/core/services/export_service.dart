import 'dart:convert';
import 'package:prep_tracker/core/services/file_saver_stub.dart'
    if (dart.library.html) 'package:prep_tracker/core/services/file_saver_web.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/settings/data/models/settings_model.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';

/// ── User Data Export Service ──
/// Generates JSON, CSV, and PDF backups. Supports native Web and Mobile download/share.
class ExportService {
  /// Generate a unified JSON string representing all user data
  static String generateJsonBackup({
    required List<SubjectModel> subjects,
    required List<ChapterModel> chapters,
    required List<StudySessionModel> sessions,
    required List<BookmarkModel> bookmarks,
    required List<GymAttendanceModel> gymLogs,
    required UserSettingsModel settings,
    required DailyGoalModel dailyGoal,
  }) {
    final Map<String, dynamic> backup = {
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'daily_goal': dailyGoal.toJson(),
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'chapters': chapters.map((e) => e.toJson()).toList(),
      'study_sessions': sessions.map((e) => e.toJson()).toList(),
      'bookmarks': bookmarks.map((e) => e.toJson()).toList(),
      'gym_attendance': gymLogs.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Generate CSV data for each category
  static Map<String, String> generateCsvBackups({
    required List<SubjectModel> subjects,
    required List<ChapterModel> chapters,
    required List<StudySessionModel> sessions,
    required List<BookmarkModel> bookmarks,
    required List<GymAttendanceModel> gymLogs,
  }) {
    final Map<String, String> csvs = {};

    // 1. Subjects
    final subBuf = StringBuffer('id,subject_name,color,icon,is_archived\n');
    for (final s in subjects) {
      subBuf.writeln('${s.id},"${s.subjectName.replaceAll('"', '""')}",${s.color},${s.icon},${s.isArchived}');
    }
    csvs['subjects.csv'] = subBuf.toString();

    // 2. Chapters
    final chBuf = StringBuffer('id,subject_id,chapter_name,is_completed,target_revisions,current_revisions\n');
    for (final c in chapters) {
      chBuf.writeln('${c.id},${c.subjectId},"${c.chapterName.replaceAll('"', '""')}",${c.isCompleted},${c.targetRevisions},${c.currentRevisions}');
    }
    csvs['chapters.csv'] = chBuf.toString();

    // 3. Study Sessions
    final sessBuf = StringBuffer('id,subject_id,chapter_id,duration_minutes,study_date,session_notes\n');
    for (final s in sessions) {
      sessBuf.writeln('${s.id},${s.subjectId},${s.chapterId ?? ''},${s.durationMinutes},${s.studyDate.toIso8601String().substring(0, 10)},"${(s.sessionNotes ?? '').replaceAll('"', '""')}"');
    }
    csvs['study_sessions.csv'] = sessBuf.toString();

    // 4. Bookmarks
    final bBuf = StringBuffer('id,subject_id,title,priority,is_completed\n');
    for (final b in bookmarks) {
      bBuf.writeln('${b.id},${b.subjectId ?? ''},"${b.title.replaceAll('"', '""')}",${b.priority},${b.isCompleted}');
    }
    csvs['bookmarks.csv'] = bBuf.toString();

    // 5. Gym Attendance
    final gymBuf = StringBuffer('id,attendance_date,status,notes\n');
    for (final g in gymLogs) {
      gymBuf.writeln('${g.id},${g.attendanceDate.toIso8601String().substring(0, 10)},${g.status},"${(g.notes ?? '').replaceAll('"', '""')}"');
    }
    csvs['gym_attendance.csv'] = gymBuf.toString();

    return csvs;
  }

  /// Generate a professional PDF summary report using the `pdf` library
  static Future<Uint8List> generatePdfReport({
    required String userName,
    required String userEmail,
    required int studyStreak,
    required int gymStreak,
    required double totalStudyHours,
    required int totalStudySessions,
    required int subjectsCreated,
    required int completedChapters,
    required int pendingChapters,
    required double revisionProgress,
    required double gymAttendancePercentage,
    required double currentMonthStudyHours,
    required List<SubjectModel> subjects,
    required List<BookmarkModel> bookmarks,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PrepTracker — Performance Report',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Profile Section
            pw.Text('User Profile',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: $userName'),
                    pw.Text('Email: $userEmail'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Study Streak: $studyStreak Days'),
                    pw.Text('Gym Streak: $gymStreak Days'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Stats Grid Table
            pw.Text('Personal Dashboard Statistics',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(children: [
                  _pdfCell('Metric', isHeader: true),
                  _pdfCell('Value', isHeader: true),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Total Study Hours'),
                  _pdfCell('${totalStudyHours.toStringAsFixed(1)} hrs'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Current Month Study Hours'),
                  _pdfCell('${currentMonthStudyHours.toStringAsFixed(1)} hrs'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Total Study Sessions'),
                  _pdfCell('$totalStudySessions'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Subjects Created'),
                  _pdfCell('$subjectsCreated'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Completed Chapters'),
                  _pdfCell('$completedChapters'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Pending Chapters'),
                  _pdfCell('$pendingChapters'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Revision Progress'),
                  _pdfCell('${revisionProgress.toStringAsFixed(1)}%'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Gym Attendance'),
                  _pdfCell('${gymAttendancePercentage.toStringAsFixed(1)}%'),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Subjects Summary
            pw.Text('Subject Summary',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 6),
            subjects.isEmpty
                ? pw.Text('No subjects created yet.')
                : pw.Bullet(
                    text: subjects.map((e) => e.subjectName).join(', ')),
            pw.SizedBox(height: 20),

            // Bookmarks Summary
            pw.Text('Bookmarks Summary',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 6),
            bookmarks.isEmpty
                ? pw.Text('No bookmarks logged.')
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(children: [
                        _pdfCell('Title', isHeader: true),
                        _pdfCell('Priority', isHeader: true),
                        _pdfCell('Status', isHeader: true),
                      ]),
                      ...bookmarks.take(10).map((b) => pw.TableRow(children: [
                            _pdfCell(b.title),
                            _pdfCell(b.priority),
                            _pdfCell(b.isCompleted ? 'Completed' : 'Pending'),
                          ])),
                    ],
                  ),
            pw.SizedBox(height: 30),

            // Footer / Disclaimer
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Generated by PrepTracker By Yash',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Downloads/shares the generated file bytes depending on the running platform.
  static Future<void> downloadFile(Uint8List bytes, String fileName, String mimeType) async {
    if (kIsWeb) {
      // Use dart:html Blob API for reliable browser file download
      saveFileOnWeb(bytes, fileName, mimeType);
    } else {
      // Mobile native share/save sheet
      final file = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: mimeType,
      );
      await Share.shareXFiles([file], text: 'Exported report from PrepTracker By Yash');
    }
  }
}

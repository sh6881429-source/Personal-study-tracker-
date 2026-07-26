import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/chat_message_model.dart';

class AiExportService {
  /// Converts chat messages to Markdown string
  static String exportToMarkdown(ChatSessionModel session) {
    final buffer = StringBuffer();
    buffer.writeln('# ${session.title}');
    buffer.writeln('_Exported from PrepTracker By Yash • ${DateTime.now().toString().split('.').first}_\n');
    buffer.writeln('---\n');

    for (var msg in session.messages) {
      final role = msg.role == MessageRole.user ? '👤 **You**' : '🤖 **Yash Bot**';
      buffer.writeln('$role (${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}):\n');
      if (msg.pdfName != null) {
        buffer.writeln('> 📄 Attached PDF: ${msg.pdfName}\n');
      }
      buffer.writeln('${msg.content}\n');
      buffer.writeln('---\n');
    }

    return buffer.toString();
  }

  /// Converts chat messages to Plain Text string
  static String exportToPlainText(ChatSessionModel session) {
    final buffer = StringBuffer();
    buffer.writeln('=== ${session.title.toUpperCase()} ===');
    buffer.writeln('PrepTracker By Yash AI Assistant Export\n');

    for (var msg in session.messages) {
      final sender = msg.role == MessageRole.user ? 'USER' : 'YASH BOT';
      buffer.writeln('[$sender - ${msg.timestamp.toString().split('.').first}]');
      if (msg.pdfName != null) {
        buffer.writeln('PDF: ${msg.pdfName}');
      }
      buffer.writeln(msg.content);
      buffer.writeln('\n----------------------------------------\n');
    }

    return buffer.toString();
  }

  /// Downloads text or markdown string on web
  static void downloadFileWeb(String content, String fileName, String mimeType) {
    if (kIsWeb) {
      try {
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName);
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } catch (e) {
        debugPrint('Error downloading web file: $e');
      }
    }
  }

  /// Generates PDF document bytes for a chat session
  static Future<Uint8List> generatePdfBytes(ChatSessionModel session) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PrepTracker By Yash — Yash Bot Chat Export',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    session.createdAt.toString().split(' ').first,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              session.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 16),
            ...session.messages.map((msg) {
              final isUser = msg.role == MessageRole.user;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: isUser ? PdfColors.blue50 : PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: isUser ? PdfColors.blue300 : PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      isUser ? 'You:' : 'Yash Bot:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: isUser ? PdfColors.blue900 : PdfColors.purple900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (msg.pdfName != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          '[Attachment: ${msg.pdfName}]',
                          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                        ),
                      ),
                    pw.Text(
                      msg.content,
                      style: const pw.TextStyle(fontSize: 10, height: 1.3),
                    ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Downloads or opens print preview for PDF
  static Future<void> exportPdf(ChatSessionModel session) async {
    final pdfBytes = await generatePdfBytes(session);
    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${session.title.replaceAll(' ', '_')}.pdf');
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${session.title}.pdf',
      );
    }
  }
}

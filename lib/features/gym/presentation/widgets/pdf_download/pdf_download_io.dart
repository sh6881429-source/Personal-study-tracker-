import 'dart:io' show File;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart';

Future<void> downloadOrSharePdf(
  Uint8List pdfBytes,
  String filename,
  String shareText,
) async {
  final output = await getTemporaryDirectory();
  final file = File("${output.path}/$filename");
  await file.writeAsBytes(pdfBytes);
  await Share.shareXFiles([XFile(file.path)], text: shareText);
}
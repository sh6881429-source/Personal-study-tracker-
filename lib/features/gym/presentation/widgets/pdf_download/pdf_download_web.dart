// ignore: avoid_web_libraries_in_flutter
import 'dart:convert' show base64Encode;
import 'dart:js' as js;
import 'dart:typed_data';

Future<void> downloadOrSharePdf(
  Uint8List pdfBytes,
  String filename,
  String shareText,
) async {
  final base64Pdf = base64Encode(pdfBytes);
  js.context.callMethod('eval', [
    '''
    var link = document.createElement('a');
    link.href = 'data:application/pdf;base64,$base64Pdf';
    link.download = '$filename';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    '''
  ]);
}
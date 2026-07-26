import 'dart:typed_data';

/// Non-web stub — file saving not supported on this platform via dart:html.
void saveFileOnWeb(Uint8List bytes, String fileName, String mimeType) {
  throw UnsupportedError('saveFileOnWeb is only supported on Flutter Web.');
}

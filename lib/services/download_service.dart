import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

class DownloadService {
  static const String albumName = 'Pic Studios';
  static const Duration _httpTimeout = Duration(seconds: 60);

  /// Download [url] and save the image to the device gallery under the
  /// "Pic Studios" album.
  ///
  /// [onProgress] (optional) is invoked with (bytesReceived, totalBytes) as
  /// chunks arrive. If the server doesn't send a Content-Length header,
  /// `totalBytes` will be 0 and a determinate progress bar can't be shown
  /// — fall back to indeterminate in the caller.
  ///
  /// Throws on permission denial, network failure, HTTP error, or timeout.
  static Future<void> downloadImage(
    String url,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw Exception('Photos permission denied');
      }
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(_httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('Download failed (HTTP ${response.statusCode})');
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final buffer = BytesBuilder(copy: false);

      await for (final chunk in response.stream) {
        buffer.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      final bytes = buffer.takeBytes();
      await Gal.putImageBytes(
        bytes,
        album: albumName,
        name: _displayName(fileName),
      );
    } finally {
      client.close();
    }
  }

  /// Strip the trailing extension from [fileName]; Gal sets the extension
  /// itself based on the bytes' MIME type, so passing `photo1.jpg` would
  /// produce `photo1.jpg.jpg`.
  static String _displayName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot <= 0) return fileName;
    return fileName.substring(0, lastDot);
  }
}

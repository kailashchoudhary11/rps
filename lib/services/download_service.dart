import 'dart:io';

import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  /// Album the saved image lands in inside the Photos / Gallery app.
  static const String albumName = 'Pic Studios';

  /// Download [url] and save it to the device's photo gallery under the
  /// "Pic Studios" album. Throws on permission denial, network failure,
  /// or save failure.
  static Future<void> downloadImage(String url, String fileName) async {
    // toAlbum:true would additionally check WRITE_EXTERNAL_STORAGE, which is
    // capped at API 28 in the manifest and isn't grantable on Android 10+.
    // That makes the check return false even after the user granted
    // READ_MEDIA_IMAGES. Basic hasAccess() is sufficient — the album:
    // parameter on Gal.putImage works through MediaStore on its own.
    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw Exception('Photos permission denied');
      }
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    // gal needs a file path (not bytes), so write to a temp file first.
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(response.bodyBytes);

    try {
      await Gal.putImage(tempFile.path, album: albumName);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}

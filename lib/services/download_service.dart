import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted || status.isLimited;
    } else if (Platform.isIOS) {
      return true;
    }
    return true;
  }

  /// Download image from URL
  static Future<String> downloadImage(
    String url,
    String fileName, {
    Function(double)? onProgress,
  }) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get app-specific external storage directory
      Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not get download directory');
      }

      // Create subdirectory for RajasthaniPhotoStudios
      directory = Directory('${directory.path}/RajasthaniPhotoStudios');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Download file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  /// Get download directory path
  static Future<String> getDownloadDirectory() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory == null) return '';
    return '${directory.path}/RajasthaniPhotoStudios';
  }
}

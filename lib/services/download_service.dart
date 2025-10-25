import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // For older versions, request the permission
      final status = await Permission.storage.request();
      return status.isGranted || status.isLimited;
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit permission for app directory
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

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Navigate to Pictures/RajasthaniPhotoStudios
        final picturesPath = directory!.path.split('Android')[0];
        directory = Directory('${picturesPath}Pictures/RajasthaniPhotoStudios');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not get download directory');
      }

      // Create directory if it doesn't exist
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
      rethrow;
    }
  }

  /// Get download directory path
  static Future<String> getDownloadDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      final picturesPath = directory!.path.split('Android')[0];
      return '${picturesPath}Pictures/RajasthaniPhotoStudios';
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    return '';
  }
}


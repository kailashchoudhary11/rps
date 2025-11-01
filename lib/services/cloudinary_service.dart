import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/photo_item.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  static const String cloudName = 'dohchksp8';

  factory CloudinaryService() {
    return _instance;
  }

  CloudinaryService._internal();

  /// Get all photos for an event (using tag-based public listing)
  Future<List<PhotoItem>> getEventPhotos(String eventTag) async {
    try {
      final url = Uri.parse(
        'https://res.cloudinary.com/$cloudName/image/list/$eventTag.json'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Error fetching Cloudinary list: ${response.statusCode}');
        print(response.body);
        return [];
      }

      final data = json.decode(response.body);
      final resources = data['resources'] as List<dynamic>? ?? [];

      return resources.map((resource) {
        final publicId = resource['public_id'] as String;
        final createdAtStr = resource['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : null;

        return PhotoItem(
          publicId: publicId,
          eventCode: eventTag,
          uploadedAt: createdAt,
        );
      }).toList();
    } catch (e) {
      print('Exception while fetching Cloudinary photos: $e');
      return [];
    }
  }

  /// Get all videos for an event (using tag-based public listing)
  Future<List<PhotoItem>> getEventVideos(String eventTag) async {
    try {
      // Try to fetch videos using the video list endpoint
      final url = Uri.parse(
        'https://res.cloudinary.com/$cloudName/video/list/$eventTag.json'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Error fetching Cloudinary videos: ${response.statusCode}');
        print(response.body);
        return [];
      }

      final data = json.decode(response.body);
      final resources = data['resources'] as List<dynamic>? ?? [];

      return resources.map((resource) {
        final publicId = resource['public_id'] as String;
        final createdAtStr = resource['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : null;

        return PhotoItem(
          publicId: publicId,
          eventCode: eventTag,
          uploadedAt: createdAt,
        );
      }).toList();
    } catch (e) {
      print('Exception while fetching Cloudinary videos: $e');
      return [];
    }
  }

  /// Image optimization URL generator
  static String getOptimizedUrl(String publicId,
      {int? width, int? height, bool isThumb = false}) {
    String transform = 'q_auto,f_auto';
    if (width != null) transform += ',w_$width';
    if (height != null) transform += ',h_$height';
    if (isThumb) transform += ',c_thumb,g_center';
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transform/$publicId';
  }

  /// Original-quality download link
  static String getDownloadUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/fl_attachment/$publicId';
  }

  /// Get video URL
  static String getVideoUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudName/video/upload/$publicId';
  }

  /// Get video thumbnail URL
  static String getVideoThumbnail(String publicId) {
    return 'https://res.cloudinary.com/$cloudName/video/upload/so_0,w_300,h_300,c_thumb/$publicId.jpg';
  }

  /// Search helper (uses publicId as name)
  List<PhotoItem> searchPhotos(List<PhotoItem> photos, String query) {
    if (query.isEmpty) return photos;
    return photos
        .where((photo) => photo.publicId.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}


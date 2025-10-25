import '../services/cloudinary_service.dart';

class PhotoItem {
  final String publicId;
  final String eventCode;
  final DateTime? uploadedAt;

  PhotoItem({
    required this.publicId,
    required this.eventCode,
    this.uploadedAt,
  });

  /// Get the filename from publicId
  String get name {
    final parts = publicId.split('/');
    return parts.isNotEmpty ? parts.last : publicId;
  }

  /// Get optimized URL for display
  String get url {
    return CloudinaryService.getOptimizedUrl(
      publicId,
      width: 800, // Reasonable size for display
    );
  }

  /// Get thumbnail URL
  String get thumbnailUrl {
    return CloudinaryService.getOptimizedUrl(
      publicId,
      width: 300,
      height: 300,
      isThumb: true,
    );
  }

  /// Get full resolution URL for download
  String get downloadUrl {
    return CloudinaryService.getDownloadUrl(publicId);
  }

  /// Create PhotoItem from Cloudinary resource
  factory PhotoItem.fromCloudinaryResource(Map<String, dynamic> resource, String eventCode) {
    return PhotoItem(
      publicId: resource['public_id'] as String,
      eventCode: eventCode,
      uploadedAt: resource['created_at'] != null 
          ? DateTime.parse(resource['created_at'] as String)
          : null,
    );
  }
}
class PhotoItem {
  final String name;
  final String eventCode;
  final DateTime? uploadedAt;
  final String url;
  final String thumbnailUrl;

  PhotoItem({
    required this.name,
    required this.eventCode,
    required this.url,
    required this.thumbnailUrl,
    this.uploadedAt,
  });

  /// Presigned URLs are valid for both display and download.
  String get downloadUrl => url;

  factory PhotoItem.fromJson(Map<String, dynamic> json, String eventCode) {
    final uploaded = json['uploadedAt'];
    return PhotoItem(
      name: json['name'] as String,
      eventCode: eventCode,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      uploadedAt: uploaded is String ? DateTime.parse(uploaded) : null,
    );
  }
}

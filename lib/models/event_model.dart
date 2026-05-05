class EventModel {
  final String eventCode;
  final String eventName;
  final String studioName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int photoCount;

  EventModel({
    required this.eventCode,
    required this.eventName,
    required this.studioName,
    required this.createdAt,
    this.expiresAt,
    required this.photoCount,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventCode: json['code'] as String,
      eventName: json['eventName'] as String,
      studioName: json['studioName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      photoCount: json['photoCount'] as int,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

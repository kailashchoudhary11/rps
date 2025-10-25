import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventCode: doc.id,
      eventName: data['eventName'] ?? '',
      studioName: data['studioName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      photoCount: data['photoCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'studioName': studioName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'photoCount': photoCount,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
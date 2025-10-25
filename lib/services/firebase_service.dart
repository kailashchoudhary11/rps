import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if an event code exists and is valid
  Future<EventModel?> getEventByCode(String eventCode) async {
    try {
      final doc = await _firestore.collection('events').doc(eventCode).get();
      
      if (!doc.exists) {
        return null;
      }

      final event = EventModel.fromFirestore(doc);
      
      // Check if event is expired
      if (event.isExpired) {
        throw Exception('This event code has expired');
      }

      return event;
    } catch (e) {
      rethrow;
    }
  }

  /// Update photo count for an event
  Future<void> updatePhotoCount(String eventCode, int count) async {
    try {
      await _firestore.collection('events').doc(eventCode).update({
        'photoCount': count,
      });
    } catch (e) {
      // Handle or ignore error
      print('Error updating photo count: $e');
    }
  }
}
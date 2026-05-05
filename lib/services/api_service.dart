import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';
import '../models/photo_item.dart';

class ApiService {
  // Override at build/run time:
  //   flutter run --dart-define=API_BASE_URL=http://<vm-ip>:8369
  //   flutter build apk --dart-define=API_BASE_URL=https://api.example.com
  // Default targets the Android emulator → host machine via 10.0.2.2.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Returns the event for [code], or null if it does not exist.
  /// Throws if the event has expired or the request fails for another reason.
  Future<EventModel?> getEvent(String code) async {
    final response = await http.get(Uri.parse('$baseUrl/events/$code'));

    if (response.statusCode == 404) return null;
    if (response.statusCode == 410) {
      throw Exception('This event code has expired');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load event (HTTP ${response.statusCode})',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return EventModel.fromJson(data);
  }

  /// Photo manifest for [code] with presigned R2 URLs.
  Future<List<PhotoItem>> getEventPhotos(String code) async {
    final response = await http.get(Uri.parse('$baseUrl/events/$code/photos'));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load photos (HTTP ${response.statusCode})',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final photos = data['photos'] as List<dynamic>;
    return photos
        .map((p) => PhotoItem.fromJson(p as Map<String, dynamic>, code))
        .toList();
  }

  /// Filter photos by filename substring (case-insensitive).
  List<PhotoItem> searchPhotos(List<PhotoItem> photos, String query) {
    if (query.isEmpty) return photos;
    final q = query.toLowerCase();
    return photos.where((p) => p.name.toLowerCase().contains(q)).toList();
  }
}

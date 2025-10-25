# Rajasthani Photo Studios 📸

A Flutter app for event photo sharing - making it easy for photo studios to share event photos with guests using simple access codes.

## Features

- 🔑 **Code-based Access**: Simple event code system for accessing photos
- 📱 **Beautiful UI**: Rajasthani-themed design with gradient backgrounds
- 🖼️ **Photo Gallery**: Grid layout with smooth scrolling and thumbnails
- 🔍 **Search**: Search photos by filename
- 📥 **Download**: Download individual photos to device
- 🔎 **Full-screen Viewer**: Pinch-to-zoom with photo navigation
- 💾 **Smart Caching**: Cached images for better performance
- ⚡ **Fast Loading**: Shimmer loading effects and optimized images

## Project Structure

```
lib/
├── main.dart                        # App entry point & Firebase init
├── models/                          # Data models
│   ├── event_model.dart            # Event information model
│   └── photo_item.dart             # Photo metadata model
├── screens/                         # App screens
│   ├── code_entry_screen.dart      # Event code entry
│   ├── gallery_screen.dart         # Photo grid gallery
│   └── photo_viewer_screen.dart    # Full-screen photo viewer
└── services/                        # Business logic
    ├── firebase_service.dart       # Firebase/Firestore operations
    └── download_service.dart       # Photo download handling
```

## Setup Instructions

### 1. Firebase Setup (for Event Data)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (no credit card needed!)
3. Enable **Cloud Firestore** only

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /events/{eventCode} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 2. Cloudinary Setup (for Photos)

1. Create free account at [Cloudinary.com](https://cloudinary.com)
2. No credit card required!
3. Get your Cloud Name and create Upload Preset
4. See [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md) for details

### 3. Configure Flutter App

1. **Install FlutterFire CLI:**
```bash
dart pub global activate flutterfire_cli
```

2. **Configure Firebase:**
```bash
flutterfire configure
```

3. **Update Cloudinary Config:**
Edit `lib/services/cloudinary_service.dart`:
```dart
static const String cloudName = 'YOUR_CLOUD_NAME';
static const String uploadPreset = 'YOUR_UPLOAD_PRESET';
```

## Installation

1. **Clone the repository**

```bash
git clone <your-repo-url>
cd rps
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Configure Firebase** (see Firebase Setup above)

4. **Run the app**

```bash
flutter run
```

## Usage Guide

### For Guests (App Users)

1. Open the app
2. Enter the event code provided by your photo studio
3. Browse photos in grid view
4. Tap any photo to view full-screen
5. Use the download button to save photos

### For Studios (Manual Upload for MVP)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Firestore Database**
3. Create a document in `events` collection:
   - Document ID: Your event code (e.g., `WED2024`)
   - Fields: eventName, studioName, createdAt, photoCount

4. Navigate to **Storage**
5. Create folder: `events/{eventCode}/photos/`
6. Upload photos to this folder

**Example Event Document:**

```json
{
  "eventName": "Sharma Wedding",
  "studioName": "Rajasthani Photo Studios",
  "createdAt": "2024-10-24",
  "photoCount": 150,
  "expiresAt": null
}
```

## Testing

Run tests:

```bash
flutter test
```

## Platform Support

- ✅ **Android** (Tested on Android 8+)
- ✅ **iOS** (Tested on iOS 12+)
- ⚠️ **Web** (Download functionality may vary)
- ⚠️ **Desktop** (Windows/macOS/Linux - not optimized yet)

## Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save photos to your gallery</string>
```

## Future Enhancements

- [ ] Studio dashboard for uploading photos
- [ ] Bulk download (download all photos)
- [ ] Video support
- [ ] Favorites/Collections
- [ ] Share photos via social media
- [ ] QR code scanning for event codes
- [ ] Analytics dashboard for studios
- [ ] Push notifications for new uploads

## Troubleshooting

**Firebase not initialized error:**
- Make sure you've run `flutterfire configure`
- Check that `firebase_options.dart` exists in `lib/`
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) exists

**Photos not loading:**
- Check Firebase Storage rules allow public read access
- Verify photos are in correct path: `events/{eventCode}/photos/`
- Check internet connection

**Download not working:**
- Grant storage permissions in app settings
- Check available storage space
- Android 13+: Photos save to `Pictures/RajasthaniPhotoStudios`

## License

Private project - All rights reserved

## Contact

For support or inquiries, contact your development team.

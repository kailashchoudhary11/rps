# Quick Start Guide - Rajasthani Photo Studios

Get up and running in 5 minutes!

## Prerequisites

- ✅ Flutter installed (run `flutter doctor` to check)
- ✅ Android Studio or Xcode installed
- ✅ Google account for Firebase

## Step 1: Install Dependencies (2 minutes)

```bash
cd rps
flutter pub get
```

## Step 2: Firebase Configuration (3 minutes)

### Option A: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

1. Select or create Firebase project
2. Choose platforms (Android, iOS)
3. Done! `firebase_options.dart` is created automatically

### Option B: Manual Setup

See detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

## Step 3: Set Up Firebase Services (5 minutes)

### Enable Firestore

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. **Build** → **Firestore Database** → **Create database**
4. Choose **Test mode** → Select location → **Enable**

### Enable Storage

1. **Build** → **Storage** → **Get started**
2. Choose **Test mode** → **Done**

### Add Security Rules

**Firestore Rules:**
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

**Storage Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /events/{eventCode}/photos/{photoName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 4: Create Test Event (3 minutes)

### In Firestore:

1. **Firestore Database** → **Start collection**
2. Collection ID: `events`
3. Document ID: `TEST2024`
4. Add fields:
   - `eventName` (string): "Test Event"
   - `studioName` (string): "Rajasthani Photo Studios"
   - `createdAt` (timestamp): Click "Set to now"
   - `photoCount` (number): 0

### In Storage:

1. **Storage** → Create folders:
   - `events/TEST2024/photos/`
2. Upload 2-3 test images to `photos/` folder

## Step 5: Run the App! (1 minute)

```bash
# Run on connected device or emulator
flutter run
```

### Test the app:
1. Open app
2. Enter code: `TEST2024`
3. Click "Access Photos"
4. See your test photos
5. Tap to view full-screen
6. Try downloading a photo

## Troubleshooting

### ❌ "No Firebase App created"
```bash
# Re-run configure
flutterfire configure
```

### ❌ Build fails
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### ❌ Photos not loading
- Check Firebase Storage rules (allow read: if true)
- Verify photos are in `events/TEST2024/photos/`
- Check internet connection

### ❌ Permission denied on download
- Grant storage permission in phone settings
- Android 13+: Grant "Files and media" permission

## Next Steps

✅ **You're all set!** Now you can:

1. **Create real events:**
   - Add documents to Firestore `events` collection
   - Upload photos to Storage
   - Share event codes with guests

2. **Customize the app:**
   - Change colors in `lib/main.dart`
   - Update app name in `pubspec.yaml`
   - Add your studio logo

3. **Deploy:**
   - Build for production
   - Publish to Play Store / App Store

## Project Structure

```
lib/
├── main.dart                      # App entry & theme
├── models/                        # Data models
│   ├── event_model.dart          # Event info
│   └── photo_item.dart           # Photo metadata
├── screens/                       # UI screens
│   ├── code_entry_screen.dart    # Home screen
│   ├── gallery_screen.dart       # Photo grid
│   └── photo_viewer_screen.dart  # Full-screen viewer
└── services/                      # Business logic
    ├── firebase_service.dart     # Firebase ops
    └── download_service.dart     # Download handler
```

## Key Files

- **`pubspec.yaml`** - Dependencies and app config
- **`README.md`** - Full documentation
- **`FIREBASE_SETUP.md`** - Detailed Firebase guide
- **`firebase_options.dart`** - Auto-generated Firebase config

## Common Tasks

### Add new event:
1. Firestore: Create document in `events` collection
2. Storage: Upload photos to `events/{code}/photos/`

### Change theme colors:
Edit `lib/main.dart` → `ThemeData` → `colorScheme`

### Update app name:
- `pubspec.yaml` → `name`
- `android/app/src/main/AndroidManifest.xml` → `android:label`
- `ios/Runner/Info.plist` → `CFBundleDisplayName`

## Support

For detailed documentation, see [README.md](README.md)

For Firebase setup help, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

---

Happy coding! 📸✨


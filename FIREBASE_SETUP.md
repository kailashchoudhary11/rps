# Firebase Setup Guide

Complete step-by-step guide to set up Firebase for Rajasthani Photo Studios app.

## Prerequisites

- Flutter installed and configured
- Google account
- Firebase account (free tier is sufficient for MVP)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project**
3. Enter project name: `rajasthani-photo-studios`
4. Disable Google Analytics (optional for MVP)
5. Click **Create project**

## Step 2: Enable Firebase Services

### Enable Firestore Database

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (we'll add rules later)
4. Choose your location (e.g., `asia-south1` for India)
5. Click **Enable**

### Enable Firebase Storage

1. In Firebase Console, go to **Build** → **Storage**
2. Click **Get started**
3. Select **Start in test mode**
4. Choose same location as Firestore
5. Click **Done**

## Step 3: Register Your App

### For Android

1. In Firebase Console, click **Add app** → **Android**
2. Enter Android package name: `com.example.rps` (or your custom package)
   - Find in: `android/app/build.gradle.kts` → `applicationId`
3. Enter app nickname: `Rajasthani Photo Studios Android`
4. Skip SHA-1 for now (needed later for Firebase Auth)
5. Click **Register app**
6. Download `google-services.json`
7. Move it to: `android/app/google-services.json`
8. Click **Next** and **Continue to console**

### For iOS

1. In Firebase Console, click **Add app** → **iOS**
2. Enter iOS bundle ID: `com.example.rps` (or your custom bundle)
   - Find in: `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`
3. Enter app nickname: `Rajasthani Photo Studios iOS`
4. Skip App Store ID for now
5. Click **Register app**
6. Download `GoogleService-Info.plist`
7. Open Xcode: `open ios/Runner.xcworkspace`
8. Drag `GoogleService-Info.plist` into `Runner` folder in Xcode
   - ✅ Check "Copy items if needed"
   - ✅ Select "Runner" target
9. Click **Next** and **Continue to console**

## Step 4: Configure FlutterFire (Recommended)

### Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Add to PATH if needed (add to `~/.zshrc` or `~/.bashrc`):

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Configure Firebase in Flutter

```bash
# Run from project root
flutterfire configure
```

This will:
- ✅ Create `lib/firebase_options.dart`
- ✅ Link your Flutter app with Firebase project
- ✅ Configure for all platforms

**Select the Firebase project you just created when prompted.**

## Step 5: Set Up Firestore Security Rules

1. In Firebase Console, go to **Firestore Database** → **Rules**
2. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Event documents - anyone can read, only authenticated users can write
    match /events/{eventCode} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

### Explanation:
- **`allow read: if true`**: Anyone with the app can read event data
- **`allow write: if request.auth != null`**: Only authenticated users (future studio dashboard) can create/edit events

## Step 6: Set Up Storage Security Rules

1. In Firebase Console, go to **Storage** → **Rules**
2. Replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Event photos - anyone can read, only authenticated users can upload
    match /events/{eventCode}/photos/{photoName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

## Step 7: Create Test Event Data

### Create Event in Firestore

1. Go to **Firestore Database** → **Data**
2. Click **Start collection**
3. Collection ID: `events`
4. Document ID: `TEST2024` (this will be your event code)
5. Add fields:

| Field Name | Type | Value |
|------------|------|-------|
| eventName | string | "Test Wedding Event" |
| studioName | string | "Rajasthani Photo Studios" |
| createdAt | timestamp | (click "Set to now") |
| photoCount | number | 0 |
| expiresAt | timestamp | (leave empty or set future date) |

6. Click **Save**

### Upload Test Photos to Storage

1. Go to **Storage** → **Files**
2. Create folder structure:
   - Click **Create folder** → name: `events`
   - Inside `events`, create folder: `TEST2024`
   - Inside `TEST2024`, create folder: `photos`
3. Click on `photos` folder
4. Click **Upload files**
5. Select 3-5 sample photos from your computer
6. Wait for upload to complete

## Step 8: Test the App

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
# For Android
flutter run

# For iOS
flutter run
```

### Test Flow

1. App should open to code entry screen
2. Enter code: `TEST2024`
3. Click "Access Photos"
4. You should see the test photos in a grid
5. Tap a photo to view full-screen
6. Try downloading a photo

## Troubleshooting

### ❌ Error: "No Firebase App has been created"

**Solution:**
- Make sure `flutterfire configure` was run successfully
- Check that `lib/firebase_options.dart` exists
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in correct location

### ❌ Error: "PERMISSION_DENIED" when loading photos

**Solution:**
- Check Storage rules allow public read (`allow read: if true`)
- Make sure photos are in correct path: `events/{eventCode}/photos/`
- Verify your event code matches the Firestore document ID

### ❌ Photos not showing up

**Solution:**
- Check Firebase Console → Storage to verify photos are uploaded
- Ensure photos are in: `events/TEST2024/photos/`
- Check your internet connection
- Look for errors in console: `flutter run --verbose`

### ❌ Download not working on Android

**Solution:**
- Add permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```
- On Android 13+, grant "Files and media" permission manually in app settings

### ❌ Build fails on Android

**Solution:**
- Check `android/build.gradle.kts` has:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```
- Check `android/app/build.gradle.kts` has at bottom:
```kotlin
apply plugin: 'com.google.gms.google-services'
```

## Usage for Real Events

### Creating a New Event

1. **In Firestore:**
   - Go to Firestore Database
   - Add new document to `events` collection
   - Document ID = Event code (e.g., `SHARMA-WED-2024`)
   - Add fields: eventName, studioName, createdAt, photoCount

2. **In Storage:**
   - Create folder: `events/{your-event-code}/photos/`
   - Upload event photos

3. **Share Code:**
   - Give the event code to event attendees
   - They enter it in the app to access photos

### Event Code Best Practices

- Use uppercase letters and numbers
- Keep it short (6-15 characters)
- Make it memorable
- Examples:
  - `SHARMA-WED-2024`
  - `RAJ-BDA-1024`
  - `DIWALI-2024`

## Cost Estimation (Free Tier)

Firebase free tier is sufficient for starting:

| Service | Free Tier | Typical MVP Usage |
|---------|-----------|-------------------|
| **Firestore** | 1 GB storage, 50K reads/day | ✅ Plenty for 100+ events |
| **Storage** | 5 GB storage, 1 GB/day downloads | ✅ Good for 1000+ photos |
| **Bandwidth** | 10 GB/month | ✅ Sufficient for MVP |

**Upgrade needed when:**
- More than 500 photo downloads per day
- Storing more than 5,000 photos
- 100+ active events simultaneously

## Next Steps

1. ✅ Test with real photos
2. ✅ Share test event code with friends/family
3. ✅ Gather feedback on UX
4. 📱 Prepare for production:
   - Update Firebase rules for production
   - Set up Firebase Analytics
   - Configure crash reporting
   - Add app icon and splash screen
5. 🚀 Build and deploy to Play Store / App Store

## Support

For issues:
1. Check Firebase Console logs
2. Check Flutter console output
3. Review Firebase [documentation](https://firebase.google.com/docs)
4. Contact development team


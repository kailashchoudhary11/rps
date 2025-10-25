# Cloudinary Setup Guide

Quick guide to set up Cloudinary for Rajasthani Photo Studios app.

## Step 1: Create Cloudinary Account

1. Go to [Cloudinary.com](https://cloudinary.com)
2. Sign up for a free account
3. No credit card required!

## Step 2: Get Credentials

1. Go to Dashboard
2. Note down:
   - Cloud Name
   - API Key (optional for unsigned uploads)
   - API Secret (optional for unsigned uploads)

## Step 3: Create Upload Preset (for Unsigned Uploads)

1. Go to Settings → Upload
2. Scroll to "Upload presets"
3. Click "Add upload preset"
4. Settings:
   - Signing Mode: Unsigned
   - Folder: `rajasthani-photo-studios`
   - Allowed formats: jpg, png, webp
   - Enable "Use filename or externally defined Public ID"

## Step 4: Configure App

1. Open `lib/services/cloudinary_service.dart`
2. Replace credentials:
```dart
static const String cloudName = 'YOUR_CLOUD_NAME';
static const String uploadPreset = 'YOUR_UPLOAD_PRESET';
```

## Step 5: Folder Structure

For better organization, use this structure in Cloudinary:
```
rajasthani-photo-studios/
  ├── EVENT_CODE1/
  │   ├── photo1.jpg
  │   └── photo2.jpg
  └── EVENT_CODE2/
      ├── photo3.jpg
      └── photo4.jpg
```

## Free Tier Limits

✅ Very generous free tier:
- 25 credits/month (≈ 25GB storage)
- 25GB bandwidth/month
- 25,000 transformations
- No credit card required

## Image Optimizations

The app automatically uses these Cloudinary features:
- Automatic format (webp/avif)
- Automatic quality
- Responsive sizing
- Smart thumbnails

## Manual Upload (for MVP)

1. Go to Cloudinary Media Library
2. Create folder with event code (e.g., `rajasthani-photo-studios/WED2024`)
3. Upload photos
4. In Firestore, add photo records:
```javascript
events/{eventCode}/photos/{photoId}
{
  name: "photo1.jpg",
  publicId: "rajasthani-photo-studios/WED2024/photo1",
  uploadedAt: timestamp,
  sizeInBytes: 1234567
}
```

## Testing Setup

1. Create test folder in Cloudinary:
   `rajasthani-photo-studios/TEST2024`

2. Upload 2-3 test photos

3. Create Firestore document:
```javascript
events/TEST2024
{
  eventName: "Test Event",
  studioName: "Rajasthani Photo Studios",
  createdAt: now(),
  photoCount: 3,
  cloudinaryFolder: "rajasthani-photo-studios/TEST2024"
}
```

4. Add photo records in Firestore:
```javascript
events/TEST2024/photos/{photoId}
{
  name: "photo1.jpg",
  publicId: "rajasthani-photo-studios/TEST2024/photo1",
  uploadedAt: now(),
  sizeInBytes: 1234567
}
```

## Troubleshooting

### ❌ Images not loading
- Check Cloud Name is correct
- Verify photo publicId matches Cloudinary
- Check internet connection

### ❌ Wrong image sizes
- Clear app cache
- Check URL transformations
- Verify original upload

### ❌ Upload preset not working
- Check preset name
- Verify unsigned mode is enabled
- Check allowed formats

## Best Practices

1. **Naming**
   - Use meaningful filenames
   - Avoid spaces and special characters
   - Include event date (e.g., `wedding_2024_01_01.jpg`)

2. **Organization**
   - Create folder per event
   - Use consistent naming convention
   - Keep original files

3. **Optimization**
   - Upload high quality
   - Let Cloudinary handle optimization
   - Use provided transformation URLs

## Future Enhancements

- [ ] Direct upload from app
- [ ] Image moderation
- [ ] Face detection
- [ ] Auto-tagging
- [ ] Custom transformations

## Support

- [Cloudinary Docs](https://cloudinary.com/documentation)
- [Flutter SDK Guide](https://cloudinary.com/documentation/flutter_integration)
- [Transformation Reference](https://cloudinary.com/documentation/image_transformations)

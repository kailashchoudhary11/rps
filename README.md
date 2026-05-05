# Pic Studios

A Flutter app for event photo sharing — guests enter a short event code and browse the studio's photos for that event. The app talks only to a small FastAPI backend, which stores event metadata + the photo manifest in SQLite and mints presigned URLs for a private R2 bucket.

```
Flutter app  ──HTTP──▶  FastAPI backend  ──SQLAlchemy──▶  SQLite
                              │
                              └──S3 SDK──▶  Cloudflare R2 (private bucket, presigned URLs)
```

No Firebase. No public Cloudinary. R2 stays private — the backend is the only thing with credentials.

## Repo layout

```
.
├── lib/                 # Flutter app
│   ├── main.dart
│   ├── models/          # EventModel, PhotoItem (plain JSON)
│   ├── screens/         # CodeEntryScreen, GalleryScreen, PhotoViewerScreen
│   └── services/        # ApiService (HTTP), DownloadService (disk)
├── android/, ios/, ...  # Flutter platform folders
├── backend/             # FastAPI service — see backend/README.md
└── test/                # Flutter widget tests
```

## Features

- Code-based event access (HTTP lookup against the backend)
- Grid view with shimmer placeholders and cached thumbnails
- Filename search across the loaded manifest
- Full-screen viewer with pinch-to-zoom (`photo_view`)
- Single-tap download of the current photo to app storage
- Backend-driven event expiry (`expiresAt`)

## How a request flows

1. User enters an event code → app `POST`s to `GET /events/{code}`.
2. Backend looks up the row, returns metadata or 404/410.
3. App calls `GET /events/{code}/photos` → backend mints two presigned R2 URLs per photo (full + thumbnail) with a configurable TTL.
4. Grid loads thumbnails directly from R2 using the presigned URLs.
5. Tap → viewer loads the full presigned URL. Download → bytes are fetched via `http` and written to `getExternalStorageDirectory()/PicStudios/`.

## Setup

### 1. Backend

See [backend/README.md](backend/README.md). Short version:

```bash
pyenv install 3.13.5             # one time
cd backend
uv sync
cp .env.example .env             # fill in R2 creds
uv run uvicorn app.main:app --reload
uv run python -m scripts.seed    # inserts TEST2024 + 2 photo rows
```

Backend is reachable at <http://localhost:8000>; Swagger UI at `/docs`.

### 2. R2

- Create a bucket in Cloudflare R2.
- Generate an API token scoped to that bucket (read+write).
- Keep the bucket **private** — no public r2.dev access.
- Drop `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` into `backend/.env`.
- Object key layout:
  - `events/{code}/{name}` — full image
  - `events/{code}/thumbs/{name}` — 300px thumbnail

Each photo also needs a row in the SQLite `photos` table (the seed script does this for `TEST2024`).

### 3. Flutter app

```bash
flutter pub get
flutter run
```

The Android emulator reaches the host machine via `10.0.2.2`, so `ApiService.baseUrl` is set to `http://10.0.2.2:8000`. For a physical device on the same WiFi, change it to your Mac's LAN IP. For production, the deployed backend URL.

## Platform support

- Android — primary target
- iOS — works in principle; not configured by default
- Web / desktop — not supported (download flow uses mobile-only `path_provider` + `permission_handler`)

### Android permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

## Testing

```bash
flutter test         # widget smoke test
flutter analyze      # lint
```

Backend tests aren't set up yet (see `backend/README.md` for what's deferred).

## Troubleshooting

- **`Connection refused` on the app** — backend isn't running, or `ApiService.baseUrl` is wrong for your device. Emulator uses `10.0.2.2`, not `localhost`.
- **`/events/TEST2024/photos` returns 500** — `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` are blank in `backend/.env`. Fill them in.
- **Gallery shows broken-image icons** — the photo rows exist in SQLite but the matching R2 objects don't (or the keys don't match). Paste a presigned URL into a browser to see the real R2 error.
- **Download permission denied on Android 13+** — grant "Files and media" in the app's system settings.

## License

Private project — all rights reserved.

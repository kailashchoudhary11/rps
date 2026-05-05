# Pic Studios

A Flutter app for event photo sharing — guests enter a short event code and browse the studio's photos for that event. The app talks only to a small FastAPI backend, which stores event metadata in SQLite and mints presigned URLs for a private R2 bucket. The photo manifest itself is **not** stored in the DB; the backend lists R2 at request time.

```
Flutter app  ──HTTP──▶  FastAPI  ──SQLAlchemy──▶  SQLite (event metadata only)
                          │
                          └──S3 SDK──▶  Cloudflare R2 (private bucket; LIST + presigned URLs)
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

1. User enters an event code → app calls `GET /events/{code}`.
2. Backend looks up the SQLite row, returns metadata or 404/410.
3. App calls `GET /events/{code}/photos` → backend confirms the event still exists, then runs `ListObjectsV2` against `events/{code}/thumbs/` in R2 to enumerate photos. For each thumbnail key it mints two presigned URLs (full + thumb) and returns them sorted newest-first by R2's `LastModified`.
4. Grid loads thumbnails directly from R2 using the presigned URLs.
5. Tap → viewer loads the full presigned URL. Download → bytes are fetched via `http` and written to `getExternalStorageDirectory()/PicStudios/`.

The photo manifest is never written to the DB. To add or remove photos, just upload/delete in R2 — the next gallery open picks them up.

## Setup

### 1. Backend

See [backend/README.md](backend/README.md). Short version:

```bash
pyenv install 3.13.5             # one time
cd backend
uv sync
cp .env.example .env             # fill in R2 creds
uv run uvicorn app.main:app --reload
uv run python -m scripts.seed    # inserts the TEST2024 event row
```

Backend is reachable at <http://localhost:8000>; Swagger UI at `/docs`.

### 2. R2

- Create a bucket in Cloudflare R2.
- Generate an API token scoped to that bucket (read+write).
- Keep the bucket **private** — no public r2.dev access.
- Drop `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` into `backend/.env`.
- Object key layout:
  - `events/{code}/{name}` — full image
  - `events/{code}/thumbs/{name}` — thumbnail (~500px square recommended)

Photos are discovered via `ListObjectsV2` at request time — no DB write needed per photo. Just upload both objects with matching filenames and the next gallery open picks them up.

### 3. Flutter app

```bash
flutter pub get
flutter run
```

`ApiService.baseUrl` defaults to `http://10.0.2.2:8000` (Android emulator → host gateway). Override at run time with `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://<vm-ip>:8369
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
```

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
- **`/events/TEST2024/photos` returns 500** — `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` are blank or wrong in `backend/.env`, or the `R2_BUCKET` name doesn't match.
- **`/events/TEST2024/photos` returns `{"photos":[]}` even though you uploaded** — the objects aren't under the expected prefix. The backend lists `events/TEST2024/thumbs/`; check that exact key prefix exists in R2 (case-sensitive).
- **Gallery shows the right count but broken-image icons in the viewer** — thumbnails are in `events/{code}/thumbs/` but the matching full-size objects aren't in `events/{code}/`. Upload tooling must always produce both.
- **Download permission denied on Android 13+** — grant "Files and media" in the app's system settings.

## License

Private project — all rights reserved.

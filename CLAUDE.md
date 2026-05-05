# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Flutter (repo root)

```bash
flutter pub get                       # install deps
flutter run                           # run on connected device / emulator
flutter analyze                       # lint (uses package:flutter_lints/flutter.yaml)
flutter test                          # run all tests
flutter test test/widget_test.dart    # run a single test file
flutter test --plain-name "App loads code entry screen"
flutter build apk
```

The Flutter SDK constraint is `^3.9.2` (`pubspec.yaml`).

### Backend (`backend/` — FastAPI + SQLite)

```bash
cd backend
uv sync                               # create .venv, install deps (Python 3.13.5 via pyenv)
cp .env.example .env                  # then fill in R2 creds
uv run uvicorn app.main:app --reload  # http://localhost:8000, /docs for Swagger
uv run python -m scripts.seed         # idempotent TEST2024 event row
uv run ruff check .                   # lint
```

The SQLite file lives at `backend/pic_studios.db` and is `*.db`-ignored — back it up if you care.

## Architecture

Three-tier: Flutter app → FastAPI backend → SQLite (metadata) + Cloudflare R2 (bytes). The previous incarnations (Firestore + Cloudinary, then Firestore + public R2) are gone.

```
Flutter app  ──HTTP──▶  FastAPI  ──SQLAlchemy──▶  SQLite
                          │
                          └──S3 SDK──▶  R2 (private bucket, presigned URLs)
```

### What lives where

- **SQLite** (`backend/pic_studios.db`): the `events` table only — `code` (PK), `event_name`, `studio_name`, `created_at`, `expires_at`. There is **no `photos` table**. The DB exists purely to hold event-level metadata that the UI displays (event name, studio name, expiry).
- **R2** (private bucket): two objects per photo, keyed `events/{code}/{name}` (full) and `events/{code}/thumbs/{name}` (thumbnail). R2 is the **source of truth for the photo manifest** — the backend lists the `thumbs/` prefix to enumerate photos at request time. The bucket has no public access; every byte goes out via a backend-minted presigned URL.
- **Backend** holds all R2 credentials. The Flutter app never talks to R2 directly.

### Endpoint contract

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `/health` | `{"status":"ok"}` |
| `GET` | `/events/{code}` | 200 with metadata (camelCase JSON), 404 missing, 410 expired |
| `GET` | `/events/{code}/photos` | 200 with `{"photos":[{name,uploadedAt,url,thumbnailUrl},...]}`. 404 only if the event row is missing (DB existence check happens before R2 LIST); a real event with no uploaded photos returns `{"photos":[]}` and 200. |
| `GET` | `/privacy` | Static HTML privacy policy served from `backend/app/static/privacy.html`. Used as the Play Store privacy-policy URL once the backend is on HTTPS. Hidden from `/docs`. |

The backend uppercases the code on input (`_normalize_code` in `app/routers/events.py`). This is the **single normalization point** — the Flutter app sends whatever the user typed, the backend canonicalizes. Treat the canonical form (uppercase) as authoritative for everything downstream: DB primary keys, R2 object keys (`events/{CODE}/...`), Hero tags, etc.

When the (deferred) admin endpoints are added, they must call `_normalize_code` on the way in too, otherwise mixed-case rows would slip in and `db.get(Event, "WED2024")` would miss a row stored as `wed2024`. SQLite's default collation is binary/case-sensitive.

### Things that bite when you don't expect them

1. **Presigned URL TTL** is 1 hour (configurable via `PRESIGNED_URL_TTL`). The grid loads URLs once on screen open; if the user idles for > TTL and then taps a photo, the full-size load may 403. Currently no refresh — re-enter the gallery to get fresh URLs.
2. **R2 LIST is the manifest.** `list_event_photos` in `app/r2.py` lists `events/{code}/thumbs/` and treats the resulting key set as the canonical photo list. A photo without a thumbnail will not appear; a thumbnail without a corresponding full image will appear in the grid but 404 in the viewer. Upload tooling must always produce both.
3. **LIST sort order is `LastModified` desc** (newest first), not alphabetical. boto3's `LastModified` is timezone-aware UTC. If you ever need stable alphabetical ordering, sort on `name` instead — but watch out for `photo10.jpg` < `photo2.jpg` lexicographically.
4. **1000-key page limit**: `ListObjectsV2` returns at most 1000 objects per page. The helper paginates transparently, but for events approaching that size be aware of the latency cost (each page is a round-trip).
5. **R2 list ops are Class A** ($4.50 per million; 1M free per month). One LIST per gallery open. Effectively free for this app's scale.
6. **Object key case sensitivity**: R2 keys are case-sensitive. Filenames returned by LIST flow back to the client as-is — if you upload `Photo1.JPG`, that's exactly what the URL will reference and what the client will display.
7. **No video support**. The earlier Cloudinary-era code had a Photos/Videos toggle; that was removed in the R2 migration. Adding videos back means new endpoints, new keys (`events/{code}/videos/...`), and a video player widget. Don't half-add it.
8. **Schema is created via `Base.metadata.create_all`** on app startup — no Alembic. Fine while the schema is stable; once it starts changing, add Alembic before changing it the second time.
9. **The Flutter test (`test/widget_test.dart`) does not hit the backend.** It just checks the home screen renders. There is no integration test that exercises the API contract.

### Networking quirks

`ApiService.baseUrl` is a `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000')`. Override at run/build time with `--dart-define`:

```bash
flutter run   --dart-define=API_BASE_URL=http://<vm-ip>:8369
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
```

The default targets the Android emulator's host gateway (`10.0.2.2`). Other contexts:

- Physical Android phone on same WiFi → Mac's LAN IP (e.g. `http://192.168.1.42:8000`)
- iOS simulator → `http://localhost:8000` (different from Android emulator)
- VM with the deployed backend → `http://<vm-ip>:8369` (host port is hardcoded to 8369 in `backend/compose.yaml`)

### Downloads

`DownloadService.downloadImage` writes to `getExternalStorageDirectory()/PicStudios/`. The folder name is hardcoded — change it in `lib/services/download_service.dart` if rebranding. The download URL is the same presigned `url` field returned by the backend; no separate download URL is minted.

## Naming — load-bearing identifiers

The app is "Pic Studios" everywhere user-visible. A few identifiers from the original scaffold remain and should not be changed casually:

- Android `applicationId` / namespace: `com.example.rps` (`android/app/build.gradle.kts`). Changing this breaks installed users.
- Pubspec package name: `rps` (`pubspec.yaml`). Used in test imports (`package:rps/main.dart`).

## What's deferred (not built yet)

- **Admin endpoints**: `POST /events` and presigned PUT URLs for direct upload. Until these exist, create event rows via `scripts/seed.py` or with `sqlite3` directly. Photos themselves don't need a DB write — uploading them to R2 with the right key is enough.
- **Upload tooling**: a script that takes a folder, resizes to ~500px thumbs, uploads originals + thumbs to R2 with matching filenames. No DB write needed.
- **Alembic migrations**.
- **Backend tests** (no `pytest` config yet).
- **Production hardening**: structured logging, rate limiting, locked-down CORS, Sentry, deploy config.

## Reference docs in this repo

- `README.md` — feature overview, full setup
- `QUICKSTART.md` — 10-minute end-to-end setup
- `backend/README.md` — backend-specific install/run/seed/R2 layout

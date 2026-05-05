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
uv run python -m scripts.seed         # idempotent TEST2024 + 2 photo rows
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

- **SQLite** (`backend/pic_studios.db`): the `events` table (`code`, `event_name`, `studio_name`, `created_at`, `expires_at`) and the `photos` table (`id`, `event_code` FK, `name`, `uploaded_at`). `photoCount` is **derived** from a `COUNT(*)` query, not stored.
- **R2** (private bucket): two objects per photo, keyed `events/{code}/{name}` and `events/{code}/thumbs/{name}`. The bucket has no public access — every byte goes out via a backend-minted presigned URL.
- **Backend** holds all R2 credentials. The Flutter app never talks to R2 directly.

### Endpoint contract

| Method | Path | Notes |
|--------|------|-------|
| `GET` | `/health` | `{"status":"ok"}` |
| `GET` | `/events/{code}` | 200 with metadata (camelCase JSON), 404 missing, 410 expired |
| `GET` | `/events/{code}/photos` | 200 with `{"photos":[{name,uploadedAt,url,thumbnailUrl},...]}`, 404 if event missing |

The backend uppercases the code on input (`_normalize_code` in `app/routers/events.py`). This is the **single normalization point** — the Flutter app sends whatever the user typed, the backend canonicalizes. Treat the canonical form (uppercase) as authoritative for everything downstream: DB primary keys, R2 object keys (`events/{CODE}/...`), Hero tags, etc.

When the (deferred) admin endpoints are added, they must call `_normalize_code` on the way in too, otherwise mixed-case rows would slip in and `db.get(Event, "WED2024")` would miss a row stored as `wed2024`. SQLite's default collation is binary/case-sensitive.

### Things that bite when you don't expect them

1. **Presigned URL TTL** is 1 hour (configurable via `PRESIGNED_URL_TTL`). The grid loads URLs once on screen open; if the user idles for > TTL and then taps a photo, the full-size load may 403. Currently no refresh — re-enter the gallery to get fresh URLs.
2. **Object key case sensitivity**: R2 keys are case-sensitive. The `name` in the SQLite `photos` row must match the R2 object key suffix exactly, or you'll get 404s in the browser when debugging.
3. **No video support**. The earlier Cloudinary-era code had a Photos/Videos toggle; that was removed in the R2 migration. Adding videos back means new endpoints, new keys (`events/{code}/videos/...`), and a video player widget. Don't half-add it.
4. **Schema is created via `Base.metadata.create_all`** on app startup — no Alembic. Fine while the schema is stable; once it starts changing, add Alembic before changing it the second time.
5. **The Flutter test (`test/widget_test.dart`) does not hit the backend.** It just checks the home screen renders. There is no integration test that exercises the API contract.

### Networking quirks

- Android emulator → host machine: `http://10.0.2.2:8000`. The default in `lib/services/api_service.dart`.
- Physical Android phone → host: the Mac's LAN IP, e.g. `http://192.168.1.42:8000`. Edit the constant; there's no env-driven config.
- iOS simulator → host: `http://localhost:8000` (different from Android emulator).

### Downloads

`DownloadService.downloadImage` writes to `getExternalStorageDirectory()/PicStudios/`. The folder name is hardcoded — change it in `lib/services/download_service.dart` if rebranding. The download URL is the same presigned `url` field returned by the backend; no separate download URL is minted.

## Naming — load-bearing identifiers

The app is "Pic Studios" everywhere user-visible. A few identifiers from the original scaffold remain and should not be changed casually:

- Android `applicationId` / namespace: `com.example.rps` (`android/app/build.gradle.kts`). Changing this breaks installed users.
- Pubspec package name: `rps` (`pubspec.yaml`). Used in test imports (`package:rps/main.dart`).

## What's deferred (not built yet)

- **Admin endpoints**: `POST /events`, `POST /events/{code}/photos`, presigned PUT URLs for direct upload. Until these exist, populate via `scripts/seed.py` or by inserting rows manually with `sqlite3`.
- **Upload tooling**: a script that takes a folder, resizes to 300px thumbs, uploads originals + thumbs to R2, and registers rows via the (deferred) admin API.
- **Alembic migrations**.
- **Backend tests** (no `pytest` config yet).
- **Production hardening**: structured logging, rate limiting, locked-down CORS, Sentry, deploy config.

## Reference docs in this repo

- `README.md` — feature overview, full setup
- `QUICKSTART.md` — 10-minute end-to-end setup
- `backend/README.md` — backend-specific install/run/seed/R2 layout

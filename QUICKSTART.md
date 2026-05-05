# Quick Start — Pic Studios

End-to-end in about 10 minutes. For more detail see [README.md](README.md) and [backend/README.md](backend/README.md).

## Prerequisites

- Flutter SDK (run `flutter doctor`)
- Android Studio (for the emulator) — iOS is optional
- [pyenv](https://github.com/pyenv/pyenv) and [uv](https://docs.astral.sh/uv/) for the backend
- A Cloudflare account (for R2)

## 1. Run the backend

```bash
pyenv install 3.13.5         # one-time
cd backend
uv sync                      # creates .venv, installs deps
cp .env.example .env         # leave R2 vars empty for now if you only want /health
uv run uvicorn app.main:app --reload
```

Visit <http://localhost:8000/health> → `{"status":"ok"}` and <http://localhost:8000/docs> for the API.

## 2. Seed test data

In another terminal:

```bash
cd backend
uv run python -m scripts.seed
```

Inserts the `TEST2024` event row. (Photos themselves are discovered by listing R2 — no per-photo DB writes.)

`GET /events/TEST2024` should now return:

```json
{
  "code": "TEST2024",
  "eventName": "Test Event",
  "studioName": "Pic Studios",
  "createdAt": "...",
  "expiresAt": null
}
```

## 3. Set up R2 (for the photo endpoint to actually serve bytes)

1. In Cloudflare, create an R2 bucket. Keep it **private** — do not enable r2.dev public access.
2. Generate an R2 API token with read+write on that bucket.
3. Fill in `backend/.env`:
   ```
   R2_ACCOUNT_ID=<your account id>
   R2_ACCESS_KEY_ID=<token access key>
   R2_SECRET_ACCESS_KEY=<token secret>
   R2_BUCKET=<bucket name>
   ```
4. Upload sample objects (manually for now — admin/upload endpoints are deferred). Object keys are case-sensitive; filenames should be lowercase and URL-safe:
   ```
   events/TEST2024/photo1.jpg              # full image
   events/TEST2024/thumbs/photo1.jpg       # ~500px square thumbnail
   events/TEST2024/photo2.jpg
   events/TEST2024/thumbs/photo2.jpg
   ```
5. Hit `GET /events/TEST2024/photos`. The backend runs `ListObjectsV2` over `events/TEST2024/thumbs/` and returns one entry per thumbnail with presigned `url` (full) and `thumbnailUrl`. No backend restart needed — uploads show up on the next request.

## 4. Run the Flutter app

```bash
cd ..                        # back to repo root
flutter pub get
flutter run
```

Pick the Android emulator from the device list. The app's `ApiService.baseUrl` defaults to `http://10.0.2.2:8000` (how the emulator reaches the host machine). For any other target, override with `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://<vm-ip>:8369
```

In the app:

1. Type `TEST2024` and tap **Access Photos**.
2. Gallery shows two thumbnails (or broken-image icons if the R2 objects aren't there yet).
3. Tap → full-screen viewer with the original image.
4. Tap the download icon → file lands in `Android/data/com.example.rps/files/PicStudios/`.

## Common issues

- **App says "Connection refused"** — backend isn't running, or you're on a physical device. Emulator → `http://10.0.2.2:8000`. Physical device on same WiFi → your Mac's LAN IP, e.g. `http://192.168.1.42:8000`. Edit `lib/services/api_service.dart` and hot-restart (capital `R`).
- **`/events/TEST2024/photos` returns 500** — R2 creds are blank/wrong in `backend/.env`, or the `R2_BUCKET` name is wrong.
- **`/photos` returns `{"photos":[]}` after uploading** — your objects aren't under `events/TEST2024/thumbs/`. Verify the exact prefix in R2 (case-sensitive).
- **Thumbs render but full-screen 404s** — full-size objects are missing from `events/{code}/`. Always upload both full and thumb with matching filenames.
- **Build fails** — `flutter clean && flutter pub get && flutter run`.
- **Permission denied on Android 13+ during download** — grant "Files and media" in the app's system settings.

## Useful tweaks

- **API base URL** — `lib/services/api_service.dart` (`baseUrl` constant).
- **Theme colors** — `lib/main.dart` → `ThemeData.colorScheme`.
- **Presigned URL TTL** — `PRESIGNED_URL_TTL` in `backend/.env` (seconds).
- **Download folder** — `lib/services/download_service.dart` (currently `PicStudios/`).

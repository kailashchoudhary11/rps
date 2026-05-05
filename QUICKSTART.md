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

Inserts `events/TEST2024` with two photo rows (`photo1.jpg`, `photo2.jpg`).

`GET /events/TEST2024` should now return:

```json
{
  "code": "TEST2024",
  "eventName": "Test Event",
  "studioName": "Pic Studios",
  "createdAt": "...",
  "expiresAt": null,
  "photoCount": 2
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
4. Upload sample objects (manually for now — admin/upload endpoints are deferred):
   ```
   events/TEST2024/photo1.jpg              # full image
   events/TEST2024/thumbs/photo1.jpg       # 300px thumbnail
   events/TEST2024/photo2.jpg
   events/TEST2024/thumbs/photo2.jpg
   ```
5. Restart `uvicorn` and hit `GET /events/TEST2024/photos`. You should see two photos with presigned `url` and `thumbnailUrl`.

## 4. Run the Flutter app

```bash
cd ..                        # back to repo root
flutter pub get
flutter run
```

Pick the Android emulator from the device list. The app's `ApiService.baseUrl` is `http://10.0.2.2:8000`, which is how the emulator reaches the host machine.

In the app:

1. Type `TEST2024` and tap **Access Photos**.
2. Gallery shows two thumbnails (or broken-image icons if the R2 objects aren't there yet).
3. Tap → full-screen viewer with the original image.
4. Tap the download icon → file lands in `Android/data/com.example.rps/files/PicStudios/`.

## Common issues

- **App says "Connection refused"** — backend isn't running, or you're on a physical device. Emulator → `http://10.0.2.2:8000`. Physical device on same WiFi → your Mac's LAN IP, e.g. `http://192.168.1.42:8000`. Edit `lib/services/api_service.dart` and hot-restart (capital `R`).
- **`/events/TEST2024/photos` returns 500** — R2 creds are blank in `backend/.env`.
- **Photos load in `/photos` JSON but show broken icons in the app** — paste the presigned URL into a browser. If it 403s or 404s, R2 keys/bucket name are wrong, or the object doesn't exist at that key. Object keys are case-sensitive and must match the `name` in the SQLite `photos` row exactly.
- **Build fails** — `flutter clean && flutter pub get && flutter run`.
- **Permission denied on Android 13+ during download** — grant "Files and media" in the app's system settings.

## Useful tweaks

- **API base URL** — `lib/services/api_service.dart` (`baseUrl` constant).
- **Theme colors** — `lib/main.dart` → `ThemeData.colorScheme`.
- **Presigned URL TTL** — `PRESIGNED_URL_TTL` in `backend/.env` (seconds).
- **Download folder** — `lib/services/download_service.dart` (currently `PicStudios/`).

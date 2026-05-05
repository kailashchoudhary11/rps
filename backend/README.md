# Pic Studios — Backend

FastAPI service that:

- Stores event metadata + photo manifest in SQLite
- Mints presigned R2 URLs for full images and thumbnails on demand

The Flutter app talks only to this service — R2 stays private, no Firestore, no public r2.dev URLs.

## Requirements

- Python 3.13.5 (via [pyenv](https://github.com/pyenv/pyenv))
- [uv](https://docs.astral.sh/uv/) for dependency management

## Setup

```bash
pyenv install 3.13.5          # one-time, if not already installed
cd backend
# .python-version already pins 3.13.5; pyenv will pick it up automatically
uv sync                        # creates .venv and installs deps
cp .env.example .env           # then edit .env with R2 credentials
```

## Run

```bash
uv run uvicorn app.main:app --reload
```

- API docs: <http://localhost:8000/docs>
- Health: <http://localhost:8000/health>

The Android emulator reaches the host machine via `10.0.2.2`, so the Flutter app should use `http://10.0.2.2:8000` as its API base URL.

## Routes

| Method | Path                      | Notes                                                |
|--------|---------------------------|------------------------------------------------------|
| GET    | `/health`                 | Liveness check                                       |
| GET    | `/events/{code}`          | Event metadata (404 if missing, 410 if expired)      |
| GET    | `/events/{code}/photos`   | Photo manifest with presigned `url` + `thumbnailUrl` |

The event code is normalized to uppercase server-side, mirroring the app.

Admin endpoints (event creation, photo registration, presigned upload URLs) are deferred. For now, populate the DB with the seed script.

## Seed test data

```bash
uv run python -m scripts.seed
```

Inserts `events/TEST2024` with two photo rows (`photo1.jpg`, `photo2.jpg`). The matching R2 objects must exist for the presigned URLs to actually return bytes:

```
events/TEST2024/photo1.jpg          # full image
events/TEST2024/thumbs/photo1.jpg   # 300px thumbnail
events/TEST2024/photo2.jpg
events/TEST2024/thumbs/photo2.jpg
```

## R2 layout

For each photo, two objects with these exact keys:

```
events/{code}/{name}              # full-resolution original
events/{code}/thumbs/{name}       # 300px thumbnail
```

The backend mints presigned `GET` URLs for both — the bucket should be **private** (no r2.dev public access).

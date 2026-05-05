# Pic Studios — Backend

FastAPI service that:

- Stores **event metadata** in SQLite (the photo manifest is **not** in the DB)
- Lists R2 to enumerate photos at request time and mints presigned URLs for full images + thumbnails

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
| GET    | `/events/{code}/photos`   | LIST `events/{code}/thumbs/` in R2 → presigned `url` + `thumbnailUrl` per object, sorted by `LastModified` desc. 404 only if the event row is missing; an event with no uploaded photos returns `{"photos":[]}` and 200. |

The event code is normalized to uppercase server-side. Admin endpoints (event creation, presigned upload URLs) are deferred. For now, create event rows with the seed script.

## Seed test data

```bash
uv run python -m scripts.seed
```

Inserts the `TEST2024` event row. Photos are discovered by listing R2 — there are no per-photo DB writes. To populate the gallery, upload to your R2 bucket under:

```
events/TEST2024/photo1.jpg          # full image
events/TEST2024/thumbs/photo1.jpg   # ~500px square thumbnail
```

…and the next call to `/events/TEST2024/photos` picks them up.

## R2 layout

For each photo, two objects with matching filenames:

```
events/{code}/{name}              # full-resolution original
events/{code}/thumbs/{name}       # thumbnail
```

The bucket should be **private** (no r2.dev public access). The backend mints presigned `GET` URLs for both. The thumbnail key set is the source of truth for the manifest — `list_event_photos` in `app/r2.py` does the enumeration via paginated `ListObjectsV2`.

### Cost note

`ListObjectsV2` is a Class A op in R2 ($4.50 per million; **1M free per month**). One LIST per gallery open. At any reasonable scale this is effectively free.

### Sort order

Photos are returned sorted by `LastModified` descending (newest first). If you need stable ordering across re-uploads, control the timestamp explicitly when uploading (S3 SDKs accept it as a parameter).

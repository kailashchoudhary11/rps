from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Event
from app.r2 import list_event_photos, presigned_get_url
from app.schemas import EventOut, PhotoOut, PhotosOut

router = APIRouter(prefix="/events", tags=["events"])


def _normalize_code(code: str) -> str:
    return code.strip().upper()


@router.get("/{code}", response_model=EventOut, response_model_by_alias=True)
def get_event(code: str, db: Session = Depends(get_db)) -> EventOut:
    code = _normalize_code(code)
    event = db.get(Event, code)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Event not found")
    if event.expires_at and event.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_410_GONE, detail="Event has expired")

    return EventOut.model_validate(event)


@router.get("/{code}/photos", response_model=PhotosOut, response_model_by_alias=True)
def list_photos(code: str, db: Session = Depends(get_db)) -> PhotosOut:
    code = _normalize_code(code)
    if db.get(Event, code) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Event not found")

    items = list_event_photos(code)
    items.sort(key=lambda x: x[1], reverse=True)  # newest first

    return PhotosOut(
        photos=[
            PhotoOut(
                name=name,
                uploaded_at=last_modified,
                url=presigned_get_url(f"events/{code}/{name}"),
                thumbnail_url=presigned_get_url(f"events/{code}/thumbs/{name}"),
            )
            for name, last_modified in items
        ]
    )

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Event, Photo
from app.r2 import presigned_get_url
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

    photo_count = (
        db.scalar(select(func.count()).select_from(Photo).where(Photo.event_code == code))
        or 0
    )

    return EventOut(
        code=event.code,
        event_name=event.event_name,
        studio_name=event.studio_name,
        created_at=event.created_at,
        expires_at=event.expires_at,
        photo_count=photo_count,
    )


@router.get("/{code}/photos", response_model=PhotosOut, response_model_by_alias=True)
def list_photos(code: str, db: Session = Depends(get_db)) -> PhotosOut:
    code = _normalize_code(code)
    event = db.get(Event, code)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Event not found")

    photos = db.scalars(
        select(Photo).where(Photo.event_code == code).order_by(Photo.uploaded_at.desc())
    ).all()

    return PhotosOut(
        photos=[
            PhotoOut(
                name=p.name,
                uploaded_at=p.uploaded_at,
                url=presigned_get_url(f"events/{code}/{p.name}"),
                thumbnail_url=presigned_get_url(f"events/{code}/thumbs/{p.name}"),
            )
            for p in photos
        ]
    )

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class Event(Base):
    __tablename__ = "events"

    code: Mapped[str] = mapped_column(String, primary_key=True)
    event_name: Mapped[str] = mapped_column(String)
    studio_name: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    photos: Mapped[list["Photo"]] = relationship(
        back_populates="event", cascade="all, delete-orphan"
    )


class Photo(Base):
    __tablename__ = "photos"

    id: Mapped[int] = mapped_column(primary_key=True)
    event_code: Mapped[str] = mapped_column(ForeignKey("events.code"), index=True)
    name: Mapped[str] = mapped_column(String)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime)

    event: Mapped[Event] = relationship(back_populates="photos")

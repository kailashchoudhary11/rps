"""Insert TEST2024 with two photo rows so the gallery flow can be exercised."""

from datetime import datetime, timezone

from app.db import Base, SessionLocal, engine
from app.models import Event, Photo


def main() -> None:
    Base.metadata.create_all(bind=engine)
    now = datetime.now(timezone.utc)

    with SessionLocal() as db:
        if db.get(Event, "TEST2024") is None:
            db.add(
                Event(
                    code="TEST2024",
                    event_name="Test Event",
                    studio_name="Pic Studios",
                    created_at=now,
                    expires_at=None,
                )
            )

        existing = {
            p.name for p in db.query(Photo).filter_by(event_code="TEST2024").all()
        }
        for name in ("photo1.jpg", "photo2.jpg"):
            if name not in existing:
                db.add(Photo(event_code="TEST2024", name=name, uploaded_at=now))

        db.commit()

    print("Seeded TEST2024 with photo1.jpg, photo2.jpg")


if __name__ == "__main__":
    main()

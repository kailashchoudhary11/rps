"""Insert TEST2024 event so the gallery flow can be exercised end-to-end.

The photo manifest now comes from R2 LIST, not the database. Upload sample
photos under events/TEST2024/ and events/TEST2024/thumbs/ in your R2 bucket
to see them in the gallery.
"""

from datetime import datetime, timezone

from app.db import Base, SessionLocal, engine
from app.models import Event


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
            db.commit()
            print("Seeded TEST2024.")
        else:
            print("TEST2024 already exists; nothing to do.")


if __name__ == "__main__":
    main()

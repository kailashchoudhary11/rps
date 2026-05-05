from datetime import datetime

from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True,
    )


class EventOut(CamelModel):
    code: str
    event_name: str
    studio_name: str
    created_at: datetime
    expires_at: datetime | None


class PhotoOut(CamelModel):
    name: str
    uploaded_at: datetime
    url: str
    thumbnail_url: str


class PhotosOut(CamelModel):
    photos: list[PhotoOut]

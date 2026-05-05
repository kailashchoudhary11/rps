from datetime import datetime

import boto3
from botocore.config import Config

from app.config import settings


def _client():
    if not (settings.r2_access_key_id and settings.r2_secret_access_key):
        raise RuntimeError(
            "R2 credentials not configured. Set R2_ACCESS_KEY_ID and "
            "R2_SECRET_ACCESS_KEY in backend/.env."
        )
    return boto3.client(
        "s3",
        endpoint_url=settings.r2_endpoint,
        aws_access_key_id=settings.r2_access_key_id,
        aws_secret_access_key=settings.r2_secret_access_key,
        region_name="auto",
        config=Config(signature_version="s3v4"),
    )


def presigned_get_url(key: str) -> str:
    return _client().generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.r2_bucket, "Key": key},
        ExpiresIn=settings.presigned_url_ttl,
    )


def list_event_photos(code: str) -> list[tuple[str, datetime]]:
    """Return (name, last_modified) for each thumbnail under events/{code}/thumbs/.

    The thumbnail key set is the source of truth for the manifest — every visible
    photo must have a thumbnail. Pagination is handled transparently.
    """
    prefix = f"events/{code}/thumbs/"
    paginator = _client().get_paginator("list_objects_v2")
    items: list[tuple[str, datetime]] = []
    for page in paginator.paginate(Bucket=settings.r2_bucket, Prefix=prefix):
        print("The page is", page)
        for obj in page.get("Contents", []):
            name = obj["Key"][len(prefix) :]
            if not name:
                # The prefix itself can show up as an empty-name entry — skip it.
                continue
            items.append((name, obj["LastModified"]))
    return items

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

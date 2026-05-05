from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse

router = APIRouter(tags=["legal"])

_PRIVACY_PATH = Path(__file__).resolve().parent.parent / "static" / "privacy.html"


@router.get("/privacy", response_class=FileResponse, include_in_schema=False)
def privacy() -> FileResponse:
    return FileResponse(_PRIVACY_PATH, media_type="text/html; charset=utf-8")

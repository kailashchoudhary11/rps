# syntax=docker/dockerfile:1.7

# ---------- builder ----------
FROM python:3.13.5-slim-bookworm AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN pip install uv

WORKDIR /app

# Install runtime deps in a cacheable layer — invalidated only when the
# lockfile or pyproject changes, not when source code changes.
COPY pyproject.toml uv.lock /app/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Now copy the application source.
COPY app /app/app
COPY scripts /app/scripts

# ---------- runtime ----------
FROM python:3.13.5-slim-bookworm

ENV PATH="/app/.venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Bring over the prebuilt venv + app source from the builder stage.
COPY --from=builder /app /app

# SQLite database lives outside the image so it survives container replacement.
# Set DATABASE_URL=sqlite:////data/pic_studios.db when running.
RUN mkdir -p /data
VOLUME ["/data"]

EXPOSE 8000

# Liveness probe; orchestrators usually bring their own, but this works for
# `docker run` too.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3).status == 200 else sys.exit(1)" \
    || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

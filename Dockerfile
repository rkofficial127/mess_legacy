# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS flutter-build

WORKDIR /app/frontend
COPY frontend/ .

RUN flutter pub get
RUN flutter build web --release

# Stage 2: Python backend
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY backend/ .

# Copy Flutter web build into backend static dir
COPY --from=flutter-build /app/frontend/build/web ./static

EXPOSE 8000

COPY start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]

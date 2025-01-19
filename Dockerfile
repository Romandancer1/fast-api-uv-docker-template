FROM python:3.12.2-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    musl-dev \
    bash \
    zlib1g-dev \
    libjpeg-dev \
    libcairo2-dev \
    libpango1.0-dev \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/

COPY requirements/lock/requirements.txt ./requirements/lock/requirements.txt

RUN pip install uv && uv pip sync ./requirements/lock/requirements.txt --system

COPY . .
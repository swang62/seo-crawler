# syntax=docker/dockerfile:1

# Use Python 3.11 slim image as base
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Set working directory
WORKDIR /app

# Install system dependencies required for Playwright and Chrome
RUN mount=type=cache,target=/var/lib/apt \
  apt-get update && apt-get install -y \
  wget \
  gnupg \
  curl \
  ca-certificates

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r requirements.txt

RUN mount=type=cache,target=/var/lib/apt \
  playwright install-deps

# Create a non-root user to run the application
RUN groupadd -r librecrawl && useradd -r -g librecrawl -u 1000 librecrawl \
  && mkdir -p /home/librecrawl && chown -R librecrawl:librecrawl /home/librecrawl

# Need to setup directories
RUN mkdir -p /home/librecrawl && chown -R librecrawl:librecrawl /home/librecrawl
RUN mkdir -p /app/data && chown -R librecrawl:librecrawl /app

# Switch to non-root user
USER librecrawl

RUN mount=type=cache,target=/home/librecrawl/.cache \
  playwright install chromium

# Copy application code
COPY --chown=librecrawl:librecrawl . .

# Expose Flask port
EXPOSE 5000
ENV FLASK_APP=main.py

# Run the application
CMD ["python", "main.py"]

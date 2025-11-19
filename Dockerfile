# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for Playwright and Chrome
RUN apt-get update && apt-get install -y \
  wget \
  gnupg \
  ca-certificates \
  fonts-liberation \
  xdg-utils \
  && rm -rf /var/lib/apt/lists/*

# Install Playwright browsers (Chromium)
RUN playwright install chromium
RUN playwright install-deps chromium

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user to run the application
RUN groupadd -r librecrawl && useradd -r -g librecrawl -u 1000 librecrawl

# Copy application code
COPY --chown=librecrawl:librecrawl . .

# Create directory for user database if it doesn't exist
RUN mkdir -p /app/data && chown -R librecrawl:librecrawl /app/data

# Change ownership of the entire app directory
RUN chown -R librecrawl:librecrawl /app

# Switch to non-root user
USER librecrawl

# Expose Flask port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=main.py
ENV PYTHONUNBUFFERED=1
ENV LOCAL_MODE=false

CMD ["python", "main.py"]

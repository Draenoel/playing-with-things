# MLflow Tracking Server Dockerfile
# Base image: Python 3.11 slim for smaller image size
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
# - postgresql-client: for psql commands (optional, for debugging)
# - curl: for health checks
# - gcc, libpq-dev: required for building psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create directory for MLflow artifacts (if using local storage)
RUN mkdir -p /app/mlruns

# Copy initialization scripts
COPY scripts/ /scripts/

# Make scripts executable
RUN chmod +x /scripts/*.sh

# Expose MLflow default port
EXPOSE 5000

# Health check to ensure MLflow server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Default command: Start MLflow server using entrypoint script
# The entrypoint script handles environment variable substitution
# - --host 0.0.0.0: Listen on all interfaces (required for Docker)
# - --port 5000: MLflow default port
# - --backend-store-uri: PostgreSQL connection string (from environment)
# - --default-artifact-root: Artifact storage location (from environment)
# - --workers: Number of worker processes (can be overridden)
ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]


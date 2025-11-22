# MLflow Tracking Server Dockerfile
# Base image: Python 3.11 slim for smaller image size
# Sonar Best Practices Applied:
# - Specific base image version (not 'latest')
# - Minimal layers for better caching
# - Security: Remove unnecessary packages
# - Non-root user (commented, can be enabled)
# - Health checks for container orchestration
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
# PYTHONUNBUFFERED: Ensure Python output is sent straight to terminal
# PYTHONDONTWRITEBYTECODE: Prevent Python from writing .pyc files
# PIP_NO_CACHE_DIR: Disable pip cache to reduce image size
# PIP_DISABLE_PIP_VERSION_CHECK: Skip pip version check
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies in a single layer
# - postgresql-client: for psql commands (optional, for debugging)
# - curl: for health checks
# - gcc, libpq-dev: required for building psycopg2
# Remove apt cache to reduce image size
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-client \
        curl \
        gcc \
        libpq-dev && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Copy requirements file first for better layer caching
COPY requirements.txt .

# Install Python dependencies
# Using --no-cache-dir to reduce image size
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Create directory for MLflow artifacts (if using local storage)
# Set proper permissions
RUN mkdir -p /app/mlruns && \
    chmod 755 /app/mlruns

# Copy initialization scripts
COPY scripts/ /scripts/

# Make scripts executable and verify they exist
RUN chmod +x /scripts/*.sh && \
    test -f /scripts/entrypoint.sh || (echo "Error: entrypoint.sh not found" && exit 1)

# Security: Consider running as non-root user (uncomment if needed)
# RUN groupadd -r mlflow && useradd -r -g mlflow mlflow && \
#     chown -R mlflow:mlflow /app /scripts
# USER mlflow

# Expose MLflow default port
# Using explicit port number instead of variable
EXPOSE 5000

# Health check to ensure MLflow server is running
# Interval: Check every 30 seconds
# Timeout: 10 seconds per check
# Start period: Allow 40 seconds for initial startup
# Retries: 3 attempts before marking unhealthy
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


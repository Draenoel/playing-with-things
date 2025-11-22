#!/bin/bash
# =============================================================================
# MLflow Server Entrypoint Script
# =============================================================================
# This script starts the MLflow server with environment variable substitution
# Supports both local filesystem and S3/MinIO storage backends

set -e

# Default values if not set
MLFLOW_WORKERS=${MLFLOW_WORKERS:-4}
STORAGE_BACKEND=${STORAGE_BACKEND:-s3}

# Validate required environment variables
if [ -z "$MLFLOW_BACKEND_STORE_URI" ]; then
    echo "Error: MLFLOW_BACKEND_STORE_URI is not set"
    exit 1
fi

# Determine artifact root based on storage backend
if [ -n "$MLFLOW_ARTIFACT_ROOT" ]; then
    # Use explicitly provided artifact root
    ARTIFACT_ROOT="$MLFLOW_ARTIFACT_ROOT"
    echo "Using explicitly configured artifact root: $ARTIFACT_ROOT"
elif [ "$STORAGE_BACKEND" = "local" ]; then
    # Use local filesystem storage
    ARTIFACT_ROOT="file:/app/mlruns"
    echo "Using local filesystem storage: $ARTIFACT_ROOT"
elif [ "$STORAGE_BACKEND" = "s3" ]; then
    # Use S3/MinIO storage
    MINIO_BUCKET_NAME=${MINIO_BUCKET_NAME:-mlflow-artifacts}
    ARTIFACT_ROOT="s3://${MINIO_BUCKET_NAME}/"
    echo "Using S3/MinIO storage: $ARTIFACT_ROOT"
    echo "S3 Endpoint: ${MLFLOW_S3_ENDPOINT_URL:-http://minio:9000}"
else
    echo "Error: Invalid STORAGE_BACKEND value: $STORAGE_BACKEND"
    echo "Valid values are: 'local' or 's3'"
    exit 1
fi

echo "=========================================="
echo "MLflow Server Configuration"
echo "=========================================="
echo "Storage Backend: $STORAGE_BACKEND"
echo "Artifact Root: $ARTIFACT_ROOT"
echo "Workers: $MLFLOW_WORKERS"
echo "=========================================="

# Start MLflow server
exec mlflow server \
    --host 0.0.0.0 \
    --port 5000 \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${ARTIFACT_ROOT}" \
    --workers "${MLFLOW_WORKERS}"


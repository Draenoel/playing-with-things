#!/usr/bin/env bash
# =============================================================================
# MLflow Server Entrypoint Script
# =============================================================================
# This script starts the MLflow server with environment variable substitution
# Supports both local filesystem and S3/MinIO storage backends
#
# Bash Best Practices Applied:
# - set -euo pipefail: Exit on error, undefined vars, pipe failures
# - Quoted variables: Prevents word splitting and pathname expansion
# - [[ ]] instead of [ ]: More robust conditional testing
# - Readonly constants: Immutable values
# - Explicit error handling: Clear error messages

set -euo pipefail

# Constants
readonly MLFLOW_HOST="0.0.0.0"
readonly MLFLOW_PORT="5000"
readonly LOCAL_STORAGE_PATH="file:/app/mlruns"
readonly STORAGE_BACKEND_LOCAL="local"
readonly STORAGE_BACKEND_S3="s3"

# Default values with validation
readonly MLFLOW_WORKERS="${MLFLOW_WORKERS:-4}"
readonly STORAGE_BACKEND="${STORAGE_BACKEND:-s3}"

# Validate required environment variables
if [[ -z "${MLFLOW_BACKEND_STORE_URI:-}" ]]; then
    echo "Error: MLFLOW_BACKEND_STORE_URI is not set" >&2
    exit 1
fi

# Validate storage backend value
if [[ "${STORAGE_BACKEND}" != "${STORAGE_BACKEND_LOCAL}" ]] && \
   [[ "${STORAGE_BACKEND}" != "${STORAGE_BACKEND_S3}" ]]; then
    echo "Error: Invalid STORAGE_BACKEND value: '${STORAGE_BACKEND}'" >&2
    echo "Valid values are: '${STORAGE_BACKEND_LOCAL}' or '${STORAGE_BACKEND_S3}'" >&2
    exit 1
fi

# Determine artifact root based on storage backend
declare artifact_root
if [[ -n "${MLFLOW_ARTIFACT_ROOT:-}" ]]; then
    # Use explicitly provided artifact root
    artifact_root="${MLFLOW_ARTIFACT_ROOT}"
    echo "Using explicitly configured artifact root: ${artifact_root}"
elif [[ "${STORAGE_BACKEND}" == "${STORAGE_BACKEND_LOCAL}" ]]; then
    # When using local storage with --serve-artifacts, use mlflow-artifacts:/ URI
    # This tells clients to upload artifacts via HTTP to the tracking server
    artifact_root="mlflow-artifacts:/"
    echo "Using local filesystem storage with artifact serving: ${artifact_root}"
    echo "Artifacts will be stored in: ${LOCAL_STORAGE_PATH#file:}"
elif [[ "${STORAGE_BACKEND}" == "${STORAGE_BACKEND_S3}" ]]; then
    # Use S3/MinIO storage
    readonly minio_bucket_name="${MINIO_BUCKET_NAME:-mlflow-artifacts}"
    artifact_root="s3://${minio_bucket_name}/"
    echo "Using S3/MinIO storage: ${artifact_root}"
    echo "S3 Endpoint: ${MLFLOW_S3_ENDPOINT_URL:-http://minio:9000}"
else
    echo "Error: Unexpected storage backend configuration" >&2
    exit 1
fi

# Display configuration
echo "=========================================="
echo "MLflow Server Configuration"
echo "=========================================="
echo "Storage Backend: ${STORAGE_BACKEND}"
echo "Artifact Root: ${artifact_root}"
echo "Workers: ${MLFLOW_WORKERS}"
echo "=========================================="

# Verify mlflow command exists
if ! command -v mlflow &> /dev/null; then
    echo "Error: mlflow command not found in PATH" >&2
    exit 1
fi

# Start MLflow server
# Using exec to replace shell process and handle signals properly
# When using local storage, enable artifact serving via HTTP to allow remote clients
# to upload artifacts without needing direct file system access
if [[ "${STORAGE_BACKEND}" == "${STORAGE_BACKEND_LOCAL}" ]]; then
    # Extract the path from file:// URI for artifacts-destination
    readonly artifacts_dest="${LOCAL_STORAGE_PATH#file:}"
    exec mlflow server \
        --host "${MLFLOW_HOST}" \
        --port "${MLFLOW_PORT}" \
        --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
        --default-artifact-root "${artifact_root}" \
        --serve-artifacts \
        --artifacts-destination "${artifacts_dest}" \
        --workers "${MLFLOW_WORKERS}"
else
    # For S3 storage, artifacts are handled via S3 API, no need for serve-artifacts
    exec mlflow server \
        --host "${MLFLOW_HOST}" \
        --port "${MLFLOW_PORT}" \
        --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
        --default-artifact-root "${artifact_root}" \
        --workers "${MLFLOW_WORKERS}"
fi


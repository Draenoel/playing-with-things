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
    # Use local filesystem storage
    artifact_root="${LOCAL_STORAGE_PATH}"
    echo "Using local filesystem storage: ${artifact_root}"
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
exec mlflow server \
    --host "${MLFLOW_HOST}" \
    --port "${MLFLOW_PORT}" \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --default-artifact-root "${artifact_root}" \
    --workers "${MLFLOW_WORKERS}"


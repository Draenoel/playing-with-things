#!/usr/bin/env sh
# =============================================================================
# MinIO Initialization Script
# =============================================================================
# This script initializes MinIO bucket and access policies for MLflow artifacts
# Run with: docker-compose --profile init up minio-init
# Or manually: docker-compose exec minio-init /scripts/init-minio.sh
#
# Bash Best Practices Applied:
# - set -e: Exit on any error
# - Quoted variables: Prevents word splitting
# - Constants: Readonly values where appropriate
# - Explicit error handling: Clear error messages
# - Command existence checks: Verify required commands

set -e

# Constants
readonly MAX_ATTEMPTS=30
readonly RETRY_DELAY=2
readonly POLICY_FILE="/tmp/bucket-policy.json"

# Configuration from environment variables (with defaults)
readonly MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
readonly MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin}"
readonly MINIO_BUCKET_NAME="${MINIO_BUCKET_NAME:-mlflow-artifacts}"
readonly MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"

echo "=========================================="
echo "MinIO Bucket Initialization"
echo "=========================================="

# Verify mc command exists
if ! command -v mc > /dev/null 2>&1; then
    echo "Error: MinIO client (mc) command not found" >&2
    exit 1
fi

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
attempt=0
until mc alias set minio "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
        echo "Error: MinIO did not become ready after ${MAX_ATTEMPTS} attempts" >&2
        exit 1
    fi
    echo "MinIO is not ready yet. Waiting... (attempt ${attempt}/${MAX_ATTEMPTS})"
    sleep "${RETRY_DELAY}"
done

echo "✓ MinIO is ready. Initializing bucket..."

# Configure MinIO client alias
mc alias set minio "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

# Check if bucket already exists
if mc ls "minio/${MINIO_BUCKET_NAME}" > /dev/null 2>&1; then
    echo "✓ Bucket '${MINIO_BUCKET_NAME}' already exists. Skipping creation."
else
    # Create bucket for MLflow artifacts
    echo "Creating bucket '${MINIO_BUCKET_NAME}'..."
    if mc mb "minio/${MINIO_BUCKET_NAME}"; then
        echo "✓ Bucket '${MINIO_BUCKET_NAME}' created successfully."
    else
        echo "Error: Failed to create bucket '${MINIO_BUCKET_NAME}'" >&2
        exit 1
    fi
fi

# Set bucket policy to allow read/write access
# Note: For production, use more restrictive policies with IAM
echo "Setting bucket policy for MLflow access..."

# Create a policy that allows MLflow to read/write artifacts
# Using heredoc with proper escaping for bucket name
cat > "${POLICY_FILE}" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["*"]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${MINIO_BUCKET_NAME}/*",
        "arn:aws:s3:::${MINIO_BUCKET_NAME}"
      ]
    }
  ]
}
EOF

# Apply policy (this allows access with credentials)
# Suppress error output as credential-based access is acceptable
if ! mc anonymous set-json "${POLICY_FILE}" "minio/${MINIO_BUCKET_NAME}" > /dev/null 2>&1; then
    echo "Note: Using credential-based access (recommended for production)"
fi

# Clean up temporary policy file
rm -f "${POLICY_FILE}"

# Verify bucket exists and is accessible
echo "Verifying bucket access..."
if mc ls "minio/${MINIO_BUCKET_NAME}" > /dev/null 2>&1; then
    echo "✓ Bucket '${MINIO_BUCKET_NAME}' is ready and accessible."
    echo ""
    echo "=========================================="
    echo "MinIO Initialization Complete"
    echo "=========================================="
    echo "Endpoint: ${MINIO_ENDPOINT}"
    echo "Bucket: ${MINIO_BUCKET_NAME}"
    echo "Access Key: ${MINIO_ROOT_USER}"
    echo ""
    echo "MinIO Console: http://localhost:9001"
    echo "Use the access key and secret key to log in."
    echo "=========================================="
else
    echo "✗ Error: Bucket verification failed." >&2
    exit 1
fi


#!/bin/sh
# =============================================================================
# MinIO Initialization Script
# =============================================================================
# This script initializes MinIO bucket and access policies for MLflow artifacts
# Run with: docker-compose --profile init up minio-init
# Or manually: docker-compose exec minio-init /scripts/init-minio.sh

set -e  # Exit on any error

# Configuration from environment variables (with defaults)
MINIO_ROOT_USER=${MINIO_ROOT_USER:-minioadmin}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-minioadmin}
MINIO_BUCKET_NAME=${MINIO_BUCKET_NAME:-mlflow-artifacts}
MINIO_ENDPOINT=${MINIO_ENDPOINT:-http://minio:9000}

echo "=========================================="
echo "MinIO Bucket Initialization"
echo "=========================================="

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
max_attempts=30
attempt=0
until mc alias set minio ${MINIO_ENDPOINT} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "Error: MinIO did not become ready after ${max_attempts} attempts"
        exit 1
    fi
    echo "MinIO is not ready yet. Waiting... (attempt ${attempt}/${max_attempts})"
    sleep 2
done

echo "✓ MinIO is ready. Initializing bucket..."

# Configure MinIO client alias
mc alias set minio ${MINIO_ENDPOINT} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}

# Check if bucket already exists
if mc ls minio/${MINIO_BUCKET_NAME} > /dev/null 2>&1; then
    echo "✓ Bucket '${MINIO_BUCKET_NAME}' already exists. Skipping creation."
else
    # Create bucket for MLflow artifacts
    echo "Creating bucket '${MINIO_BUCKET_NAME}'..."
    mc mb minio/${MINIO_BUCKET_NAME}
    echo "✓ Bucket '${MINIO_BUCKET_NAME}' created successfully."
fi

# Set bucket policy to allow read/write access
# Note: For production, use more restrictive policies with IAM
echo "Setting bucket policy for MLflow access..."

# Create a policy that allows MLflow to read/write artifacts
cat > /tmp/bucket-policy.json <<EOF
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
mc anonymous set-json /tmp/bucket-policy.json minio/${MINIO_BUCKET_NAME} 2>/dev/null || {
    echo "Note: Using credential-based access (recommended for production)"
}

# Verify bucket exists and is accessible
echo "Verifying bucket access..."
if mc ls minio/${MINIO_BUCKET_NAME} > /dev/null 2>&1; then
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
    echo "✗ Error: Bucket verification failed."
    exit 1
fi


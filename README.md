# Self-Hosted MLflow Server

A complete Docker-based setup for running MLflow Tracking Server with PostgreSQL metadata store and S3-compatible MinIO artifact storage.

## Project Overview

This project provides a production-ready, self-hosted MLflow server that includes:

- **MLflow Tracking Server**: Web UI and REST API for experiment tracking
- **PostgreSQL**: Reliable metadata store for experiments, runs, and models
- **Flexible Storage Backend**: Choose between:
  - **Local Storage**: Filesystem-based storage (offline-friendly, no internet required)
  - **MinIO**: S3-compatible object storage for artifacts (production-ready, scalable)
- **Easy Configuration**: Simple `STORAGE_BACKEND` flag to switch between storage modes

## Prerequisites and Requirements

### System Requirements
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Linux**: Tested on Ubuntu 20.04+, Debian 11+, and WSL2
- **Disk Space**: Minimum 10GB free (more recommended for production)
- **Memory**: Minimum 4GB RAM (8GB+ recommended)

### Software Dependencies
- Docker and Docker Compose installed and running
- Git (for cloning the repository)
- Basic knowledge of Docker and MLflow concepts

## Quick Start Guide

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd playing-with-things

# Copy environment variables template
cp env.example .env

# Edit .env file with your preferred settings (optional)
# Default values work for local development
```

### 2. Configure Storage Backend

Choose your storage backend in the `.env` file:

```bash
# For local filesystem storage (no internet required, offline-friendly)
STORAGE_BACKEND=local

# For S3/MinIO storage (default, recommended for production)
STORAGE_BACKEND=s3
```

### 3. Start Services with Docker Compose

**For Local Storage (Offline Mode):**
```bash
# Start services without MinIO (local storage only)
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

**For S3/MinIO Storage:**
```bash
# Start all services including MinIO
docker-compose --profile s3 up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### 4. Access Services

Once services are running, access them at:

- **MLflow UI**: http://localhost:5000
- **MinIO Console** (only when using S3 storage): http://localhost:9001
  - Default credentials: `minioadmin` / `minioadmin` (change in `.env`)
- **PostgreSQL**: `localhost:5432`
  - Database: `mlflow`
  - Default user: `mlflow` (credentials in `.env`)

### 5. Initialize MinIO Bucket (S3 Storage Only)

If using S3/MinIO storage, initialize the bucket:

```bash
# Option 1: Run initialization service (recommended)
docker-compose --profile s3 --profile init up minio-init

# Option 2: Run manually
docker-compose --profile s3 run --rm minio-init

# Option 3: Use MinIO Console (Web UI)
# Access http://localhost:9001 and create bucket manually
```

The bucket will be created with the name specified in `.env` (default: `mlflow-artifacts`).

## Configuration Options

### Storage Backend Selection

This setup supports two storage backends, controlled by the `STORAGE_BACKEND` environment variable:

#### Option 1: Local Storage (Offline Mode)

Perfect for:
- Local development and testing
- Offline environments (no internet required)
- Single-machine deployments
- Quick prototyping

**Setup:**
```bash
# In .env file
STORAGE_BACKEND=local

# Start services (MinIO not required)
docker-compose up -d
```

**Usage in Python:**
```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("my-experiment")

# Artifacts will be stored locally in ./mlruns directory
with mlflow.start_run():
    mlflow.log_param("alpha", 0.5)
    mlflow.log_metric("accuracy", 0.95)
    mlflow.log_artifact("model.pkl")
```

**Benefits:**
- ✅ No internet connection required
- ✅ Simpler setup (no MinIO service)
- ✅ Faster for small-scale use
- ✅ Artifacts stored in `./mlruns` directory

#### Option 2: S3-Compatible MinIO (Production)

Perfect for:
- Production deployments
- Multi-user environments
- Scalable artifact storage
- Distributed setups

**Setup:**
```bash
# In .env file
STORAGE_BACKEND=s3

# Start services with MinIO
docker-compose --profile s3 up -d

# Initialize MinIO bucket
docker-compose --profile s3 --profile init up minio-init
```

**Usage in Python:**
```python
import mlflow
import os

# Set environment variables for S3/MinIO
os.environ['MLFLOW_S3_ENDPOINT_URL'] = 'http://localhost:9000'
os.environ['AWS_ACCESS_KEY_ID'] = 'minioadmin'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'minioadmin'

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("my-experiment")

with mlflow.start_run():
    mlflow.log_param("alpha", 0.5)
    mlflow.log_metric("accuracy", 0.95)
    # Artifacts will be stored in MinIO
    mlflow.log_artifact("model.pkl")
```

**Benefits:**
- ✅ Scalable object storage
- ✅ Better for production workloads
- ✅ S3-compatible (can switch to AWS S3 easily)
- ✅ Web UI for artifact management

### Environment Variables

Key configuration options in `.env`:

- **STORAGE_BACKEND**: Set to `local` for filesystem storage or `s3` for MinIO (default: `s3`)
- **PostgreSQL**: Database credentials and connection settings
- **MinIO**: Access keys, bucket name, and endpoint (only needed when `STORAGE_BACKEND=s3`)
- **MLflow**: Server configuration and artifact paths

See `env.example` for all available options and their descriptions.

**Quick Switch Between Storage Backends:**

```bash
# Switch to local storage
echo "STORAGE_BACKEND=local" >> .env
docker-compose down
docker-compose up -d

# Switch to S3/MinIO storage
echo "STORAGE_BACKEND=s3" >> .env
docker-compose down
docker-compose --profile s3 up -d
```

## Basic Usage Examples

### Example 1: Logging a Simple Experiment

```python
import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Connect to MLflow server
mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("iris-classification")

# Load data
iris = load_iris()
X_train, X_test, y_train, y_test = train_test_split(
    iris.data, iris.target, test_size=0.2, random_state=42
)

# Train model
with mlflow.start_run():
    # Log parameters
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)
    
    # Train and evaluate
    model = RandomForestClassifier(n_estimators=100, max_depth=10)
    model.fit(X_train, y_train)
    accuracy = accuracy_score(y_test, model.predict(X_test))
    
    # Log metrics
    mlflow.log_metric("accuracy", accuracy)
    
    # Log model
    mlflow.sklearn.log_model(model, "model")
    
    print(f"Logged run with accuracy: {accuracy}")
```

### Example 2: Using MinIO for Artifacts

```python
import mlflow
import os

# Configure S3 endpoint for MinIO
os.environ['MLFLOW_S3_ENDPOINT_URL'] = 'http://localhost:9000'
os.environ['AWS_ACCESS_KEY_ID'] = 'minioadmin'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'minioadmin'

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("s3-artifacts-demo")

with mlflow.start_run():
    # Log artifacts to MinIO
    with open("data.txt", "w") as f:
        f.write("Sample data")
    mlflow.log_artifact("data.txt")
    
    print("Artifact logged to MinIO")
```

### Example 3: Loading a Logged Model

```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5000")

# Load model from a specific run
model_uri = "runs:/<run-id>/model"
model = mlflow.sklearn.load_model(model_uri)

# Use the model for predictions
predictions = model.predict(X_new)
```

## Troubleshooting

### Common Issues

#### 1. Services Won't Start

**Problem**: Docker containers fail to start or exit immediately.

**Solutions**:
```bash
# Check logs for errors
docker-compose logs

# Verify ports are not in use
netstat -tulpn | grep -E '5000|5432|9000|9001'

# Restart services
docker-compose down
docker-compose up -d
```

#### 2. Cannot Connect to MLflow Server

**Problem**: Connection refused or timeout when accessing MLflow UI.

**Solutions**:
- Verify MLflow service is running: `docker-compose ps`
- Check if port 5000 is accessible: `curl http://localhost:5000`
- Review MLflow logs: `docker-compose logs mlflow`
- Ensure firewall allows port 5000

#### 3. PostgreSQL Connection Errors

**Problem**: MLflow cannot connect to PostgreSQL database.

**Solutions**:
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Verify credentials in .env match
docker-compose exec postgres psql -U mlflow -d mlflow -c "SELECT 1;"

# Check PostgreSQL logs
docker-compose logs postgres
```

#### 4. MinIO Access Denied

**Problem**: Cannot upload artifacts to MinIO.

**Solutions**:
- Verify MinIO credentials in `.env`
- Check bucket exists: `docker-compose exec minio mc ls minio/`
- Reinitialize bucket: `./scripts/init-minio.sh`
- Verify S3 endpoint URL is correct: `http://localhost:9000`

#### 5. Permission Denied Errors

**Problem**: Permission errors when accessing volumes.

**Solutions**:
```bash
# Fix volume permissions
sudo chown -R $USER:$USER ./data
sudo chmod -R 755 ./data

# Or run with sudo (not recommended for production)
sudo docker-compose up -d
```

#### 6. Out of Disk Space

**Problem**: Services fail due to insufficient disk space.

**Solutions**:
```bash
# Check disk usage
df -h

# Clean up Docker resources
docker system prune -a

# Remove old MLflow runs (if using local storage)
rm -rf ./mlruns/*
```

### Health Checks

Verify all services are healthy:

```bash
# Check all services status
docker-compose ps

# Test MLflow API
curl http://localhost:5000/health

# Test PostgreSQL
docker-compose exec postgres pg_isready -U mlflow

# Test MinIO
curl http://localhost:9000/minio/health/live
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mlflow
docker-compose logs -f postgres
docker-compose logs -f minio

# Last 100 lines
docker-compose logs --tail=100 mlflow
```

## Production Deployment

For production deployments, use `docker-compose.prod.yml`:

```bash
# Start with production configuration
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

See `docker-compose.prod.yml` for production-specific settings including:
- Resource limits
- Security hardening
- Backup strategies
- Health check configurations

## Backup and Recovery

### Backup PostgreSQL Database

```bash
# Create backup
docker-compose exec postgres pg_dump -U mlflow mlflow > backup_$(date +%Y%m%d).sql

# Restore from backup
docker-compose exec -T postgres psql -U mlflow mlflow < backup_20240101.sql
```

### Backup MinIO Data

```bash
# Backup MinIO data directory
tar -czf minio_backup_$(date +%Y%m%d).tar.gz ./data/minio
```

## Additional Resources

- [MLflow Documentation](https://www.mlflow.org/docs/latest/index.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MinIO Documentation](https://min.io/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## License

This project is provided as-is for educational and development purposes.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Disclaimer

**Code Generation Notice**: This project was generated with assistance from Cursor, an AI-powered code editor. While the code follows best practices and has been reviewed, users should:

- Review all code before deploying to production
- Test thoroughly in their specific environment
- Update default credentials and secrets
- Follow security best practices for their use case
- Verify compatibility with their infrastructure

The codebase includes:
- SonarQube best practices for code quality
- Bash scripting best practices (proper error handling, variable quoting, etc.)
- Docker security best practices
- Production-ready configurations

However, as with any generated code, it is recommended to perform security audits and testing before production deployment.


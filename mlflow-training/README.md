# MLflow Training Examples

This directory contains training examples to test and showcase MLflow functionality with a local storage backend.

## Prerequisites

- MLflow server running at http://localhost:5000 with local storage backend
- Python 3.8 or higher
- Docker and Docker Compose (for MLflow server)

## Quick Start

### Step 1: Set Up Your Training Environment

Run the setup script to create a virtual environment and install dependencies:

```bash
cd mlflow-training
./setup_training_env.sh
```

Or manually:

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Activate the Virtual Environment

```bash
cd mlflow-training
source venv/bin/activate
```

### Step 3: Run the Training Examples

#### Example 1: Basic Model Training
Trains a simple classifier and logs everything to MLflow:

```bash
python example1_basic.py
```

This will:
- Create an experiment called "iris_classification"
- Train a RandomForest classifier
- Log parameters, metrics, and the model
- Display accuracy, precision, and recall

#### Example 2: Hyperparameter Tuning
Trains multiple models with different hyperparameters:

```bash
python example2_hyperparameter_tuning.py
```

This will:
- Create an experiment called "hyperparameter_tuning"
- Train 5 models with different hyperparameter combinations
- Log each run for comparison
- Show how MLflow handles multiple runs

#### Example 3: Model Registry
Registers a model in the MLflow Model Registry:

```bash
python example3_model_registry.py
```

This will:
- Create an experiment called "model_registry_demo"
- Train a model
- Register it in the Model Registry as "iris_classifier"
- Show model versioning

### Step 4: View Results in MLflow UI

Open your browser and navigate to: **http://localhost:5000**

You'll see:
- **Experiments tab**: Your experiments and runs
- **Runs**: Individual training runs with logged parameters, metrics, and artifacts
- **Model Registry**: Your trained models ready for deployment

### Step 5: Compare Runs

In the MLflow UI:
1. Go to the "hyperparameter_tuning" experiment
2. Select multiple runs
3. Click "Compare" to see metrics, parameters, and performance side-by-side

## Storage Configuration

These examples use **local storage backend**. Artifacts are stored in the MLflow server's local filesystem (typically in `./mlruns` directory on the server).

No S3/MinIO configuration is needed - the examples connect directly to the MLflow server at http://localhost:5000.

**Note:** The MLflow server is configured with `--serve-artifacts` which enables HTTP-based artifact uploads. This means:
- ✅ No local directories needed on your machine
- ✅ Artifacts are uploaded via HTTP to the server
- ✅ The server stores artifacts in `/app/mlruns` inside the container

**Important:** If you encounter permission errors, it's likely because you're using an old experiment that was created before artifact serving was enabled. Old experiments have `file://` URIs. Solution: delete the old experiment or use a new experiment name.

## Troubleshooting

### Cannot Connect to MLflow Server

Make sure MLflow is running:
```bash
cd ..  # Go back to project root
docker-compose ps
```

Check if the server is accessible:
```bash
curl http://localhost:5000/health
```

### Import Errors

Make sure you've activated the virtual environment and installed dependencies:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### Permission Errors

If you encounter permission errors, make sure:
- MLflow server is configured to use local storage backend
- The server has write permissions to its artifact storage directory

## Files in This Directory

- `example1_basic.py`: Basic model training with MLflow logging
- `example2_hyperparameter_tuning.py`: Hyperparameter tuning with multiple runs
- `example3_model_registry.py`: Model registration and versioning
- `setup_training_env.sh`: Automated setup script
- `requirements.txt`: Python dependencies for training examples
- `venv/`: Virtual environment directory (created by setup script)

## Next Steps

1. Run Example 1 first to get familiar with basic logging
2. Run Example 2 to see how MLflow handles multiple runs and comparisons
3. Run Example 3 to register your best model
4. Use the MLflow UI to explore runs, metrics, and models
5. Modify hyperparameters and re-run to see versioning in action


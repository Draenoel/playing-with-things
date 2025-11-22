# Git Setup Guide for MLflow Training

## What to Commit to GitHub

✅ **Commit these files:**
- `example1_basic.py` - Basic training example
- `example2_hyperparameter_tuning.py` - Hyperparameter tuning example
- `example3_model_registry.py` - Model registry example
- `requirements.txt` - Python dependencies
- `setup_training_env.sh` - Setup script
- `README.md` - Documentation

## What to Ignore (Already in .gitignore)

❌ **Ignore these:**
- `venv/` - Virtual environment (auto-generated)
- `mlflow_training/` - Old directory (removed)
- `__pycache__/` - Python cache files
- `*.pyc` - Compiled Python files

The `.gitignore` file in the project root already includes:
- `mlflow-training/venv/` - Training virtual environment
- `mlflow_training/` - Old training directory

## Known Issues

### Artifact Upload Issue - SOLVED ✅

**Solution:** The MLflow server is now configured with `--serve-artifacts` and `--artifacts-destination` flags, which enables HTTP-based artifact uploads. This allows remote clients to upload artifacts via HTTP without needing direct file system access.

**How it works:**
- Server uses `--serve-artifacts` to enable HTTP artifact serving
- Server uses `--artifacts-destination /app/mlruns` to specify where artifacts are stored in the container
- Server uses `--default-artifact-root mlflow-artifacts:/` to tell clients to use HTTP
- Clients upload artifacts via HTTP to `http://localhost:5000/api/2.0/mlflow-artifacts/artifacts/...`

**Important:** Experiments created before enabling `--serve-artifacts` will still have `file://` URIs and won't work. You need to:
- Delete old experiments, OR
- Use new experiment names

**To check experiment artifact URIs:**
```python
import mlflow
mlflow.set_tracking_uri('http://localhost:5000')
client = mlflow.tracking.MlflowClient()
exps = client.search_experiments()
for exp in exps:
    print(f'{exp.name}: {exp.artifact_location}')
```

Experiments with `mlflow-artifacts:/` URIs will work correctly. Those with `file://` URIs need to be recreated.

### Deprecation Warnings

The `artifact_path` deprecation warning comes from MLflow's internal code, not our scripts. It's safe to ignore for now.

The `input_example` warning has been fixed by adding `input_example` parameter to all `log_model()` calls.


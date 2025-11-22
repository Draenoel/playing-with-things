"""
Example 1: Basic Model Training with MLflow Logging

This example trains a simple classifier and logs everything to MLflow.
Uses local storage backend.
"""

import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score
import warnings
import os

warnings.filterwarnings('ignore')

# Set MLflow tracking URI
mlflow.set_tracking_uri("http://localhost:5000")

# Force MLflow to use HTTP for artifact uploads when connecting to remote server
# This ensures artifacts are uploaded via HTTP instead of trying to write to local file paths
os.environ['MLFLOW_TRACKING_URI'] = 'http://localhost:5000'

# Create or set experiment
# Note: Experiments created before enabling --serve-artifacts may have file:// URIs
# Delete old experiments or use a new name to get HTTP-based artifact serving
mlflow.set_experiment("iris_classification_demo")

# Load data
iris = load_iris()
X = pd.DataFrame(iris.data, columns=iris.feature_names)
y = iris.target

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Start MLflow run
with mlflow.start_run(run_name="rf_classifier_v1"):
    # Define hyperparameters
    n_estimators = 100
    max_depth = 10
    random_state = 42
    
    # Log parameters
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)
    mlflow.log_param("random_state", random_state)
    
    # Train model
    model = RandomForestClassifier(
        n_estimators=n_estimators,
        max_depth=max_depth,
        random_state=random_state
    )
    model.fit(X_train, y_train)
    
    # Make predictions
    y_pred = model.predict(X_test)
    
    # Calculate metrics
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted')
    recall = recall_score(y_test, y_pred, average='weighted')
    
    # Log metrics
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("precision", precision)
    mlflow.log_metric("recall", recall)
    
    # Log model with input example to auto-infer signature
    mlflow.sklearn.log_model(
        model, 
        "model",
        input_example=X_test.iloc[:5]  # Use first 5 test samples as input example
    )
    
    # Log additional artifacts (optional)
    mlflow.log_text(f"Training completed successfully", "training_log.txt")
    
    print(f"Run completed with accuracy: {accuracy:.4f}")
    print(f"Precision: {precision:.4f}, Recall: {recall:.4f}")
    print(f"View this run in MLflow UI: http://localhost:5000")


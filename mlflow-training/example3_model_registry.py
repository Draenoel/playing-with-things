"""
Example 3: Model Registration & Versioning

This example shows how to register your best model in the MLflow Model Registry.
Uses local storage backend.
"""

import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import warnings

warnings.filterwarnings('ignore')

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("model_registry_demo")

# Load and prepare data
iris = load_iris()
X_train, X_test, y_train, y_test = train_test_split(
    iris.data, iris.target, test_size=0.2, random_state=42
)

# Train model
with mlflow.start_run(run_name="production_ready_model"):
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train, y_train)
    
    accuracy = accuracy_score(y_test, model.predict(X_test))
    
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)
    mlflow.log_metric("accuracy", accuracy)
    
    # Log model with input example to auto-infer signature
    mlflow.sklearn.log_model(
        model,
        "model",
        input_example=X_test[:5]  # Use first 5 test samples as input example
    )
    
    # Get current run ID
    run_id = mlflow.active_run().info.run_id
    model_uri = f"runs:/{run_id}/model"
    
    # Register model
    try:
        registered_model = mlflow.register_model(
            model_uri=model_uri,
            name="iris_classifier"
        )
        
        print(f"Model registered as: {registered_model.name}, Version: {registered_model.version}")
        print(f"View registered model in MLflow UI: http://localhost:5000")
    except Exception as e:
        print(f"Note: {e}")
        print("Model may already be registered. Check MLflow UI for existing versions.")


"""
Example 2: Hyperparameter Tuning with Multiple Runs

This example trains multiple models with different hyperparameters 
to showcase MLflow's comparison features.
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
mlflow.set_experiment("hyperparameter_tuning")

# Load data
iris = load_iris()
X = iris.data
y = iris.target

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Hyperparameter combinations to test
param_grid = [
    {"n_estimators": 50, "max_depth": 5},
    {"n_estimators": 100, "max_depth": 10},
    {"n_estimators": 200, "max_depth": 15},
    {"n_estimators": 100, "max_depth": 20},
    {"n_estimators": 150, "max_depth": 12},
]

# Train models with different hyperparameters
for i, params in enumerate(param_grid):
    with mlflow.start_run(run_name=f"rf_tuning_run_{i+1}"):
        # Log parameters
        mlflow.log_params(params)
        
        # Train model
        model = RandomForestClassifier(
            n_estimators=params["n_estimators"],
            max_depth=params["max_depth"],
            random_state=42
        )
        model.fit(X_train, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        # Log metrics
        mlflow.log_metric("accuracy", accuracy)
        
        # Log model with input example to auto-infer signature
        mlflow.sklearn.log_model(
            model,
            "model",
            input_example=X_test[:5]  # Use first 5 test samples as input example
        )
        
        print(f"Run {i+1}: n_estimators={params['n_estimators']}, "
              f"max_depth={params['max_depth']}, accuracy={accuracy:.4f}")

print(f"\nAll runs completed! View and compare runs in MLflow UI: http://localhost:5000")


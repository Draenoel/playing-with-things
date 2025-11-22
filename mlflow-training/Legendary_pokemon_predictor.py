import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

# --- 1. SETUP & CONFIGURATION ---
# Point this to your remote server if you have one, or keep localhost
TRACKING_URI = "http://localhost:5000" 
EXPERIMENT_NAME = "Pokemon_Legendary_Predictor"

mlflow.set_tracking_uri(TRACKING_URI)
mlflow.set_experiment(EXPERIMENT_NAME)

print(f"Tracking to: {mlflow.get_tracking_uri()}")
print(f"Experiment: {EXPERIMENT_NAME}")

# --- 2. PREPARE THE DATA ---
# We load directly from a public GitHub gist (no local download needed)
url = "https://gist.githubusercontent.com/armgilles/194bcff35001e7eb53a2a8b441e8b2c6/raw/92200bc0a673d5ce2110aaad4544ed6c4010f687/pokemon.csv"
print("Downloading Pokedex...")
df = pd.read_csv(url)

# Select features (The Stats) and Target (Legendary)
features = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed']
target = 'Legendary'

X = df[features]
y = df[target]

# Split: 80% for training, 20% for testing
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# --- 3. TRAIN & LOG ---
with mlflow.start_run(run_name="Legendary_Hunter_v1"):
    
    # A. Hyperparameters
    n_estimators = 100
    max_depth = 15
    
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)
    mlflow.log_param("features_used", str(features))

    # B. Train the Model
    print("Training model...")
    clf = RandomForestClassifier(n_estimators=n_estimators, max_depth=max_depth, random_state=42)
    clf.fit(X_train, y_train)

    # C. Evaluate
    y_pred = clf.predict(X_test)
    
    acc = accuracy_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    
    print(f"Accuracy: {acc:.4f} | Precision: {prec:.4f} | Recall: {recall:.4f}")
    
    mlflow.log_metric("accuracy", acc)
    mlflow.log_metric("precision", prec)
    mlflow.log_metric("recall", recall)

    # D. Log the Confusion Matrix (Visual Artifact)
    # This creates a plot showing True Positives vs False Positives
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(6,6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['Normal', 'Legendary'], 
                yticklabels=['Normal', 'Legendary'])
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.title('Legendary Prediction Confusion Matrix')
    
    # Save plot locally then log it to MLflow
    plt.savefig("confusion_matrix.png")
    mlflow.log_artifact("confusion_matrix.png")

    # E. Log the Model itself
    # input_example helps MLflow understand the data schema
    mlflow.sklearn.log_model(clf, "model", input_example=X_train.iloc[:5])

    print("Run Complete! Check MLflow UI.")
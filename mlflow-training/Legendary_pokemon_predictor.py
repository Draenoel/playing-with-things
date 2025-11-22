import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

# --- CONFIGURATION ---
TRACKING_URI = "http://localhost:5000" 
EXPERIMENT_NAME = "Pokemon_Legendary_Predictor"

mlflow.set_tracking_uri(TRACKING_URI)
mlflow.set_experiment(EXPERIMENT_NAME)

# --- DATA ---
url = "https://gist.githubusercontent.com/armgilles/194bcff35001e7eb53a2a8b441e8b2c6/raw/92200bc0a673d5ce2110aaad4544ed6c4010f687/pokemon.csv"
df = pd.read_csv(url)

# 1. FEATURE ENGINEERING: Calculate "Total Stats"
# This gives the model a clear summary of power
df['Total_Stats'] = df['HP'] + df['Attack'] + df['Defense'] + df['Sp. Atk'] + df['Sp. Def'] + df['Speed']

features = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed', 'Generation', 'Total_Stats']
target = 'Legendary'

X = df[features]
y = df[target]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# --- TRAIN ---
with mlflow.start_run(run_name="Legendary_Hunter_v3_Engineered"):
    
    n_estimators = 100
    max_depth = 15
    
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)
    mlflow.log_param("features_used", str(features))
    mlflow.log_param("class_weight", "balanced") # Log this new change

    print("Training model with Total Stats + Balanced Weights...")
    
    # 2. MODEL TWEAK: class_weight='balanced'
    # This forces the model to care more about the rare "Legendary" class
    clf = RandomForestClassifier(
        n_estimators=n_estimators, 
        max_depth=max_depth, 
        random_state=42,
        class_weight='balanced' 
    )
    clf.fit(X_train, y_train)

    y_pred = clf.predict(X_test)
    
    acc = accuracy_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    
    print(f"Accuracy: {acc:.4f} | Precision: {prec:.4f} | Recall: {recall:.4f}")
    
    mlflow.log_metric("accuracy", acc)
    mlflow.log_metric("precision", prec)
    mlflow.log_metric("recall", recall)

    # Confusion Matrix
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(6,6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['Normal', 'Legendary'], 
                yticklabels=['Normal', 'Legendary'])
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.title('Legendary Prediction (v3 Balanced)')
    
    plt.savefig("confusion_matrix_v3.png")
    mlflow.log_artifact("confusion_matrix_v3.png")

    mlflow.sklearn.log_model(clf, "model", input_example=X_train.iloc[:5])

    print("Run v3 Complete! Check MLflow UI.")
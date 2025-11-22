import pickle
import pandas as pd
from sklearn.model_selection import train_test_split

# 1. Load Data
url = "https://gist.githubusercontent.com/armgilles/194bcff35001e7eb53a2a8b441e8b2c6/raw/92200bc0a673d5ce2110aaad4544ed6c4010f687/pokemon.csv"
df = pd.read_csv(url)
df['Total_Stats'] = df['HP'] + df['Attack'] + df['Defense'] + df['Sp. Atk'] + df['Sp. Def'] + df['Speed']
features = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed', 'Generation', 'Total_Stats']
X = df[features]
y = df['Legendary']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 2. Load the Downloaded Model
print("Loading model from local file 'my_model.pkl'...")
with open("my_model.pkl", "rb") as f:
    model = pickle.load(f)

# 3. Reveal the Impostors
predictions = model.predict(X_test)
results = X_test.copy()
results['Actual'] = y_test
results['Predicted'] = predictions
results['Name'] = df.loc[X_test.index, 'Name']

print("\n--- THE IMPOSTORS (False Positives) ---")
# Predicted True, Actually False
impostors = results[(results['Predicted'] == True) & (results['Actual'] == False)]
print(impostors[['Name', 'Total_Stats']])
from sentence_transformers import SentenceTransformer
import os

# Create models directory
os.makedirs('models/all-MiniLM-L6-v2', exist_ok=True)

# Load and save the model
model = SentenceTransformer('all-MiniLM-L6-v2')
model.save('models/all-MiniLM-L6-v2')

print("Model saved successfully to 'models/all-MiniLM-L6-v2'")

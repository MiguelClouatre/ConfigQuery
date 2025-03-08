# test_config.py
import config

print("Configuration test:")
print(f"OpenAI API Key set: {'Yes' if config.OPENAI_API_KEY else 'No'}")
print(f"Using model: {config.OPENAI_MODEL}")
print(f"ChromaDB path: {config.CHROMA_DB_PATH}")

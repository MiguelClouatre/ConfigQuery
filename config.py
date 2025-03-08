"""
Configuration file for the chatbot application.
Handles loading of environment variables and setting default configurations.
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# OpenAI API Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")  # Default to GPT-3.5 Turbo if not specified
OPENAI_TEMPERATURE = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))  # Default temperature
OPENAI_MAX_TOKENS = int(os.getenv("OPENAI_MAX_TOKENS", "1024"))  # Default max tokens

# ChromaDB Configuration
CHROMA_DB_PATH = os.getenv("CHROMA_DB_PATH", "./chroma_db")
CHROMA_COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "msp_configs")

# Conversation Configuration
MAX_CONVERSATION_HISTORY = int(os.getenv("MAX_CONVERSATION_HISTORY", "10"))  # Number of messages to keep

# Application Configuration
DEBUG_MODE = os.getenv("DEBUG_MODE", "False").lower() == "true"

# Validate required configuration
def validate_config():
    """Validate that all required configuration variables are set."""
    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY is not set. Please set it in your .env file or environment variables.")
    
    # Add any other validation checks here
    
    if DEBUG_MODE:
        print("Configuration loaded successfully.")
        print(f"Using model: {OPENAI_MODEL}")
        print(f"ChromaDB path: {CHROMA_DB_PATH}")
        print(f"ChromaDB collection: {CHROMA_COLLECTION_NAME}")

# Call validation function when this module is imported
validate_config()
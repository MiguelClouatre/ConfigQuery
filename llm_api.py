"""
LLM API Module

Handles all interactions with the OpenAI API, including sending requests,
handling responses, and managing errors.
"""
import time
import openai
from openai import OpenAI
import config

# Initialize the OpenAI client with the API key from config
client = OpenAI(api_key=config.OPENAI_API_KEY)

def create_chat_completion(messages, model=None, temperature=None, max_tokens=None):
    """
    Send a request to the OpenAI Chat Completions API and return the response.
    
    Args:
        messages (list): List of message dictionaries in the format 
                        [{"role": "system", "content": "..."}, 
                         {"role": "user", "content": "..."}]
        model (str, optional): The model to use. Defaults to config.OPENAI_MODEL.
        temperature (float, optional): Controls randomness. Defaults to config.OPENAI_TEMPERATURE.
        max_tokens (int, optional): Maximum tokens in response. Defaults to config.OPENAI_MAX_TOKENS.
    
    Returns:
        str: The assistant's response text
        
    Raises:
        Exception: If there's an error communicating with the API
    """
    # Use default values from config if not explicitly provided
    model = model or config.OPENAI_MODEL
    temperature = temperature if temperature is not None else config.OPENAI_TEMPERATURE
    max_tokens = max_tokens or config.OPENAI_MAX_TOKENS
    
    # Log the request if in debug mode
    if config.DEBUG_MODE:
        print(f"Sending request to {model}:")
        for msg in messages:
            print(f"  {msg['role']}: {msg['content'][:50]}...")
    
    try:
        # Send the request to the OpenAI API
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        
        # Extract and return the response text
        return response.choices[0].message.content
    
    except openai.APIError as e:
        # Handle API errors
        print(f"OpenAI API Error: {str(e)}")
        raise Exception(f"Error communicating with the AI service: {str(e)}")
    
    except openai.APIConnectionError as e:
        # Handle connection errors
        print(f"Connection Error: {str(e)}")
        raise Exception("Unable to connect to the AI service. Please check your internet connection.")
    
    except openai.RateLimitError as e:
        # Handle rate limit errors with exponential backoff
        print(f"Rate limit exceeded: {str(e)}")
        wait_time = 5
        print(f"Waiting {wait_time} seconds and trying again...")
        time.sleep(wait_time)
        # Recursive call with exponential backoff would go here in a more complex implementation
        raise Exception("The AI service is currently overloaded. Please try again later.")
    
    except Exception as e:
        # Handle any other unexpected errors
        print(f"Unexpected error: {str(e)}")
        raise Exception(f"An unexpected error occurred: {str(e)}")

def simple_completion(prompt, system_message=None):
    """
    A simplified interface for quick completions.
    
    Args:
        prompt (str): The user's prompt
        system_message (str, optional): System instructions. Defaults to a generic helpful assistant.
    
    Returns:
        str: The assistant's response
    """
    # Set up a default system message if none is provided
    if system_message is None:
        system_message = "You are a helpful assistant that provides clear and concise answers."
    
    # Create the messages array
    messages = [
        {"role": "system", "content": system_message},
        {"role": "user", "content": prompt}
    ]
    
    # Call the main function and return the result
    return create_chat_completion(messages)

# Simple test function
if __name__ == "__main__":
    # Test the API connection
    try:
        response = simple_completion("Hello, how are you today?")
        print("API Response:")
        print(response)
        print("\nAPI connection test successful!")
    except Exception as e:
        print(f"API test failed: {str(e)}")

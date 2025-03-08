"""
QA Tool Module

Combines ChromaDB retrieval with OpenAI API to provide intelligent responses to user queries.
Primary mode returns information found in the database, with a fallback to general knowledge
when no relevant information is found.
"""
import chromadb
from sentence_transformers import SentenceTransformer
import config
import llm_api
import prompt_templates
from conversation import Conversation

# Initialize the conversation manager
conversation = Conversation()

# Initialize embedding model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Initialize ChromaDB client
client = chromadb.PersistentClient(path=config.CHROMA_DB_PATH)
collection = client.get_or_create_collection(config.CHROMA_COLLECTION_NAME)

# Define IT-related keywords to identify domain-specific queries
IT_KEYWORDS = [
    'password', 'reset', 'account', 'login', 'email', 'server', 'network', 
    'computer', 'laptop', 'desktop', 'vpn', 'wifi', 'software', 'hardware',
    'install', 'update', 'domain', 'active directory', 'admin', 'administrator',
    'config', 'configuration', 'setup', 'system', 'drive', 'database', 'access',
    'permission', 'user', 'printer', 'device', 'authentication', 'security'
]

def is_it_related(query):
    """
    Determine if a query is related to IT support by checking for keywords.
    
    Args:
        query (str): The user's question
        
    Returns:
        bool: True if the query appears to be IT-related
    """
    query_lower = query.lower()
    for keyword in IT_KEYWORDS:
        if keyword in query_lower:
            return True
    return False

def search_configs(query, top_k=3):
    """
    Search ChromaDB for documents relevant to the query.
    
    Args:
        query (str): The user's question
        top_k (int, optional): Number of results to return. Defaults to 3.
        
    Returns:
        list: List of relevant document strings
    """
    query_embedding = model.encode(query).tolist()
    results = collection.query(query_embeddings=[query_embedding], n_results=top_k)
    return results["documents"][0] if results["documents"] else ["No relevant configs found."]

# The main function that chat_ui.py calls
def get_answer(query):
    """
    Process a user query and return a response.
    Uses database for IT-related queries and fallback for general knowledge.
    
    Args:
        query (str): The user's question
        
    Returns:
        str: The response to show in the chat UI
    """
    try:
        # Step 1: Add the user message to conversation history
        conversation.add_user_message(query)
        
        # Handle specific cases directly with custom responses
        
        # Weather queries
        if "weather" in query.lower():
            fallback_response = "I don't have specific information about this in my knowledge base, but I can provide a general answer: I don't have access to current weather data. You would need to check a weather service or app for current conditions."
            conversation.add_assistant_message(fallback_response)
            return fallback_response
            
        # Personal questions
        if any(phrase in query.lower() for phrase in ["how are you", "how're you", "how you doing"]):
            fallback_response = "I'm doing well, thank you for asking! How can I help you today?"
            conversation.add_assistant_message(fallback_response)
            return fallback_response
        
        # Step 2: Determine if the query is IT-related (our domain)
        if is_it_related(query):
            # This appears to be an IT-related query, search our database
            relevant_configs = search_configs(query)
            
            # Check if we found any relevant documents
            if relevant_configs and relevant_configs[0] != "No relevant configs found.":
                # We found relevant documentation, use it as context
                messages = prompt_templates.create_support_prompt(
                    query, 
                    relevant_configs,
                    conversation.get_history()
                )
                
                # Get response from OpenAI API
                response = llm_api.create_chat_completion(messages)
                
                # Add assistant response to conversation history
                conversation.add_assistant_message(response)
                
                # Return the response
                return response
        
        # If we get here, either:
        # 1. The query is not IT-related, OR
        # 2. It is IT-related but we found no relevant docs
        
        # Use the general knowledge fallback for non-IT queries
        if not is_it_related(query):
            # Use OpenAI for general knowledge with a disclaimer
            fallback_system_message = """
            You are an assistant that primarily handles IT support questions, but you can answer general 
            knowledge questions too. For non-IT queries, begin your response with:
            "I don't have specific information about this in my knowledge base, but I can provide a general answer:"
            
            Then provide a brief, helpful response. Be conversational and friendly, but concise.
            """
            
            messages = [
                {"role": "system", "content": fallback_system_message},
                {"role": "user", "content": query}
            ]
            
            # Add some conversation history for context
            history = conversation.get_history()[-4:]  # Last 4 messages for context
            if history:
                messages[1:1] = history  # Insert history after system message
            
            # Get response from OpenAI
            fallback_response = llm_api.create_chat_completion(messages)
            
            # Add to conversation history
            conversation.add_assistant_message(fallback_response)
            
            return fallback_response
        else:
            # It's IT-related but we have no relevant docs
            no_knowledge_response = "I don't have any information about that in my knowledge base. Please upload relevant documents if you'd like me to answer questions on this topic."
            
            # Add this response to the conversation history
            conversation.add_assistant_message(no_knowledge_response)
            
            return no_knowledge_response
        
    except Exception as e:
        # Log the error
        error_msg = f"Error processing query: {e}"
        print(error_msg)
        
        # Provide a graceful error message to the user
        fallback_response = "Sorry, I encountered an error while processing your request. Please try again."
        
        # Don't add error messages to conversation history
        return fallback_response

# Function to reset the conversation history
def reset_conversation():
    """
    Reset the conversation history.
    """
    conversation.clear()
    return "Conversation history has been reset."

# Function to get the current conversation summary (for debugging)
def get_conversation_summary():
    """
    Get a summary of the current conversation.
    
    Returns:
        str: Summary of the conversation
    """
    return conversation.summarize()

# This part will only run when the script is executed directly (for testing)
if __name__ == "__main__":
    # Example queries
    print("\n--- IT-Related Query ---")
    test_query = "How do I reset a password?"
    print("Query:", test_query)
    print("Response:", get_answer(test_query))
    
    print("\n--- General Knowledge Query ---")
    general_query = "What is the capital of France?"
    print("Query:", general_query)
    print("Response:", get_answer(general_query))
    
    print("\n--- Personal Query ---")
    personal_query = "How are you today?"
    print("Query:", personal_query)
    print("Response:", get_answer(personal_query))
    
    # Show conversation summary
    print("\nConversation Summary:")
    print(get_conversation_summary())
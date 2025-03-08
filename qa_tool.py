"""
QA Tool Module

Combines ChromaDB retrieval with OpenAI API to provide intelligent responses to user queries.
Only returns information found in the database.
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

# Initialize ChromaDB client - now using path from config
client = chromadb.PersistentClient(path=config.CHROMA_DB_PATH)
collection = client.get_or_create_collection(config.CHROMA_COLLECTION_NAME)

# REMOVED: No more default example documents

# Function to search for relevant configs
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
    Process a user query and return a response using only information in ChromaDB.
    
    Args:
        query (str): The user's question
        
    Returns:
        str: The response to show in the chat UI
    """
    try:
        # Step 1: Add the user message to conversation history
        conversation.add_user_message(query)
        
        # Step 2: Search ChromaDB for relevant documents
        relevant_configs = search_configs(query)
        
        # Step 3: Check if we found any relevant documents
        if relevant_configs and relevant_configs[0] != "No relevant configs found.":
            # We found relevant documentation, use it as context
            messages = prompt_templates.create_support_prompt(
                query, 
                relevant_configs,
                conversation.get_history()
            )
            
            # Step 4: Get response from OpenAI API
            response = llm_api.create_chat_completion(messages)
            
            # Step 5: Add assistant response to conversation history
            conversation.add_assistant_message(response)
            
            # Step 6: Return the response
            return response
        else:
            # No relevant documents found, return a standard "I don't know" response
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
    # Example query
    test_query = "How do I add a user to a shared mailbox at BDW?"
    print("Query:", test_query)
    print("\nResponse:", get_answer(test_query))
    
    # Show conversation summary
    print("\nConversation Summary:")
    print(get_conversation_summary())
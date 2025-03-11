"""
QA Tool Module

Combines ChromaDB retrieval with OpenAI API to provide intelligent responses to user queries.
Includes enhanced search with synonym support and flexible fallback to general knowledge.
"""
import chromadb
from sentence_transformers import SentenceTransformer
import config
import llm_api
import prompt_templates
from conversation import Conversation
import re

# Initialize the conversation manager
conversation = Conversation()

# Initialize embedding model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Initialize ChromaDB client - now using path from config
client = chromadb.PersistentClient(path=config.CHROMA_DB_PATH)
collection = client.get_or_create_collection(config.CHROMA_COLLECTION_NAME)

# Define synonyms for common IT terms to enhance search
SYNONYM_MAPPING = {
    # Verbs for account/password operations
    "reset": ["change", "update", "modify", "alter", "edit", "fix"],
    "change": ["reset", "update", "modify", "alter", "edit", "revise"],
    "add": ["create", "generate", "make", "setup", "configure", "establish"],
    "remove": ["delete", "disable", "revoke", "terminate", "eliminate"],
    "install": ["setup", "deploy", "implement", "add", "configure"],
    
    # Nouns for IT objects
    "password": ["credentials", "login", "authentication", "passcode", "pwd"],
    "account": ["user", "profile", "login", "id", "identity"],
    "config": ["configuration", "setting", "option", "parameter", "preference"],
    "settings": ["options", "preferences", "configurations", "parameters", "setup"],
    
    # Domain terminology
    "ms": ["microsoft", "office365", "azure", "windows", "o365"],
    "microsoft": ["ms", "office365", "windows", "o365", "msft"],
    "login": ["sign in", "log in", "access", "authenticate", "credentials"],
    "vpn": ["remote access", "remote connection", "virtual private network"],
    
    # Common IT topics
    "email": ["mail", "outlook", "message", "inbox"],
    "printer": ["printing", "print", "scanner", "copier"],
    "network": ["internet", "connection", "wifi", "ethernet", "lan"],
    "file": ["document", "folder", "directory", "data"],
    "permission": ["access", "right", "privilege", "authorization"],
}

# Define IT-related keywords to identify domain-specific queries
IT_KEYWORDS = [
    'password', 'reset', 'account', 'login', 'email', 'server', 'network', 
    'computer', 'laptop', 'desktop', 'vpn', 'wifi', 'software', 'hardware',
    'install', 'update', 'domain', 'active directory', 'admin', 'administrator',
    'config', 'configuration', 'setup', 'system', 'drive', 'database', 'access',
    'permission', 'user', 'printer', 'device', 'authentication', 'security',
    'microsoft', 'ms', 'windows', 'office', 'azure', 'sharepoint', 'onedrive',
    'app', 'application', 'program', 'browser', 'website', 'portal', 'cloud',
    'file', 'folder', 'document', 'data', 'backup', 'restore', 'recover'
]

def expand_query_with_synonyms(query):
    """
    Expand a query with synonyms to improve search results.
    
    Args:
        query (str): The original user query
        
    Returns:
        str: Expanded query with synonyms
    """
    words = query.lower().split()
    expanded_words = words.copy()
    
    for word in words:
        # Clean the word of punctuation for matching
        clean_word = re.sub(r'[^\w\s]', '', word)
        
        # Check if this word has synonyms
        if clean_word in SYNONYM_MAPPING:
            # Add synonyms to expanded words
            expanded_words.extend(SYNONYM_MAPPING[clean_word])
    
    # Remove duplicates while preserving order
    expanded_words = list(dict.fromkeys(expanded_words))
    
    # Join into a single string
    expanded_query = " ".join(expanded_words)
    
    return expanded_query

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

def search_configs(query, top_k=5):
    """
    Search ChromaDB for documents relevant to the query with enhanced semantic matching.
    
    Args:
        query (str): The user's question
        top_k (int, optional): Number of results to return. Defaults to 5.
        
    Returns:
        list: List of relevant document strings
        list: List of similarity scores
        bool: Whether any results were found
    """
    # Expand query with synonyms to improve matching
    expanded_query = expand_query_with_synonyms(query)
    
    # Encode the expanded query
    query_embedding = model.encode(expanded_query).tolist()
    
    # Search for the most relevant documents
    results = collection.query(query_embeddings=[query_embedding], n_results=top_k)
    
    # Check if we have any results
    if results["documents"] and len(results["documents"][0]) > 0:
        return results["documents"][0], results["distances"][0], True
    else:
        return ["No relevant configs found."], [0], False

# Dictionary to store conversations by ID
conversation_instances = {"default": Conversation()}

def get_answer(query, conversation_id="default"):
    """
    Process a user query and return a response.
    Uses enhanced search with flexible fallback to general knowledge.
    
    Args:
        query (str): The user's question
        conversation_id (str, optional): Identifier for the conversation. Defaults to "default".
        
    Returns:
        str: The response to show in the chat UI
    """
    try:
        # Get or create conversation instance
        if conversation_id not in conversation_instances:
            conversation_instances[conversation_id] = Conversation()
        
        # Use the appropriate conversation instance
        conv = conversation_instances[conversation_id]
        
        # Step 1: Add the user message to conversation history
        conv.add_user_message(query)
        
        # Handle specific cases directly with custom responses
        # Weather and personal queries handled directly
        if any(word in query.lower() for word in ["weather", "temperature", "forecast", "rain", "snow"]):
            fallback_response = "I don't have specific information about this in my knowledge base, but I can provide a general answer: I don't have access to current weather data. You would need to check a weather service or app for current conditions."
            conv.add_assistant_message(fallback_response)
            return fallback_response
            
        if any(phrase in query.lower() for phrase in ["how are you", "how're you", "how you doing"]):
            fallback_response = "I'm doing well, thank you for asking! How can I help you today?"
            conv.add_assistant_message(fallback_response)
            return fallback_response
        
        # Step 2: Search ChromaDB for relevant documents and get similarity scores
        relevant_docs, similarity_scores, has_results = search_configs(query)
        
        # Very low threshold just to filter out completely irrelevant results
        minimum_threshold = 0.2
        
        # Step 3: Determine response approach based on search results and confidence
        if has_results and max(similarity_scores) >= minimum_threshold:
            # We have some potentially relevant documents
            
            # Group documents by relevance level
            high_confidence_docs = []
            medium_confidence_docs = []
            low_confidence_docs = []
            
            for doc, score in zip(relevant_docs, similarity_scores):
                if score >= 0.5:  # High confidence
                    high_confidence_docs.append(doc)
                elif score >= 0.3:  # Medium confidence
                    medium_confidence_docs.append(doc)
                else:  # Low confidence but above minimum threshold
                    low_confidence_docs.append(doc)
            
            # Choose appropriate prompt template based on confidence levels
            if high_confidence_docs:
                # Use strict prompt with high confidence documents
                messages = prompt_templates.create_high_confidence_prompt(
                    query, 
                    high_confidence_docs,
                    conv.get_history()
                )
            elif medium_confidence_docs:
                # Use medium confidence prompt that allows some inference
                all_docs = medium_confidence_docs + low_confidence_docs
                messages = prompt_templates.create_medium_confidence_prompt(
                    query, 
                    all_docs,
                    conv.get_history()
                )
            else:
                # Use low confidence prompt that allows more general knowledge with the docs as reference
                messages = prompt_templates.create_low_confidence_prompt(
                    query, 
                    low_confidence_docs,
                    conv.get_history(),
                    is_it_related(query)
                )
        else:
            # No relevant documents found - use general knowledge with appropriate disclaimers
            messages = prompt_templates.create_fallback_prompt(
                query,
                conv.get_history(),
                is_it_related(query)
            )
        
        # Get response from OpenAI API
        response = llm_api.create_chat_completion(messages)
        
        # Add assistant response to conversation history
        conv.add_assistant_message(response)
        
        # Return the response
        return response
        
    except Exception as e:
        # Log the error
        error_msg = f"Error processing query: {e}"
        print(error_msg)
        
        # Provide a graceful error message to the user
        fallback_response = "Sorry, I encountered an error while processing your request. Please try again."
        
        # Don't add error messages to conversation history
        return fallback_response

def reset_conversation(conversation_id="default"):
    """
    Reset the conversation history.
    
    Args:
        conversation_id (str, optional): Identifier for the conversation. Defaults to "default".
    """
    if conversation_id in conversation_instances:
        conversation_instances[conversation_id].clear()
    else:
        conversation_instances[conversation_id] = Conversation()
    
    return "Conversation history has been reset."

def get_conversation_summary(conversation_id="default"):
    """
    Get a summary of the current conversation.
    
    Args:
        conversation_id (str, optional): Identifier for the conversation. Defaults to "default".
    
    Returns:
        str: Summary of the conversation
    """
    if conversation_id in conversation_instances:
        return conversation_instances[conversation_id].summarize()
    else:
        return "Conversation not found."

# This part will only run when the script is executed directly (for testing)
if __name__ == "__main__":
    # Example queries
    print("\n--- IT-Related Query ---")
    test_query = "How do I reset a password?"
    print("Query:", test_query)
    print("Response:", get_answer(test_query))
    
    print("\n--- Similar Query with Different Wording ---")
    test_query2 = "How do I change someone's MS login?"
    print("Query:", test_query2)
    print("Response:", get_answer(test_query2))
    
    print("\n--- General Knowledge Query ---")
    general_query = "What is the capital of France?"
    print("Query:", general_query)
    print("Response:", get_answer(general_query))
    
    print("\n--- Vague IT Query ---")
    vague_query = "Do you know how to do MS stuff?"
    print("Query:", vague_query)
    print("Response:", get_answer(vague_query))
    
    print("\n--- Conversation Summary ---")
    print(get_conversation_summary())
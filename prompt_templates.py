"""
Prompt Templates Module

Contains templates and formatting functions for creating effective prompts
for the LLM based on different scenarios.
"""
import config

# System prompt for the IT support assistant - strict adherence to database info only
SYSTEM_PROMPT = """
You are an IT Support Assistant that ONLY uses information from the provided context.

When responding:
1. ONLY use information explicitly stated in the CONTEXT section
2. If the answer isn't completely contained in the context, say "I don't have enough information about that in my knowledge base"
3. Do not generate or make up any information
4. Do not use any knowledge outside of what's in the CONTEXT
5. Be concise and to the point
6. When citing information, stick strictly to what's provided
7. If asked something not in the context, simply acknowledge that you don't have that information

You MUST NEVER make up or generate information not contained in the CONTEXT.
"""

# System prompt for fallback mode when no relevant docs found - allows general knowledge
FALLBACK_SYSTEM_PROMPT = """
You are an IT Support Assistant with general knowledge capabilities.

Important instructions:
1. You are responding to a query where NO RELEVANT INFORMATION was found in the knowledge base
2. Begin your response with "I don't have specific information about this in my knowledge base, but I can provide a general answer:"
3. After this disclaimer, provide a helpful general response using your built-in knowledge
4. Be concise but informative
5. Be accurate and helpful even when answering from general knowledge
6. If it's a complex technical or domain-specific query that really should have documentation, note that the user might want to add relevant documentation to the knowledge base
"""

def format_context_from_docs(documents):
    """
    Format a list of documents from ChromaDB into a context string for the prompt.
    
    Args:
        documents (list): List of document strings from ChromaDB
    
    Returns:
        str: Formatted context string
    """
    if not documents or (len(documents) == 1 and documents[0] == "No relevant configs found."):
        return "No specific documentation available for this query."
    
    formatted_docs = []
    for i, doc in enumerate(documents, 1):
        formatted_docs.append(f"DOCUMENT {i}:\n{doc.strip()}")
    
    return "\n\n".join(formatted_docs)

def create_support_prompt(query, documents, conversation_history=None):
    """
    Create a complete prompt for the support assistant with context and conversation history.
    Uses strict adherence to provided context.
    
    Args:
        query (str): The user's current question
        documents (list): Relevant documents from ChromaDB
        conversation_history (list, optional): Previous conversation messages
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    # Start with the system message
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT}
    ]
    
    # Format the context from retrieved documents
    context = format_context_from_docs(documents)
    
    # Add context as a system message
    messages.append({
        "role": "system", 
        "content": f"CONTEXT:\n{context}\n\nRespond ONLY based on this information."
    })
    
    # Add conversation history if provided
    if conversation_history and len(conversation_history) > 0:
        # Take only the last N messages based on config
        history = conversation_history[-config.MAX_CONVERSATION_HISTORY:]
        for msg in history:
            messages.append(msg)
    
    # Add the current query
    messages.append({"role": "user", "content": query})
    
    return messages

def create_fallback_prompt(query, conversation_history=None):
    """
    Create a prompt for the fallback mode that allows general knowledge.
    Used when no relevant documents are found in the database.
    
    Args:
        query (str): The user's current question
        conversation_history (list, optional): Previous conversation messages
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    # Start with the fallback system message
    messages = [
        {"role": "system", "content": FALLBACK_SYSTEM_PROMPT}
    ]
    
    # Add conversation history if provided
    if conversation_history and len(conversation_history) > 0:
        # Take only the last N messages based on config
        history = conversation_history[-config.MAX_CONVERSATION_HISTORY:]
        for msg in history:
            messages.append(msg)
    
    # Add the current query
    messages.append({"role": "user", "content": query})
    
    return messages

# Test function
if __name__ == "__main__":
    # Test context formatting
    test_docs = [
        "To add a user to a BDW shared mailbox: Step 1... Step 2...",
        "VPN troubleshooting guide: Step 1..."
    ]
    
    formatted_context = format_context_from_docs(test_docs)
    print("Formatted Context Example:")
    print(formatted_context)
    print("\n" + "-"*50 + "\n")
    
    # Test strict prompt creation
    test_query = "How do I add someone to a shared mailbox?"
    test_messages = create_support_prompt(test_query, test_docs)
    
    print("Strict Prompt Example:")
    for msg in test_messages:
        print(f"[{msg['role']}]")
        print(msg['content'])
        print("-"*30)
    
    # Test fallback prompt creation
    fallback_messages = create_fallback_prompt(test_query)
    
    print("\nFallback Prompt Example:")
    for msg in fallback_messages:
        print(f"[{msg['role']}]")
        print(msg['content'])
        print("-"*30)
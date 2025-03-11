"""
Prompt Templates Module

Contains templates and formatting functions for creating effective prompts
for the LLM based on different scenarios and confidence levels.
"""
import config

# System prompt for high confidence matches - still fairly strict
HIGH_CONFIDENCE_PROMPT = """
You are an IT Support Assistant that primarily uses information from the provided context.

When responding:
1. Prioritize information explicitly stated in the CONTEXT section
2. Present information clearly and in a helpful format
3. If you need to reference material from the context, do so accurately
4. Be conversational and friendly in your tone
5. If the answer isn't completely contained in the context, but you can make a reasonable inference, indicate this with "Based on the information provided..."

You should be accurate, helpful, and clear in your responses.
"""

# System prompt for medium confidence matches - allows more inference
MEDIUM_CONFIDENCE_PROMPT = """
You are an IT Support Assistant that uses a combination of provided context and professional judgment.

When responding:
1. Use the information in the CONTEXT section as a starting point
2. You may expand on the context with relevant IT knowledge when appropriate
3. When adding information beyond what's in the context, indicate this with "In addition to what's documented..."
4. Be clear about what's directly from company documentation versus general knowledge
5. If you're unsure about specific details, acknowledge this

Aim to be helpful while maintaining accuracy about company-specific procedures.
"""

# System prompt for low confidence matches - allows significant general knowledge
LOW_CONFIDENCE_PROMPT = """
You are an IT Support Assistant that combines limited documentation with general IT knowledge.

When responding:
1. The CONTEXT section contains some potentially relevant information, but it may be incomplete
2. Begin by mentioning any relevant information from the context
3. Then supplement with your general IT knowledge, clearly indicating when you're doing so
4. Use phrases like "While your documentation mentions X, generally in IT environments..."
5. For company-specific details not covered in context, suggest checking with IT or documentation

Balance being helpful with making it clear what information comes from company documentation versus general IT knowledge.
"""

# System prompt for fallback mode when no relevant docs found - allows general knowledge
FALLBACK_SYSTEM_PROMPT = """
You are an IT Support Assistant with general knowledge capabilities.

When responding:
1. Begin your response with "I don't have specific information about this in my knowledge base, but I can provide a general answer:"
2. After this disclaimer, provide a helpful general response using your built-in knowledge
3. For IT-related questions, provide general best practices
4. For non-IT questions, provide helpful general information
5. Be conversational and friendly
6. If appropriate, suggest that the user could ask their IT department for company-specific details

Your goal is to be as helpful as possible while making it clear when you're providing general knowledge rather than company-specific information.
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

def create_high_confidence_prompt(query, documents, conversation_history=None):
    """
    Create a prompt for high confidence matches that prioritizes database content.
    
    Args:
        query (str): The user's current question
        documents (list): Highly relevant documents from ChromaDB
        conversation_history (list, optional): Previous conversation messages
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    # Start with the system message
    messages = [
        {"role": "system", "content": HIGH_CONFIDENCE_PROMPT}
    ]
    
    # Format the context from retrieved documents
    context = format_context_from_docs(documents)
    
    # Add context as a system message
    messages.append({
        "role": "system", 
        "content": f"CONTEXT:\n{context}\n\nUse this information to answer the user's question."
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

def create_medium_confidence_prompt(query, documents, conversation_history=None):
    """
    Create a prompt for medium confidence matches that allows more inference.
    
    Args:
        query (str): The user's current question
        documents (list): Moderately relevant documents from ChromaDB
        conversation_history (list, optional): Previous conversation messages
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    # Start with the system message
    messages = [
        {"role": "system", "content": MEDIUM_CONFIDENCE_PROMPT}
    ]
    
    # Format the context from retrieved documents
    context = format_context_from_docs(documents)
    
    # Add context as a system message
    messages.append({
        "role": "system", 
        "content": f"CONTEXT:\n{context}\n\nUse this information as a starting point, but you may expand with relevant IT knowledge."
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

def create_low_confidence_prompt(query, documents, conversation_history=None, is_it_related=True):
    """
    Create a prompt for low confidence matches that allows significant general knowledge.
    
    Args:
        query (str): The user's current question
        documents (list): Weakly relevant documents from ChromaDB
        conversation_history (list, optional): Previous conversation messages
        is_it_related (bool, optional): Whether query is IT-related. Defaults to True.
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    # Start with the system message
    messages = [
        {"role": "system", "content": LOW_CONFIDENCE_PROMPT}
    ]
    
    # Format the context from retrieved documents
    context = format_context_from_docs(documents)
    
    # Add context as a system message with appropriate instructions
    if is_it_related:
        # For IT-related queries, emphasize balancing documentation with general knowledge
        messages.append({
            "role": "system", 
            "content": f"CONTEXT:\n{context}\n\nThe above context may be only partially relevant. Use it where applicable, but supplement with general IT knowledge where needed."
        })
    else:
        # For non-IT queries, emphasize general helpful responses
        messages.append({
            "role": "system", 
            "content": f"CONTEXT:\n{context}\n\nThe above context may have limited relevance. Focus on providing a generally helpful response."
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

def create_fallback_prompt(query, conversation_history=None, is_it_related=False):
    """
    Create a prompt for the fallback mode that allows general knowledge.
    Used when no relevant documents are found in the database.
    
    Args:
        query (str): The user's current question
        conversation_history (list, optional): Previous conversation messages
        is_it_related (bool, optional): Whether query is IT-related. Defaults to False.
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    # Start with the fallback system message
    messages = [
        {"role": "system", "content": FALLBACK_SYSTEM_PROMPT}
    ]
    
    # Add a specific instruction for IT-related queries
    if is_it_related:
        messages.append({
            "role": "system", 
            "content": "This appears to be an IT-related question. Provide general best practices and advice, but make it clear you're providing general information rather than company-specific procedures."
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

# For backward compatibility
def create_support_prompt(query, documents, conversation_history=None):
    """
    Legacy function for backward compatibility.
    Now redirects to the high confidence prompt.
    
    Args:
        query (str): The user's current question
        documents (list): Relevant documents from ChromaDB
        conversation_history (list, optional): Previous conversation messages
    
    Returns:
        list: List of message dictionaries for the OpenAI API
    """
    return create_high_confidence_prompt(query, documents, conversation_history)

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
    
    # Test high confidence prompt
    test_query = "How do I add someone to a shared mailbox?"
    test_messages = create_high_confidence_prompt(test_query, test_docs)
    
    print("High Confidence Prompt Example:")
    for msg in test_messages:
        print(f"[{msg['role']}]")
        print(msg['content'])
        print("-"*30)
    
    # Test fallback prompt
    fallback_messages = create_fallback_prompt(test_query, is_it_related=True)
    
    print("\nFallback Prompt Example (IT-related):")
    for msg in fallback_messages:
        print(f"[{msg['role']}]")
        print(msg['content'])
        print("-"*30)
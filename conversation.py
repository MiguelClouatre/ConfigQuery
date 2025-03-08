"""
Conversation Management Module

Handles tracking conversation history, managing context windows,
and formatting conversations for the LLM API.
"""
import config

class Conversation:
    """
    Class to manage conversation history and formatting.
    """
    
    def __init__(self, max_history=None):
        """
        Initialize a new conversation.
        
        Args:
            max_history (int, optional): Maximum number of messages to keep in history.
                                        Defaults to config.MAX_CONVERSATION_HISTORY.
        """
        self.max_history = max_history or config.MAX_CONVERSATION_HISTORY
        self.messages = []
    
    def add_user_message(self, message):
        """
        Add a user message to the conversation history.
        
        Args:
            message (str): The user's message
        """
        self.messages.append({
            "role": "user",
            "content": message
        })
        
        # Trim history if needed
        self._trim_history()
    
    def add_assistant_message(self, message):
        """
        Add an assistant message to the conversation history.
        
        Args:
            message (str): The assistant's message
        """
        self.messages.append({
            "role": "assistant",
            "content": message
        })
        
        # Trim history if needed
        self._trim_history()
    
    def _trim_history(self):
        """
        Ensure conversation history doesn't exceed the maximum length.
        """
        if len(self.messages) > self.max_history:
            # Remove oldest messages to maintain max_history
            excess = len(self.messages) - self.max_history
            self.messages = self.messages[excess:]
    
    def get_history(self):
        """
        Get the conversation history.
        
        Returns:
            list: List of message dictionaries
        """
        return self.messages.copy()
    
    def clear(self):
        """
        Clear the conversation history.
        """
        self.messages = []
    
    def get_latest_exchange(self):
        """
        Get the most recent user query and assistant response if available.
        
        Returns:
            tuple: (latest_query, latest_response)
        """
        latest_query = None
        latest_response = None
        
        # Find the most recent user message
        for i in range(len(self.messages) - 1, -1, -1):
            if self.messages[i]["role"] == "user":
                latest_query = self.messages[i]["content"]
                break
        
        # Find the most recent assistant message
        for i in range(len(self.messages) - 1, -1, -1):
            if self.messages[i]["role"] == "assistant":
                latest_response = self.messages[i]["content"]
                break
        
        return latest_query, latest_response
    
    def summarize(self, max_chars=500):
        """
        Provide a summary of the conversation (for debugging or logging).
        
        Args:
            max_chars (int, optional): Maximum characters per message in summary.
                                     Defaults to 500.
        
        Returns:
            str: A summary of the conversation
        """
        summary = []
        for msg in self.messages:
            # Truncate long messages for the summary
            content = msg["content"]
            if len(content) > max_chars:
                content = content[:max_chars] + "..."
            
            summary.append(f"{msg['role'].upper()}: {content}")
        
        return "\n\n".join(summary)

# Test the conversation manager
if __name__ == "__main__":
    # Create a new conversation
    conv = Conversation(max_history=5)
    
    # Add some test messages
    conv.add_user_message("Hello, I'm having trouble with my VPN connection.")
    conv.add_assistant_message("I'm sorry to hear that. What specifically is happening with your VPN?")
    conv.add_user_message("It connects but then drops after a few minutes.")
    conv.add_assistant_message("That could be due to several reasons. Do you have a stable internet connection?")
    
    # Print the conversation history
    print("Conversation History:")
    for msg in conv.get_history():
        print(f"[{msg['role']}] {msg['content']}")
    
    # Test summary
    print("\nConversation Summary:")
    print(conv.summarize())
    
    # Test latest exchange
    latest_query, latest_response = conv.get_latest_exchange()
    print("\nLatest Exchange:")
    print(f"Query: {latest_query}")
    print(f"Response: {latest_response}")

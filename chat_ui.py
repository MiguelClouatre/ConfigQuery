from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QUrl, QTimer
import sys
import os
import json
from pathlib import Path
from qa_tool import get_answer, reset_conversation
from document_processor import process_file

# Bridge class to connect Python backend with QML frontend
class ChatBridge(QObject):
    # Signals to send to QML
    newBotMessage = pyqtSignal(str, str, arguments=['message', 'conversationId'])
    updateLoadingState = pyqtSignal(bool, arguments=['isLoading']) 
    conversationReset = pyqtSignal()
    conversationCreated = pyqtSignal(str, str, arguments=['conversationId', 'title'])
    conversationDeleted = pyqtSignal(str, arguments=['conversationId'])
    conversationPinned = pyqtSignal(str, int, arguments=['conversationId', 'pinOrder'])
    conversationUnpinned = pyqtSignal(str, arguments=['conversationId'])
    pinOrderUpdated = pyqtSignal()
    
    def __init__(self):
        QObject.__init__(self)
        self.conversations = {}
        self.active_conversation_id = "default"
        self.pinned_conversations = []  # List of conversation IDs in pin order
        self.load_conversations()
        
        # Create default conversation if none exists
        if "default" not in self.conversations:
            self.conversations["default"] = {
                "title": "New Chat", 
                "messages": [],
                "pinned": False,
                "pinOrder": -1
            }
            self.save_conversations()
    
    # Load saved conversations from file
    def load_conversations(self):
        try:
            conversations_file = Path("conversations.json")
            if conversations_file.exists():
                with open(conversations_file, "r") as f:
                    data = json.load(f)
                    
                    # Check if data is in the new format with properties
                    if isinstance(data, dict):
                        self.conversations = data
                        
                        # Build pinned conversations list from loaded data
                        self.pinned_conversations = []
                        for conv_id, conv_data in self.conversations.items():
                            if conv_data.get("pinned", False):
                                # Add entry with ID and order
                                self.pinned_conversations.append({
                                    "id": conv_id,
                                    "order": conv_data.get("pinOrder", 0)
                                })
                        
                        # Sort the pinned conversations by order
                        self.pinned_conversations.sort(key=lambda x: x["order"])
                
                print(f"Loaded {len(self.conversations)} conversations")
                
                # Emit signals for each conversation to populate the UI
                for conv_id, conv_data in self.conversations.items():
                    self.conversationCreated.emit(conv_id, conv_data.get("title", "New Chat"))
                    
                    # Emit pinned status if applicable
                    if conv_data.get("pinned", False):
                        self.conversationPinned.emit(conv_id, conv_data.get("pinOrder", 0))
            else:
                self.conversations = {
                    "default": {
                        "title": "New Chat", 
                        "messages": [],
                        "pinned": False,
                        "pinOrder": -1
                    }
                }
                self.conversationCreated.emit("default", "New Chat")
                print("No conversations file found, starting fresh")
        except Exception as e:
            print(f"Error loading conversations: {e}")
            self.conversations = {
                "default": {
                    "title": "New Chat", 
                    "messages": [],
                    "pinned": False,
                    "pinOrder": -1
                }
            }
            self.conversationCreated.emit("default", "New Chat")
    
    # Save conversations to file
    def save_conversations(self):
        try:
            with open("conversations.json", "w") as f:
                json.dump(self.conversations, f)
            print(f"Saved {len(self.conversations)} conversations")
        except Exception as e:
            print(f"Error saving conversations: {e}")
    
    # Slot to receive messages from QML
    @pyqtSlot(str, str)
    def sendMessage(self, message, conversation_id):
        if message.strip():
            try:
                # Set loading state to true
                self.updateLoadingState.emit(True)
                
                # Set as active conversation
                self.active_conversation_id = conversation_id
                
                # Get response from your QA tool
                response = get_answer(message, conversation_id)
                
                # Emit the response back to QML
                self.newBotMessage.emit(response, conversation_id)
                
                # Save the conversation
                if conversation_id not in self.conversations:
                    self.conversations[conversation_id] = {
                        "title": "New Chat", 
                        "messages": [],
                        "pinned": False,
                        "pinOrder": -1
                    }
                
                # Make sure messages list exists
                if "messages" not in self.conversations[conversation_id]:
                    self.conversations[conversation_id]["messages"] = []
                    
                # Add messages to conversation history
                self.conversations[conversation_id]["messages"].append({"role": "user", "content": message})
                self.conversations[conversation_id]["messages"].append({"role": "assistant", "content": response})
                
                # Save conversations to disk
                self.save_conversations()
                
            except Exception as e:
                # Handle any errors
                error_message = f"Sorry, I encountered an error: {str(e)}"
                self.newBotMessage.emit(error_message, conversation_id)
            finally:
                # Set loading state back to false
                self.updateLoadingState.emit(False)
    
    # Slot to create a new conversation
    @pyqtSlot(str)
    def createNewConversation(self, conversation_id):
        if conversation_id not in self.conversations:
            self.conversations[conversation_id] = {
                "title": "New Chat", 
                "messages": [],
                "pinned": False,
                "pinOrder": -1
            }
            self.active_conversation_id = conversation_id
            self.conversationCreated.emit(conversation_id, "New Chat")
            self.save_conversations()
            reset_conversation(conversation_id)  # Reset the conversation state in qa_tool
            print(f"Created new conversation: {conversation_id}")
    
    # Slot to rename a conversation
    @pyqtSlot(str, str)
    def renameConversation(self, conversation_id, new_title):
        if conversation_id in self.conversations:
            self.conversations[conversation_id]["title"] = new_title
            self.save_conversations()
            print(f"Renamed conversation {conversation_id} to '{new_title}'")
    
    # Slot to pin a conversation
    @pyqtSlot(str)
    def pinConversation(self, conversation_id):
        if conversation_id in self.conversations:
            # Set as pinned
            self.conversations[conversation_id]["pinned"] = True
            
            # Assign pin order (higher numbers are lower in the list)
            pin_order = len(self.pinned_conversations)
            self.conversations[conversation_id]["pinOrder"] = pin_order
            
            # Add to pinned list
            self.pinned_conversations.append({
                "id": conversation_id,
                "order": pin_order
            })
            
            # Save and notify UI
            self.save_conversations()
            self.conversationPinned.emit(conversation_id, pin_order)
            print(f"Pinned conversation: {conversation_id}")
    
    # Slot to unpin a conversation
    @pyqtSlot(str)
    def unpinConversation(self, conversation_id):
        if conversation_id in self.conversations:
            # Remove pin status
            self.conversations[conversation_id]["pinned"] = False
            self.conversations[conversation_id]["pinOrder"] = -1
            
            # Remove from pinned list
            self.pinned_conversations = [p for p in self.pinned_conversations if p["id"] != conversation_id]
            
            # Reorder remaining pinned conversations
            for i, item in enumerate(self.pinned_conversations):
                self.conversations[item["id"]]["pinOrder"] = i
                item["order"] = i
            
            # Save and notify UI
            self.save_conversations()
            self.conversationUnpinned.emit(conversation_id)
            print(f"Unpinned conversation: {conversation_id}")
    
    # Slot to update the order of pinned conversations
    @pyqtSlot(str)
    def updatePinOrder(self, pin_order_json):
        try:
            # Parse the JSON string to get the ordered list of conversation IDs
            pin_order = json.loads(pin_order_json)
            
            # Reset pinned conversations list
            self.pinned_conversations = []
            
            # Update the ordering in both lists
            for i, conv_id in enumerate(pin_order):
                if conv_id in self.conversations:
                    # Update pinOrder in conversation data
                    self.conversations[conv_id]["pinOrder"] = i
                    
                    # Add to ordered list
                    self.pinned_conversations.append({
                        "id": conv_id,
                        "order": i
                    })
            
            # Save changes
            self.save_conversations()
            
            # Notify UI
            self.pinOrderUpdated.emit()
            
            print(f"Updated pin order: {pin_order}")
        except Exception as e:
            print(f"Error updating pin order: {e}")
    
    # Slot to delete a conversation
    @pyqtSlot(str)
    def deleteConversation(self, conversation_id):
        if conversation_id in self.conversations:
            # Check if pinned
            if self.conversations[conversation_id].get("pinned", False):
                # Remove from pinned list
                self.pinned_conversations = [p for p in self.pinned_conversations if p["id"] != conversation_id]
                
                # Reorder remaining pinned conversations
                for i, item in enumerate(self.pinned_conversations):
                    self.conversations[item["id"]]["pinOrder"] = i
                    item["order"] = i
            
            # Remove from conversations dict
            del self.conversations[conversation_id]
            
            # Save and notify UI
            self.save_conversations()
            self.conversationDeleted.emit(conversation_id)
            print(f"Deleted conversation: {conversation_id}")
    
    # Slot to switch between conversations
    @pyqtSlot(str)
    def switchConversation(self, conversation_id):
        if conversation_id in self.conversations:
            self.active_conversation_id = conversation_id
            reset_conversation(conversation_id)  # Reset the conversation state in qa_tool
            
            # Rebuild conversation history in qa_tool
            print(f"Switched to conversation: {conversation_id}")
    
    # Slot to handle the upload button click - opens file dialog directly
    @pyqtSlot()
    def openFileDialog(self):
        # Use a timer to ensure we don't block the UI thread
        # This runs in the main thread but after the current event is processed
        QTimer.singleShot(0, self._show_file_dialog)
    
    def _show_file_dialog(self):
        try:
            # Using tkinter for file dialog (works without QApplication)
            import tkinter as tk
            from tkinter import filedialog
            
            # Create and hide the main tkinter window
            root = tk.Tk()
            root.withdraw()
            
            # Make sure the window is at the front
            root.attributes('-topmost', True)
            
            # Open the file dialog with multiple selection enabled
            file_paths = filedialog.askopenfilenames(
                title="Select documents to upload",
                filetypes=[
                    ("Supported files", "*.txt *.pdf *.docx *.doc"),
                    ("Text files", "*.txt"),
                    ("PDF files", "*.pdf"),
                    ("Word documents", "*.docx *.doc"),
                    ("All files", "*.*")
                ],
                multiple=True  # Allow multiple file selection
            )
            
            # Destroy the tkinter window
            root.destroy()
            
            # Process the selected files if any were chosen
            if file_paths and len(file_paths) > 0:
                # Set loading state
                self.updateLoadingState.emit(True)
                
                # Process each file
                processed_count = 0
                failed_count = 0
                
                for file_path in file_paths:
                    try:
                        # Process the document
                        result = process_file(file_path)
                        
                        if result["success"]:
                            processed_count += 1
                            print(f"Document processed: {result['filename']} ({result['chunks']} chunks)")
                        else:
                            failed_count += 1
                            print(f"Failed to process document: {result['error']}")
                    except Exception as e:
                        failed_count += 1
                        print(f"Error processing file {file_path}: {str(e)}")
                
                # Print summary to console
                print(f"Processing complete: {processed_count} files added, {failed_count} failed")
                    
                # Done loading
                self.updateLoadingState.emit(False)
                
        except Exception as e:
            print(f"Error in file dialog: {str(e)}")
            self.updateLoadingState.emit(False)
    
    # Slot to reset the conversation
    @pyqtSlot()
    def resetConversation(self):
        try:
            # Reset the conversation in qa_tool
            reset_conversation(self.active_conversation_id)
            
            # Clear the current conversation history
            if self.active_conversation_id in self.conversations:
                # Keep the title and pin status but clear messages
                title = self.conversations[self.active_conversation_id].get("title", "New Chat")
                pinned = self.conversations[self.active_conversation_id].get("pinned", False)
                pin_order = self.conversations[self.active_conversation_id].get("pinOrder", -1)
                
                self.conversations[self.active_conversation_id] = {
                    "title": title, 
                    "messages": [],
                    "pinned": pinned,
                    "pinOrder": pin_order
                }
                self.save_conversations()
            
            # Notify QML that conversation was reset
            self.conversationReset.emit()
        except Exception as e:
            # Just log the error, don't show a message in the chat
            print(f"Failed to reset conversation: {str(e)}")

# Main application
if __name__ == "__main__":
    # Create the application and engine
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    # Create bridge instance and make it available to QML
    bridge = ChatBridge()
    engine.rootContext().setContextProperty("chatBridge", bridge)
    
    # Load the main QML file
    qml_path = os.path.join(os.path.dirname(__file__), "qml", "main.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    
    # Exit if QML failed to load
    if not engine.rootObjects():
        sys.exit(-1)
    
    # Run the application
    sys.exit(app.exec())
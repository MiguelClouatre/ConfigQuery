from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QUrl, QTimer
import sys
import os
from pathlib import Path
from qa_tool import get_answer, reset_conversation
from document_processor import process_file

# Bridge class to connect Python backend with QML frontend
class ChatBridge(QObject):
    # Signals to send to QML
    newBotMessage = pyqtSignal(str, arguments=['message'])
    updateLoadingState = pyqtSignal(bool, arguments=['isLoading']) 
    conversationReset = pyqtSignal()
    
    def __init__(self):
        QObject.__init__(self)
    
    # Slot to receive messages from QML
    @pyqtSlot(str)
    def sendMessage(self, message):
        if message.strip():
            try:
                # Set loading state to true
                self.updateLoadingState.emit(True)
                
                # Get response from your QA tool
                response = get_answer(message)
                
                # Emit the response back to QML
                self.newBotMessage.emit(response)
            except Exception as e:
                # Handle any errors
                error_message = f"Sorry, I encountered an error: {str(e)}"
                self.newBotMessage.emit(error_message)
            finally:
                # Set loading state back to false
                self.updateLoadingState.emit(False)
    
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
            reset_conversation()
            
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
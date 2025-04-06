import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "Utils.js" as Utils
import "./"

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    title: "QA Chatbot"
    color: "#1E1E1E"
    
    // Global properties
    property bool isLoading: false
    property string activeConversationId: "default"
    property var conversations: {"default": {title: "New Chat", messages: []}}
    property string editingConversationId: ""
    property int currentSidebarTab: 0  // 0 = Main, 1 = Favorites
    
    // Debug logging
    function logDebug(message) {
        Utils.log("MainWindow", message);
    }
    
    Component.onCompleted: {
        logDebug("Application window initialized");
        logDebug("Initial state - activeConversationId: " + activeConversationId);
        logDebug("Initial conversations: " + JSON.stringify(Object.keys(conversations)));
        
        // Make sure default conversation is properly set up
        if (conversations["default"]) {
            // Notify sidebar to add the default conversation at init time
            logDebug("Adding default conversation to sidebar");
            chatBridge.conversationCreated("default", conversations["default"].title || "New Chat");
        }
    }
    
    // Options popup for conversation menu
    OptionsPopup {
        id: optionsPopup
        debug: true
        
        onPopupHidden: {
            outsideClickArea.visible = false;
            logDebug("Popup hidden");
        }
        
        onPinClicked: function(convId, isPinned) {
            logDebug("Pin clicked: " + convId + " (isPinned: " + isPinned + ")");
            if (isPinned) {
                chatBridge.unpinConversation(convId);
            } else {
                chatBridge.pinConversation(convId);
            }
        }
        
        onRenameClicked: function(convId) {
            logDebug("Rename clicked in options popup: " + convId);
            
            // Instead of setting editingConversationId property, directly activate edit mode
            var success = sidebarView.editConversation(convId);
            logDebug("Direct edit activation result: " + success);
        }
        
        onDeleteClicked: function(convId) {
            logDebug("Delete clicked: " + convId);
            chatBridge.deleteConversation(convId);
        }
    }
    
    // Mouse area for clicking outside the options popup
    MouseArea {
        id: outsideClickArea
        anchors.fill: parent
        visible: false
        z: 99
        onClicked: {
            logDebug("Outside area clicked");
            optionsPopup.visible = false;
            optionsPopup.popupHidden();
        }
    }
    
    // Main layout
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Sidebar on the left
        SidebarView {
            id: sidebarView
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            debug: true
            activeConversationId: window.activeConversationId
            editingConversationId: window.editingConversationId
            currentSidebarTab: window.currentSidebarTab
            
            onCurrentSidebarTabChanged: {
                window.currentSidebarTab = currentSidebarTab;
                logDebug("Tab changed to: " + currentSidebarTab);
            }
            
            onConversationSelected: function(convId) {
                logDebug("Conversation selected: " + convId);
                
                // Clear editing state when selecting a conversation
                if (editingConversationId !== "") {
                    logDebug("Clearing editing state on conversation selection");
                    editingConversationId = "";
                }
                
                if (activeConversationId !== convId) {
                    activeConversationId = convId;
                    logDebug("Set activeConversationId to: " + activeConversationId);
                    
                    // Load messages for this conversation
                    logDebug("Loading messages for conversation: " + convId);
                    chatView.clearChat();
                    if (conversations[convId] && conversations[convId].messages) {
                        chatView.loadMessages(conversations[convId].messages);
                        logDebug("Loaded " + conversations[convId].messages.length + " messages");
                    } else {
                        logDebug("No messages found for conversation: " + convId);
                    }
                    
                    chatBridge.switchConversation(convId);
                }
            }
            
            onCreateNewConversation: {
                var newId = Utils.generateConversationId();
                logDebug("Creating new conversation: " + newId);
                
                // Create conversation in local model
                conversations[newId] = {title: "New Chat", messages: []};
                logDebug("Added to local conversations object");
                
                activeConversationId = newId;
                logDebug("Set activeConversationId to: " + activeConversationId);
                
                // Clear the chat view
                chatView.clearChat();
                logDebug("Cleared chat view");
                
                // Inform backend - this will trigger onConversationCreated which adds to sidebar
                chatBridge.createNewConversation(newId);
                
                // Switch to Main tab when creating a new conversation
                currentSidebarTab = 0;
                logDebug("Switched to Main tab");
            }
            
            onPinConversation: function(convId) {
                logDebug("Pin conversation: " + convId);
                chatBridge.pinConversation(convId);
            }
            
            onUnpinConversation: function(convId) {
                logDebug("Unpin conversation: " + convId);
                chatBridge.unpinConversation(convId);
            }
            
            onRenameConversation: function(convId, newTitle) {
                logDebug("Rename conversation: " + convId + " to: " + newTitle);
                
                // Update in our local data
                if (conversations[convId]) {
                    var oldTitle = conversations[convId].title;
                    conversations[convId].title = newTitle;
                    logDebug("Updated title in conversations object: '" + oldTitle + "' → '" + newTitle + "'");
                } else {
                    logDebug("Warning: Conversation not found in local data: " + convId);
                }
                
                // Update in bridge
                chatBridge.renameConversation(convId, newTitle);
                logDebug("Sent rename command to chatBridge");
                
                // Clear editing state
                editingConversationId = "";
                logDebug("Cleared editingConversationId");
                
                // Explicitly update the conversation title in UI
                sidebarView.updateConversationTitle(convId, newTitle);
                logDebug("Called updateConversationTitle on sidebar");
                
                // Force refresh after renaming
                sidebarView.forceRefresh();
                logDebug("Forced UI refresh after rename");
            }
            
            onMenuClicked: function(convId, title, isPinned, x, y) {
                logDebug("Menu clicked for: " + convId);
                optionsPopup.showPopup(convId, title, isPinned, x, y);
                outsideClickArea.visible = true;
            }
        }
        
        // Chat view on the right
        ChatView {
            id: chatView
            Layout.fillWidth: true
            Layout.fillHeight: true
            debug: true
            isLoading: window.isLoading
            activeConversationId: window.activeConversationId
            
            onSendMessage: function(message, conversationId) {
                logDebug("Sending message: " + message + " for conversation: " + conversationId);
                
                // Add to local conversations store
                if (!conversations[conversationId]) {
                    logDebug("Creating new conversation entry for: " + conversationId);
                    conversations[conversationId] = {title: "New Chat", messages: []};
                }
                
                var userMessage = {
                    "message": message,
                    "isUser": true
                };
                
                conversations[conversationId].messages.push(userMessage);
                logDebug("Added user message to conversations object");
                
                // If this is the first message, use it as the conversation title
                if (conversations[conversationId].messages.length === 1) {
                    logDebug("First message, creating title from message");
                    var newTitle = Utils.formatConversationTitle(message);
                    var oldTitle = conversations[conversationId].title;
                    conversations[conversationId].title = newTitle;
                    logDebug("Set title in conversations object: '" + oldTitle + "' → '" + newTitle + "'");
                    
                    // Update in the model and UI
                    sidebarView.updateConversationTitle(conversationId, newTitle);
                    logDebug("Updated title in sidebar");
                    
                    // Also update through bridge to ensure persistence
                    chatBridge.renameConversation(conversationId, newTitle);
                    logDebug("Sent rename to chatBridge");
                    
                    // Force UI refresh
                    sidebarView.forceRefresh();
                    logDebug("Forced UI refresh after title update");
                }
                
                // Send to the backend
                chatBridge.sendMessage(message, conversationId);
                logDebug("Sent message to chatBridge");
            }
            
            onResetConversation: {
                logDebug("Resetting conversation");
                chatBridge.resetConversation();
            }
            
            onUploadDocument: {
                logDebug("Opening file dialog");
                chatBridge.openFileDialog();
            }
        }
    }
    
    // Connections to handle events from ChatBridge
    Connections {
        target: chatBridge
        
        function onNewBotMessage(message, conversationId) {
            logDebug("New bot message for conversation: " + conversationId);
            
            if (conversationId === activeConversationId) {
                chatView.addBotMessage(message);
                logDebug("Added to chat view");
            }
            
            if (!conversations[conversationId]) {
                logDebug("Creating new conversation entry for bot message: " + conversationId);
                conversations[conversationId] = {title: "New Chat", messages: []};
            }
            
            conversations[conversationId].messages.push({
                "message": message,
                "isUser": false
            });
            logDebug("Added bot message to conversations object");
        }
        
        function onUpdateLoadingState(loading) {
            logDebug("Loading state changed: " + loading);
            isLoading = loading;
        }
        
        function onConversationReset() {
            logDebug("Conversation reset for: " + activeConversationId);
            
            chatView.clearChat();
            if (conversations[activeConversationId]) {
                conversations[activeConversationId].messages = [];
                logDebug("Cleared messages in conversations object");
            } else {
                logDebug("Warning: Active conversation not found in local data: " + activeConversationId);
            }
        }
        
        function onConversationCreated(conversationId, title) {
            logDebug("Conversation created: " + conversationId + " with title: " + title);
            
            // Create in local model if needed
            if (!conversations[conversationId]) {
                logDebug("Adding to local conversations object");
                conversations[conversationId] = {
                    title: title || "New Chat",
                    messages: []
                };
            } else {
                logDebug("Conversation already exists in local data");
            }
            
            // Check if already exists in UI
            var result = sidebarView.findConversation(conversationId);
            if (result !== null) {
                logDebug("Conversation already exists in UI, not adding again");
                return;  // Already exists
            }
            
            logDebug("Adding conversation to sidebar");
            // Add to main conversations list in sidebar
            sidebarView.addMainConversation(
                conversationId,
                conversations[conversationId].title || title || "New Chat",
                false,
                -1
            );
        }
        
        function onAddToFavorites(conversationId, title, pinOrder) {
            logDebug("Adding to favorites: " + conversationId + " with title: " + title);
            
            // Update local data
            if (conversations[conversationId]) {
                conversations[conversationId].pinned = true;
                conversations[conversationId].pinOrder = pinOrder;
                logDebug("Updated pinned state in conversations object");
            } else {
                logDebug("Warning: Conversation not found in local data: " + conversationId);
            }
            
            // Remove from main if present
            sidebarView.removeConversation(conversationId);
            
            // Add to favorites
            sidebarView.addFavoriteConversation(
                conversationId,
                conversations[conversationId]?.title || title || "New Chat",
                true,
                pinOrder
            );
            
            // Switch tab if this is active conversation
            if (activeConversationId === conversationId) {
                logDebug("Active conversation pinned, switching to Favorites tab");
                currentSidebarTab = 1;  // Switch to Favorites tab
            }
        }
        
        function onRemoveFromFavorites(conversationId) {
            logDebug("Removing from favorites: " + conversationId);
            
            // Update local data
            if (conversations[conversationId]) {
                conversations[conversationId].pinned = false;
                conversations[conversationId].pinOrder = -1;
                logDebug("Updated pinned state in conversations object");
            } else {
                logDebug("Warning: Conversation not found in local data: " + conversationId);
            }
            
            // Remove from favorites list
            sidebarView.removeConversation(conversationId);
            
            // Add to main conversations
            var title = conversations[conversationId]?.title || "New Chat";
            sidebarView.addMainConversation(
                conversationId,
                title,
                false,
                -1
            );
            
            // Switch tab if this is active conversation
            if (activeConversationId === conversationId) {
                logDebug("Active conversation unpinned, switching to Main tab");
                currentSidebarTab = 0;  // Switch to Main tab
            }
        }
        
        function onConversationPinned(conversationId, pinOrder) {
            logDebug("Conversation pinned: " + conversationId + " (backward compatibility)");
            // This is now handled by onAddToFavorites
        }
        
        function onConversationUnpinned(conversationId) {
            logDebug("Conversation unpinned: " + conversationId + " (backward compatibility)");
            // This is now handled by onRemoveFromFavorites
        }
        
        function onConversationDeleted(conversationId) {
            logDebug("Conversation deleted: " + conversationId);
            
            // Remove from view
            sidebarView.removeConversation(conversationId);
            
            // Remove from data store
            if (conversations[conversationId]) {
                delete conversations[conversationId];
                logDebug("Removed from conversations object");
            } else {
                logDebug("Warning: Conversation not found in local data: " + conversationId);
            }
            
            // Handle case when active conversation is deleted
            if (activeConversationId === conversationId) {
                logDebug("Active conversation was deleted, finding new conversation to activate");
                
                // Find any conversation to make active
                var result = sidebarView.findConversation(null);  // Will find first in main
                
                if (result) {
                    var newActiveId = result.model.get(result.index).convId;
                    activeConversationId = newActiveId;
                    logDebug("Set new activeConversationId to: " + activeConversationId);
                    
                    chatView.clearChat();
                    logDebug("Cleared chat view");
                    
                    if (conversations[activeConversationId]?.messages) {
                        chatView.loadMessages(conversations[activeConversationId].messages);
                        logDebug("Loaded " + conversations[activeConversationId].messages.length + " messages");
                    }
                    
                    chatBridge.switchConversation(activeConversationId);
                } else {
                    logDebug("No conversations found, creating default conversation");
                    // No conversations left, create default
                    chatBridge.createNewConversation("default");
                    activeConversationId = "default";
                    chatView.clearChat();
                    currentSidebarTab = 0;
                }
            }
        }
    }
}
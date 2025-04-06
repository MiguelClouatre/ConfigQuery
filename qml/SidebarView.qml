import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./"

Rectangle {
    id: sidebarView
    color: "#252525"
    
    // Debug property
    property bool debug: true
    
    // Required properties
    property string activeConversationId: "default"
    property string editingConversationId: ""
    property int currentSidebarTab: 0  // 0 = Main, 1 = Favorites
    
    // Store references to conversation items for direct access
    property var conversationItems: ({})
    
    // Signals
    signal conversationSelected(string convId)
    signal createNewConversation()
    signal pinConversation(string convId)
    signal unpinConversation(string convId)
    signal renameConversation(string convId, string newTitle)
    signal deleteConversation(string convId)
    signal menuClicked(string convId, string title, bool isPinned, real x, real y)
    
    // Debug function
    function logDebug(message) {
        if (debug) {
            console.log("SidebarView: " + message);
        }
    }
    
    Component.onCompleted: {
        logDebug("Component created");
        logDebug("Initial state - activeConversationId: " + activeConversationId);
        logDebug("Initial state - editingConversationId: " + editingConversationId);
        logDebug("Initial state - currentSidebarTab: " + currentSidebarTab);
    }
    
    // Function to register a conversation item
    function registerConversationItem(convId, item) {
        conversationItems[convId] = item;
        logDebug("Registered conversation item: " + convId);
    }
    
    // Function to unregister a conversation item
    function unregisterConversationItem(convId) {
        if (conversationItems[convId]) {
            delete conversationItems[convId];
            logDebug("Unregistered conversation item: " + convId);
        }
    }
    
    // Direct function to put a conversation into edit mode
    function editConversation(convId) {
        logDebug("Directly activating edit mode for: " + convId);
        
        // First check if we have a reference to the item
        if (conversationItems[convId]) {
            // Call the direct method on the item
            logDebug("Found item, calling activateEditMode");
            conversationItems[convId].activateEditMode();
            return true;
        } else {
            logDebug("No item found for conversation: " + convId);
            return false;
        }
    }
    
    // Function to force refresh lists
    function forceRefresh() {
        mainConversationList.forceLayout();
        favoritesConversationList.forceLayout();
        logDebug("Forced refresh of conversation lists");
    }
    
    // Header with tabs
    Rectangle {
        id: sidebarHeader
        width: parent.width
        height: 50
        color: "#333333"
        
        // Tabs for Main and Favorites
        Item {
            anchors.fill: parent
            
            Rectangle {
                id: mainTab
                width: parent.width / 2
                height: parent.height
                color: currentSidebarTab === 0 ? "#3C3C3C" : "transparent"
                radius: 8
                
                // Remove radius on the right side
                Rectangle {
                    width: parent.radius
                    height: parent.radius
                    anchors.right: parent.right
                    anchors.top: parent.top
                    color: currentSidebarTab === 0 ? "#3C3C3C" : "#333333"
                }
                
                Rectangle {
                    width: parent.radius
                    height: parent.radius
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: currentSidebarTab === 0 ? "#3C3C3C" : "#333333"
                }
                
                Text {
                    text: "Main"
                    color: "white"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        logDebug("Main tab clicked");
                        currentSidebarTab = 0;
                    }
                }
            }
            
            Rectangle {
                id: favoritesTab
                width: parent.width / 2
                height: parent.height
                anchors.right: parent.right
                color: currentSidebarTab === 1 ? "#3C3C3C" : "transparent"
                radius: 8
                
                // Remove radius on the left side
                Rectangle {
                    width: parent.radius
                    height: parent.radius
                    anchors.left: parent.left
                    anchors.top: parent.top
                    color: currentSidebarTab === 1 ? "#3C3C3C" : "#333333"
                }
                
                Rectangle {
                    width: parent.radius
                    height: parent.radius
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    color: currentSidebarTab === 1 ? "#3C3C3C" : "#333333"
                }
                
                Text {
                    text: "Favorites"
                    color: "white"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        logDebug("Favorites tab clicked");
                        currentSidebarTab = 1;
                    }
                }
            }
        }
    }
    
    // Main content area with ListView or Favorites ListView
    Item {
        id: contentArea
        anchors.top: sidebarHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: sidebarFooter.top
        anchors.margins: 5
        
        // Main tab content - regular conversations
        ListView {
            id: mainConversationList
            anchors.fill: parent
            clip: true
            spacing: 5
            visible: currentSidebarTab === 0
            cacheBuffer: 100 // Increase cache buffer to reduce repaints
            
            model: ListModel { id: mainConversationsModel }
            
            delegate: ConversationItem {
                convId: model.convId
                title: model.title
                pinned: model.pinned
                pinOrder: model.pinOrder
                activeConversationId: sidebarView.activeConversationId
                editingConversationId: sidebarView.editingConversationId
                
                Component.onCompleted: {
                    // Register this item with the sidebar
                    sidebarView.registerConversationItem(convId, this);
                }
                
                Component.onDestruction: {
                    // Unregister when destroyed
                    sidebarView.unregisterConversationItem(convId);
                }
                
                onConversationSelected: function(convId) {
                    sidebarView.conversationSelected(convId);
                }
                
                onPinClicked: function(convId, isPinned) {
                    if (isPinned) {
                        sidebarView.unpinConversation(convId);
                    } else {
                        sidebarView.pinConversation(convId);
                    }
                }
                
                onMenuClicked: function(convId, title, isPinned, x, y) {
                    sidebarView.menuClicked(convId, title, isPinned, x, y);
                }
                
                onTitleEdited: function(convId, newTitle) {
                    logDebug("TitleEdited signal received from ConversationItem: " + convId + " - " + newTitle);
                    if (newTitle !== "") {
                        logDebug("Forwarding rename command to main");
                        sidebarView.renameConversation(convId, newTitle);
                    } else {
                        // Cancel editing without saving
                        logDebug("Empty title received, cancelling edit mode");
                        sidebarView.editingConversationId = "";
                    }
                }
            }
            
            // Empty state message
            Item {
                anchors.fill: parent
                visible: mainConversationsModel.count === 0 && currentSidebarTab === 0
                
                Text {
                    anchors.centerIn: parent
                    text: "No conversations yet"
                    color: "#888888"
                    font.pixelSize: 14
                }
            }
        }
        
        // Favorites tab content - pinned conversations
        ListView {
            id: favoritesConversationList
            anchors.fill: parent
            clip: true
            spacing: 5
            visible: currentSidebarTab === 1
            cacheBuffer: 100 // Increase cache buffer to reduce repaints
            
            model: ListModel { id: favoritesConversationsModel }
            
            delegate: ConversationItem {
                convId: model.convId
                title: model.title
                pinned: model.pinned
                pinOrder: model.pinOrder
                activeConversationId: sidebarView.activeConversationId
                editingConversationId: sidebarView.editingConversationId
                
                Component.onCompleted: {
                    // Register this item with the sidebar
                    sidebarView.registerConversationItem(convId, this);
                }
                
                Component.onDestruction: {
                    // Unregister when destroyed
                    sidebarView.unregisterConversationItem(convId);
                }
                
                onConversationSelected: function(convId) {
                    sidebarView.conversationSelected(convId);
                }
                
                onPinClicked: function(convId, isPinned) {
                    if (isPinned) {
                        sidebarView.unpinConversation(convId);
                    } else {
                        sidebarView.pinConversation(convId);
                    }
                }
                
                onMenuClicked: function(convId, title, isPinned, x, y) {
                    sidebarView.menuClicked(convId, title, isPinned, x, y);
                }
                
                onTitleEdited: function(convId, newTitle) {
                    logDebug("TitleEdited signal received from ConversationItem in favorites: " + convId + " - " + newTitle);
                    if (newTitle !== "") {
                        logDebug("Forwarding rename command to main");
                        sidebarView.renameConversation(convId, newTitle);
                    } else {
                        // Cancel editing without saving
                        logDebug("Empty title received, cancelling edit mode");
                        sidebarView.editingConversationId = "";
                    }
                }
            }
            
            // Empty state message
            Item {
                anchors.fill: parent
                visible: favoritesConversationsModel.count === 0 && currentSidebarTab === 1
                
                Text {
                    anchors.centerIn: parent
                    text: "No favorites yet"
                    color: "#888888"
                    font.pixelSize: 14
                }
            }
        }
    }
    
    // Footer with New Chat button
    Rectangle {
        id: sidebarFooter
        width: parent.width
        height: 50
        color: "#252525"
        anchors.bottom: parent.bottom
        
        // New Chat button
        Button {
            text: "New Chat"
            width: parent.width - 20
            height: 36
            anchors.centerIn: parent
            
            background: Rectangle {
                color: "#007ACC"
                radius: 5
            }
            
            contentItem: Text {
                text: parent.text
                color: "white"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                logDebug("New Chat button clicked");
                sidebarView.createNewConversation();
            }
        }
    }
    
    // Methods to update the list models
    function addMainConversation(convId, title, pinned, pinOrder) {
        logDebug("Adding to main: " + convId + " - " + title);
        
        // Check if it already exists before adding
        for (var i = 0; i < mainConversationsModel.count; i++) {
            if (mainConversationsModel.get(i).convId === convId) {
                logDebug("Conversation already exists in main, not adding: " + convId);
                return;
            }
        }
        
        mainConversationsModel.append({
            convId: convId, 
            title: title || "New Chat", 
            pinned: pinned, 
            pinOrder: pinOrder
        });
        logDebug("Added to main: " + convId + " with title: " + title);
        forceRefresh();
    }
    
    function addFavoriteConversation(convId, title, pinned, pinOrder) {
        logDebug("Adding to favorites: " + convId + " - " + title);
        
        // Check if it already exists before adding
        for (var i = 0; i < favoritesConversationsModel.count; i++) {
            if (favoritesConversationsModel.get(i).convId === convId) {
                logDebug("Conversation already exists in favorites, not adding: " + convId);
                return;
            }
        }
        
        favoritesConversationsModel.append({
            convId: convId, 
            title: title || "New Chat", 
            pinned: pinned, 
            pinOrder: pinOrder
        });
        logDebug("Added to favorites: " + convId + " with title: " + title);
        forceRefresh();
    }
    
    function removeConversation(convId) {
        logDebug("Removing conversation: " + convId);
        
        // Try to remove from Main list
        for (var i = 0; i < mainConversationsModel.count; i++) {
            if (mainConversationsModel.get(i).convId === convId) {
                mainConversationsModel.remove(i);
                logDebug("Removed from main: " + convId);
                forceRefresh();
                return;
            }
        }
        
        // Try to remove from Favorites list
        for (var j = 0; j < favoritesConversationsModel.count; j++) {
            if (favoritesConversationsModel.get(j).convId === convId) {
                favoritesConversationsModel.remove(j);
                logDebug("Removed from favorites: " + convId);
                forceRefresh();
                return;
            }
        }
        
        logDebug("Conversation not found to remove: " + convId);
    }
    
    function updateConversationTitle(convId, newTitle) {
        logDebug("Updating title for: " + convId + " to: " + newTitle);
        
        if (!newTitle) {
            logDebug("Empty title provided, ignoring update");
            return;
        }
        
        // Try to update in Main list
        var foundInMain = false;
        for (var i = 0; i < mainConversationsModel.count; i++) {
            if (mainConversationsModel.get(i).convId === convId) {
                var oldTitle = mainConversationsModel.get(i).title;
                mainConversationsModel.setProperty(i, "title", newTitle);
                logDebug("Updated title in main from '" + oldTitle + "' to '" + newTitle + "' for: " + convId);
                foundInMain = true;
                forceRefresh();
                break;
            }
        }
        
        // Try to update in Favorites list if not found in main
        if (!foundInMain) {
            for (var j = 0; j < favoritesConversationsModel.count; j++) {
                if (favoritesConversationsModel.get(j).convId === convId) {
                    var oldFavTitle = favoritesConversationsModel.get(j).title;
                    favoritesConversationsModel.setProperty(j, "title", newTitle);
                    logDebug("Updated title in favorites from '" + oldFavTitle + "' to '" + newTitle + "' for: " + convId);
                    forceRefresh();
                    return;
                }
            }
            
            // If we get here, conversation not found in either list
            logDebug("Warning: Could not find conversation to update title: " + convId);
        }
    }
    
    function findConversation(convId) {
        logDebug("Finding conversation: " + convId);
        
        // If convId is null, return the first available conversation
        if (convId === null) {
            if (mainConversationsModel.count > 0) {
                logDebug("Returning first conversation from main list");
                return { model: mainConversationsModel, index: 0 };
            } else if (favoritesConversationsModel.count > 0) {
                logDebug("Returning first conversation from favorites list");
                return { model: favoritesConversationsModel, index: 0 };
            }
            logDebug("No conversations found");
            return null;
        }
        
        // Try to find in Main list
        for (var i = 0; i < mainConversationsModel.count; i++) {
            if (mainConversationsModel.get(i).convId === convId) {
                logDebug("Found in main list at index: " + i);
                return { model: mainConversationsModel, index: i };
            }
        }
        
        // Try to find in Favorites list
        for (var j = 0; j < favoritesConversationsModel.count; j++) {
            if (favoritesConversationsModel.get(j).convId === convId) {
                logDebug("Found in favorites list at index: " + j);
                return { model: favoritesConversationsModel, index: j };
            }
        }
        
        logDebug("Conversation not found: " + convId);
        return null;
    }
}
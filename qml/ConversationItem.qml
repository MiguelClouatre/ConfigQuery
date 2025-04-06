import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: ListView.view.width
    height: 50
    color: activeConversationId === convId ? "#3C3C3C" : "#252525"
    radius: 5
    
    // Debug property
    property bool debug: true
    
    // Required properties
    property string convId: ""
    property string title: ""
    property bool pinned: false
    property int pinOrder: -1
    property string activeConversationId: ""
    property string editingConversationId: ""
    
    // Internal property to track edit mode
    property bool isInEditMode: false
    
    // Signals
    signal conversationSelected(string convId)
    signal pinClicked(string convId, bool isPinned)
    signal menuClicked(string convId, string title, bool isPinned, real x, real y)
    signal titleEdited(string convId, string newTitle)
    
    // Debug function
    function logDebug(message) {
        if (debug) {
            console.log("ConversationItem: " + message);
        }
    }
    
    // Direct method to activate edit mode - this is called directly from SidebarView
    function activateEditMode() {
        if (isInEditMode) {
            logDebug("Already in edit mode: " + convId);
            return;
        }
        
        // Set internal state
        isInEditMode = true;
        logDebug("Edit mode activated for: " + convId);
        
        // Update UI elements
        titleText.visible = false;
        titleEditField.visible = true;
        titleEditField.text = root.title || "New Chat";
        
        // Add a small delay to ensure the UI has updated before focusing
        focusTimer.start();
    }
    
    // Function to exit edit mode without saving
    function cancelEdit() {
        if (!isInEditMode) {
            return;
        }
        
        logDebug("Cancelling edit mode for: " + convId);
        isInEditMode = false;
        titleEditField.visible = false;
        titleText.visible = true;
    }
    
    // Function to save the edited title
    function saveEdit() {
        if (!isInEditMode) {
            return;
        }
        
        var newTitle = titleEditField.text.trim();
        logDebug("Saving edit for: " + convId + " with new title: " + newTitle);
        
        if (newTitle) {
            titleEdited(convId, newTitle);
        } else {
            logDebug("Empty title, cancelling edit");
            titleEdited(convId, "");
        }
        
        isInEditMode = false;
        titleEditField.visible = false;
        titleText.visible = true;
    }
    
    // Timer to focus the edit field after a short delay
    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (isInEditMode) {
                titleEditField.forceActiveFocus();
                titleEditField.selectAll();
                logDebug("Focus set on edit field: " + convId);
            }
        }
    }
    
    Component.onCompleted: {
        logDebug("Conversation item created: " + convId + " - " + title);
    }
    
    onTitleChanged: {
        logDebug("Title property changed for " + convId + ": " + title);
    }
    
    // Pin icon and star
    Text {
        id: pinIcon
        width: 24
        height: 24
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: pinned ? "★" : "☆"  
        color: pinned ? "#FFFFFF" : "#888888"
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                logDebug("Pin icon clicked for: " + convId);
                root.pinClicked(convId, pinned);
            }
        }
    }
    
    // Conversation title (normal mode)
    Text {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: pinIcon.right
        anchors.leftMargin: 8
        anchors.right: menuButton.left
        anchors.rightMargin: 5
        text: root.title || "New Chat" // Fallback to "New Chat" if title is empty
        color: "white"
        font.pixelSize: 14
        elide: Text.ElideRight
        visible: !isInEditMode
        
        onVisibleChanged: {
            logDebug("Title text visible changed to: " + visible + " for: " + convId);
        }
    }
    
    // Conversation title edit field
    TextField {
        id: titleEditField
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: pinIcon.right
        anchors.leftMargin: 8
        anchors.right: menuButton.left
        anchors.rightMargin: 5
        text: root.title || "New Chat"
        color: "white"
        font.pixelSize: 14
        visible: isInEditMode
        
        background: Rectangle {
            color: "#333333"
            radius: 3
        }
        
        onVisibleChanged: {
            logDebug("Edit field visible changed to: " + visible + " for: " + convId);
        }
        
        Keys.onReturnPressed: {
            logDebug("Return key pressed in edit field");
            saveEdit();
        }
        
        Keys.onEscapePressed: {
            logDebug("Escape key pressed in edit field");
            cancelEdit();
        }
        
        onActiveFocusChanged: {
            logDebug("Edit field focus changed to: " + activeFocus + " for: " + convId);
            if (!activeFocus && isInEditMode) {
                logDebug("Lost focus while editing, saving");
                saveEdit();
            }
        }
    }
    
    // Menu button (three dots)
    Rectangle {
        id: menuButton
        width: 30
        height: 30
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        radius: 4
        
        Column {
            spacing: 3
            anchors.centerIn: parent
            
            Repeater {
                model: 3
                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: "white"
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = "#3A3A3A"
            onExited: parent.color = "transparent"
            onClicked: {
                logDebug("Menu button clicked for: " + convId);
                var x = menuButton.mapToItem(null, 0, 0).x;
                var y = menuButton.mapToItem(null, 0, 0).y;
                root.menuClicked(convId, title, pinned, x, y);
            }
        }
    }
    
    // Clickable area for selecting the conversation
    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: menuButton.width + pinIcon.width + 10
        anchors.leftMargin: pinIcon.width + 5
        enabled: !isInEditMode  // Disable when in edit mode
        
        onClicked: {
            logDebug("Conversation selected: " + convId);
            root.conversationSelected(convId);
        }
    }
}
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: chatView
    color: "#1E1E1E"
    
    // Debug property
    property bool debug: true
    
    // Required properties
    property bool isLoading: false
    property string activeConversationId: "default"
    
    // Signals
    signal sendMessage(string message, string conversationId)
    signal resetConversation()
    signal uploadDocument()
    
    // Debug function
    function logDebug(message) {
        if (debug) {
            console.log("ChatView: " + message);
        }
    }
    
    Component.onCompleted: {
        logDebug("Component created");
    }
    
    ListModel {
        id: chatModel
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Reset Conversation button at top right
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: "#1E1E1E"
            
            Button {
                text: "Reset Conversation"
                width: 150
                height: 30
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                
                background: Rectangle {
                    color: "#555555"
                    radius: 5
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    logDebug("Reset button clicked");
                    chatView.resetConversation();
                    chatModel.clear();
                }
            }
        }
        
        // Chat messages area with scrolling
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                id: chatListView
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                model: chatModel
                
                delegate: ChatBubble { 
                    width: chatListView.width - 20
                    messageText: message
                    isUserMessage: isUser
                }
                
                onCountChanged: {
                    chatListView.positionViewAtEnd();
                }
            }
        }
        
        // Loading indicator
        Item {
            Layout.fillWidth: true
            height: 30
            visible: isLoading
            
            Row {
                anchors.centerIn: parent
                spacing: 5
                
                Text {
                    text: "Thinking"
                    color: "#CCCCCC"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    id: loadingDots
                    text: "..."
                    color: "#CCCCCC"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Timer {
                    interval: 500
                    running: isLoading
                    repeat: true
                    property int dotCount: 0
                    onTriggered: {
                        dotCount = (dotCount + 1) % 4;
                        var dots = "";
                        for (var i = 0; i < dotCount; i++) {
                            dots += ".";
                        }
                        loadingDots.text = dots;
                    }
                }
            }
        }
        
        // Separator line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#333333"
        }
        
        // Message input area
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10
            
            // Attachment button
            Button {
                id: attachButton
                Layout.preferredWidth: 40
                height: 40
                enabled: !isLoading
                
                background: Rectangle {
                    color: "#333333"
                    radius: 5
                }
                
                contentItem: Text {
                    text: "+"
                    color: "white"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    logDebug("Upload button clicked");
                    chatView.uploadDocument();
                }
                
                ToolTip {
                    visible: parent.hovered
                    text: "Upload document"
                    delay: 500
                }
            }
            
            // Text input field
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#333333"
                radius: 5
                
                TextInput {
                    id: messageInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "white"
                    font.pixelSize: 14
                    clip: true
                    focus: true
                    enabled: !isLoading
                    
                    Text {
                        anchors.fill: parent
                        text: "Type your message..."
                        color: "#888888"
                        font.pixelSize: 14
                        visible: !messageInput.text && !messageInput.activeFocus
                    }
                    
                    Keys.onReturnPressed: {
                        if (!isLoading && messageInput.text.trim() !== "") {
                            sendButton.clicked();
                        }
                    }
                }
            }
            
            // Send button
            Button {
                id: sendButton
                text: "Send"
                height: 40
                Layout.preferredWidth: 80
                enabled: !isLoading && messageInput.text.trim() !== ""
                
                background: Rectangle {
                    color: sendButton.enabled ? "#007ACC" : "#555555"
                    radius: 5
                }
                
                contentItem: Text {
                    text: sendButton.text
                    color: "white"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (messageInput.text.trim() !== "") {
                        logDebug("Send button clicked: " + messageInput.text);
                        
                        // Add message to chat model
                        chatModel.append({
                            "message": messageInput.text,
                            "isUser": true
                        });
                        
                        // Emit signal to send the message
                        chatView.sendMessage(messageInput.text, activeConversationId);
                        
                        // Clear input field
                        messageInput.text = "";
                    }
                }
            }
        }
    }
    
    // Public methods to be called from main.qml
    function addBotMessage(message) {
        chatModel.append({
            "message": message,
            "isUser": false
        });
        logDebug("Bot message added");
    }
    
    function addUserMessage(message) {
        chatModel.append({
            "message": message,
            "isUser": true
        });
        logDebug("User message added");
    }
    
    function clearChat() {
        chatModel.clear();
        logDebug("Chat cleared");
    }
    
    function loadMessages(messages) {
        chatModel.clear();
        for (var i = 0; i < messages.length; i++) {
            chatModel.append(messages[i]);
        }
        logDebug("Loaded " + messages.length + " messages");
    }
}
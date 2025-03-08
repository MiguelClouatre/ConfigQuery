import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 500
    height: 600
    title: "QA Chatbot"
    color: "#1E1E1E"
    
    // State for tracking if bot is responding
    property bool isLoading: false
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Chat area with messages
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
                model: ListModel { id: chatModel }
                delegate: ChatBubble { 
                    width: chatListView.width - 20
                    messageText: message
                    isUserMessage: isUser
                }
                
                // Scroll to bottom when new messages are added
                onCountChanged: {
                    chatListView.positionViewAtEnd()
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
                
                // "Thinking" text
                Text {
                    text: "Thinking"
                    color: "#CCCCCC"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                // Animated dots
                Text {
                    id: loadingDots
                    text: "..."
                    color: "#CCCCCC"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                // Use a Timer for animation instead of StringAnimation
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
        
        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#333333"
        }
        
        // Input area
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10
            
            // Upload button (plus sign)
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
                    text: "+"  // Plus sign
                    color: "white"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    // Open file dialog directly
                    chatBridge.openFileDialog()
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
                    
                    // Placeholder text
                    Text {
                        anchors.fill: parent
                        text: "Type your message..."
                        color: "#888888"
                        font.pixelSize: 14
                        visible: !messageInput.text && !messageInput.activeFocus
                    }
                    
                    // Send on Enter key
                    Keys.onReturnPressed: {
                        if (!isLoading) {
                            sendButton.clicked()
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
                        // Add user message to chat
                        chatModel.append({
                            "message": messageInput.text,
                            "isUser": true
                        })
                        
                        // Send to backend
                        chatBridge.sendMessage(messageInput.text)
                        
                        // Clear input
                        messageInput.text = ""
                    }
                }
            }
        }
        
        // Bottom toolbar with reset button
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#252525"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                
                Item { Layout.fillWidth: true } // Spacer
                
                // Reset conversation button
                Button {
                    text: "Reset Conversation"
                    Layout.preferredWidth: 150
                    height: 30
                    
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
                        chatBridge.resetConversation()
                    }
                }
            }
        }
    }
    
    // Connect to Python signals
    Connections {
        target: chatBridge
        
        // Handle new bot messages
        function onNewBotMessage(message) {
            chatModel.append({
                "message": message,
                "isUser": false
            })
        }
        
        // Handle loading state changes
        function onUpdateLoadingState(loading) {
            isLoading = loading
        }
        
        // Handle conversation reset
        function onConversationReset() {
            chatModel.clear()
        }
    }
}
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    title: "QA Chatbot"
    color: "#1E1E1E"
    
    property bool isLoading: false
    property string activeConversationId: "default"
    property var conversations: {"default": {title: "New Chat", messages: []}}
    property string editingConversationId: ""
    
    Rectangle {
        id: optionsPopup
        width: 120
        height: 110
        color: "#333333"
        radius: 5
        visible: false
        z: 100
        
        property string convId: ""
        property string convTitle: ""
        property bool convPinned: false
        
        Column {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 2
            
            Rectangle {
                width: parent.width
                height: 30
                color: pinMouseArea.containsMouse ? "#444444" : "#333333"
                radius: 3
                
                Text {
                    id: pinText
                    text: optionsPopup.convPinned ? "Unpin" : "Pin"
                    color: "white"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: pinMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        optionsPopup.visible = false
                        if (optionsPopup.convPinned) {
                            chatBridge.unpinConversation(optionsPopup.convId)
                        } else {
                            chatBridge.pinConversation(optionsPopup.convId)
                        }
                    }
                }
            }
            
            Rectangle {
                width: parent.width
                height: 30
                color: renameMouseArea.containsMouse ? "#444444" : "#333333"
                radius: 3
                
                Text {
                    text: "Rename"
                    color: "white"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: renameMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        optionsPopup.visible = false
                        editingConversationId = optionsPopup.convId
                    }
                }
            }
            
            Rectangle {
                width: parent.width
                height: 30
                color: deleteMouseArea.containsMouse ? "#444444" : "#333333"
                radius: 3
                
                Text {
                    text: "Delete"
                    color: "white"
                    anchors.centerIn: parent
                    font.pixelSize: 14
                }
                
                MouseArea {
                    id: deleteMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        optionsPopup.visible = false
                        chatBridge.deleteConversation(optionsPopup.convId)
                    }
                }
            }
        }
        
        MouseArea {
            id: outsideClickArea
            anchors.fill: parent.parent
            enabled: optionsPopup.visible
            onClicked: {
                if (optionsPopup.visible) {
                    optionsPopup.visible = false
                }
            }
            z: -1
        }
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            color: "#252525"
            
            Rectangle {
                id: sidebarHeader
                width: parent.width
                height: 50
                color: "#333333"
                
                Button {
                    anchors.centerIn: parent
                    text: "New Chat"
                    width: parent.width - 20
                    height: 36
                    
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
                        var newId = "conv-" + Math.floor(Math.random() * 1000000)
                        conversations[newId] = {title: "New Chat", messages: []}
                        activeConversationId = newId
                        chatModel.clear()
                        chatBridge.createNewConversation(newId)
                    }
                }
            }
            
            ListView {
                id: conversationList
                anchors.top: sidebarHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: sidebarFooter.top
                anchors.margins: 5
                spacing: 5
                clip: true
                
                model: ListModel {
                    id: conversationsModel
                    
                    Component.onCompleted: {
                        append({
                            convId: "default", 
                            title: "New Chat", 
                            pinned: false, 
                            pinOrder: -1
                        })
                    }
                }
                
                delegate: Rectangle {
                    id: conversationItem
                    width: conversationList.width
                    height: 50
                    color: activeConversationId === convId ? "#3C3C3C" : "#252525"
                    radius: 5
                    
                    // Get pin status directly from the model item
                    property bool isPinned: pinned
                    
                    Text {
                        id: pinIcon
                        width: 24
                        height: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: isPinned ? "★" : "☆"  
                        color: isPinned ? "#FFFFFF" : "#888888"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (isPinned) {
                                    chatBridge.unpinConversation(convId)
                                } else {
                                    chatBridge.pinConversation(convId)
                                }
                            }
                        }
                    }
                    
                    Text {
                        id: titleText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: pinIcon.right
                        anchors.leftMargin: 8
                        anchors.right: menuButton.left
                        anchors.rightMargin: 5
                        text: title
                        color: "white"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        visible: editingConversationId !== convId
                    }
                    
                    TextField {
                        id: titleEditField
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: pinIcon.right
                        anchors.leftMargin: 8
                        anchors.right: menuButton.left
                        anchors.rightMargin: 5
                        text: title
                        color: "white"
                        font.pixelSize: 14
                        visible: editingConversationId === convId
                        background: Rectangle {
                            color: "#333333"
                            radius: 3
                        }
                        
                        onVisibleChanged: {
                            if (visible) {
                                forceActiveFocus()
                                selectAll()
                            }
                        }
                        
                        Keys.onReturnPressed: {
                            saveNewTitle()
                        }
                        
                        Keys.onEscapePressed: {
                            editingConversationId = ""
                        }
                        
                        onActiveFocusChanged: {
                            if (!activeFocus && editingConversationId === convId) {
                                saveNewTitle()
                            }
                        }
                        
                        function saveNewTitle() {
                            var newTitle = text.trim()
                            if (newTitle) {
                                for (var i = 0; i < conversationsModel.count; i++) {
                                    if (conversationsModel.get(i).convId === convId) {
                                        conversationsModel.setProperty(i, "title", newTitle)
                                        break
                                    }
                                }
                                
                                if (conversations[convId]) {
                                    conversations[convId].title = newTitle
                                }
                                
                                chatBridge.renameConversation(convId, newTitle)
                            }
                            
                            editingConversationId = ""
                        }
                    }
                    
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
                                optionsPopup.convId = convId
                                optionsPopup.convTitle = title
                                optionsPopup.convPinned = pinned
                                optionsPopup.x = menuButton.mapToItem(window.contentItem, 0, 0).x - optionsPopup.width + menuButton.width
                                optionsPopup.y = menuButton.mapToItem(window.contentItem, 0, 0).y
                                optionsPopup.visible = true
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: menuButton.width + pinIcon.width + 10
                        anchors.leftMargin: pinIcon.width + 5
                        
                        onClicked: {
                            editingConversationId = ""
                            
                            if (activeConversationId !== convId) {
                                activeConversationId = convId
                                chatModel.clear()
                                if (conversations[convId] && conversations[convId].messages) {
                                    for (var i = 0; i < conversations[convId].messages.length; i++) {
                                        var msg = conversations[convId].messages[i]
                                        chatModel.append(msg)
                                    }
                                }
                                chatBridge.switchConversation(convId)
                            }
                        }
                    }
                }
            }
            
            Rectangle {
                id: sidebarFooter
                width: parent.width
                height: 50
                color: "#252525"
                anchors.bottom: parent.bottom
                
                Button {
                    text: "Reset Conversation"
                    width: parent.width - 20
                    height: 36
                    anchors.centerIn: parent
                    
                    background: Rectangle {
                        color: "#555555"
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
                        chatBridge.resetConversation()
                    }
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1E1E1E"
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
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
                        
                        onCountChanged: {
                            chatListView.positionViewAtEnd()
                        }
                    }
                }
                
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
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#333333"
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    spacing: 10
                    
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
                            chatBridge.openFileDialog()
                        }
                        
                        ToolTip {
                            visible: parent.hovered
                            text: "Upload document"
                            delay: 500
                        }
                    }
                    
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
                                if (!isLoading) {
                                    sendButton.clicked()
                                }
                            }
                        }
                    }
                    
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
                                var userMessage = {
                                    "message": messageInput.text,
                                    "isUser": true
                                }
                                
                                chatModel.append(userMessage)
                                
                                if (!conversations[activeConversationId]) {
                                    conversations[activeConversationId] = {title: "New Chat", messages: []}
                                }
                                conversations[activeConversationId].messages.push(userMessage)
                                
                                if (conversations[activeConversationId].messages.length === 1) {
                                    var newTitle = messageInput.text
                                    if (newTitle.length > 20) {
                                        newTitle = newTitle.substring(0, 20) + "..."
                                    }
                                    conversations[activeConversationId].title = newTitle
                                    
                                    for (var i = 0; i < conversationsModel.count; i++) {
                                        if (conversationsModel.get(i).convId === activeConversationId) {
                                            conversationsModel.setProperty(i, "title", newTitle)
                                            break
                                        }
                                    }
                                }
                                
                                chatBridge.sendMessage(messageInput.text, activeConversationId)
                                
                                messageInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
    
    Connections {
        target: chatBridge
        
        function onNewBotMessage(message, conversationId) {
            if (conversationId === activeConversationId) {
                var botMessage = {
                    "message": message,
                    "isUser": false
                }
                chatModel.append(botMessage)
            }
            
            if (!conversations[conversationId]) {
                conversations[conversationId] = {title: "New Chat", messages: []}
            }
            conversations[conversationId].messages.push({
                "message": message,
                "isUser": false
            })
        }
        
        function onUpdateLoadingState(loading) {
            isLoading = loading
        }
        
        function onConversationReset() {
            chatModel.clear()
            if (conversations[activeConversationId]) {
                conversations[activeConversationId].messages = []
            }
        }
        
        function onConversationCreated(conversationId, title) {
            var exists = false
            for (var i = 0; i < conversationsModel.count; i++) {
                if (conversationsModel.get(i).convId === conversationId) {
                    exists = true
                    break
                }
            }
            
            if (!exists) {
                conversationsModel.append({
                    convId: conversationId,
                    title: title || "New Chat",
                    pinned: false,
                    pinOrder: -1
                })
            }
        }
        
        function onConversationPinned(conversationId, pinOrder) {
            for (var i = 0; i < conversationsModel.count; i++) {
                if (conversationsModel.get(i).convId === conversationId) {
                    conversationsModel.setProperty(i, "pinned", true)
                    conversationsModel.setProperty(i, "pinOrder", pinOrder)
                    break
                }
            }
        }
        
        function onConversationUnpinned(conversationId) {
            for (var i = 0; i < conversationsModel.count; i++) {
                if (conversationsModel.get(i).convId === conversationId) {
                    conversationsModel.setProperty(i, "pinned", false)
                    conversationsModel.setProperty(i, "pinOrder", -1)
                    break
                }
            }
        }
        
        function onPinOrderUpdated() {
            // We've removed the complex sorting for now
        }
        
        function onConversationDeleted(conversationId) {
            for (var i = 0; i < conversationsModel.count; i++) {
                if (conversationsModel.get(i).convId === conversationId) {
                    conversationsModel.remove(i)
                    break
                }
            }
            
            if (conversations[conversationId]) {
                delete conversations[conversationId]
            }
            
            if (activeConversationId === conversationId) {
                if (conversationsModel.count > 0) {
                    activeConversationId = conversationsModel.get(0).convId
                    chatModel.clear()
                    
                    if (conversations[activeConversationId] && conversations[activeConversationId].messages) {
                        for (var j = 0; j < conversations[activeConversationId].messages.length; j++) {
                            chatModel.append(conversations[activeConversationId].messages[j])
                        }
                    }
                } else {
                    chatBridge.createNewConversation("default")
                    activeConversationId = "default"
                    chatModel.clear()
                }
            }
        }
    }
}
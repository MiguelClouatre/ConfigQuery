import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: parent.width
    height: messageBubble.height
    
    // Properties
    property string messageText: ""
    property bool isUserMessage: false
    
    // Message bubble
    Rectangle {
        id: messageBubble
        width: messageText.length > 40 ? parent.width * 0.7 : Math.min(messageLabel.implicitWidth + 24, parent.width * 0.7)
        height: messageLabel.implicitHeight + 16
        radius: 15
        color: isUserMessage ? "#007ACC" : "#333333"
        
        // Position the bubble based on who sent it
        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        
        // Custom bubble shape with tail
        Rectangle {
            width: 15
            height: 15
            color: parent.color
            
            // Position the tail on the right side for user messages, left for bot
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            anchors.right: isUserMessage ? parent.right : undefined
            anchors.rightMargin: isUserMessage ? -7 : 0
            anchors.left: isUserMessage ? undefined : parent.left
            anchors.leftMargin: isUserMessage ? 0 : -7
            
            // Rotate to create a triangle shape
            rotation: 45
        }
        
        // Message text
        Text {
            id: messageLabel
            text: messageText
            color: "white"
            anchors.centerIn: parent
            anchors.margins: 12
            width: parent.width - 24
            wrapMode: Text.WordWrap
            font.pixelSize: 14
        }
    }
}

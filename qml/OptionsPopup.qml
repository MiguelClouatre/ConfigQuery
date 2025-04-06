import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: optionsPopup
    width: 120
    height: 110
    color: "#333333"
    radius: 5
    visible: false
    z: 100
    
    // Debug properties
    property bool debug: true
    
    // Properties to receive from parent
    property string convId: ""
    property string convTitle: ""
    property bool convPinned: false
    
    // Signal to notify parent when popup should be hidden
    signal popupHidden()
    
    // Functions to emit signals from parent
    signal pinClicked(string convId, bool isPinned)
    signal renameClicked(string convId)
    signal deleteClicked(string convId)
    
    // Debug function
    function logDebug(message) {
        if (debug) {
            console.log("OptionsPopup: " + message);
        }
    }
    
    Component.onCompleted: {
        logDebug("Component created");
    }
    
    onVisibleChanged: {
        logDebug("Visibility changed to: " + visible);
        if (visible) {
            logDebug("Showing popup for conv: " + convId + " (pinned: " + convPinned + ")");
        } else if (!visible) {
            logDebug("Popup hidden");
        }
    }
    
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
                text: optionsPopup.convPinned ? "Unfavorite" : "Favorite"
                color: "white"
                anchors.centerIn: parent
                font.pixelSize: 14
            }
            
            MouseArea {
                id: pinMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    logDebug("Pin clicked for conv: " + optionsPopup.convId);
                    optionsPopup.visible = false;
                    optionsPopup.popupHidden();
                    optionsPopup.pinClicked(optionsPopup.convId, optionsPopup.convPinned);
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
                    logDebug("Rename clicked for conv: " + optionsPopup.convId);
                    optionsPopup.visible = false;
                    optionsPopup.popupHidden();
                    optionsPopup.renameClicked(optionsPopup.convId);
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
                    logDebug("Delete clicked for conv: " + optionsPopup.convId);
                    optionsPopup.visible = false;
                    optionsPopup.popupHidden();
                    optionsPopup.deleteClicked(optionsPopup.convId);
                }
            }
        }
    }
    
    // Function to show the popup
    function showPopup(id, title, pinned, x, y) {
        convId = id;
        convTitle = title;
        convPinned = pinned;
        optionsPopup.x = x;
        optionsPopup.y = y;
        optionsPopup.visible = true;
        logDebug("showPopup called for: " + id + " at position " + x + "," + y);
    }
}
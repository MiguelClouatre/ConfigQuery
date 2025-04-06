.pragma library

// Debug flag - turn off in production
var debug = true;

// Simple console logger with component identification
function log(component, message) {
    if (debug) {
        console.log(component + ": " + message);
    }
}

// Generate a unique conversation ID
function generateConversationId() {
    return "conv-" + Math.floor(Math.random() * 1000000);
}

// Truncate a string to a maximum length with ellipsis
function truncateString(str, maxLength) {
    if (!str) return "New Chat";

    if (str.length <= maxLength) {
        return str;
    }

    return str.substring(0, maxLength) + "...";
}

// Find an item in a ListModel by property value
function findInModel(model, propertyName, value) {
    for (var i = 0; i < model.count; i++) {
        if (model.get(i)[propertyName] === value) {
            return { index: i, item: model.get(i) };
        }
    }
    return null;
}

// Format conversation titles from first message
function formatConversationTitle(message) {
    if (!message) return "New Chat";

    return truncateString(message, 20);
}
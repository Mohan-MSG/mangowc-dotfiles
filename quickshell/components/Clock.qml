import QtQuick

Text {
    property var theme
    text: Qt.formatDateTime(new Date(), "ddd dd MMM yyyy HH:mm:ss")
    font.family: theme.font
    font.pixelSize: theme.fontSize
    font.bold: true
    color: theme.cyan
    horizontalAlignment: Text.AlignHCenter

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: text = Qt.formatDateTime(new Date(), "ddd dd MMM yyyy HH:mm:ss")
    }
}

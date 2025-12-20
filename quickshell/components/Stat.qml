import QtQuick
import Quickshell.Io

Row {
    property var theme
    property string label
    property string value
    property string shellCommand
    property color statColor
    spacing: 4

    property string val: "0"

    Process {
        id: p
        command: ["sh", "-c", shellCommand]
        stdout: SplitParser { 
            onRead: d => {
                val = d.trim() 
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: p.running = true
    }

    Text {
        text: label
        font.family: theme.font
        font.pixelSize: theme.fontSize
        font.bold: true
        color: statColor
    }

    Text {
        text: val + value
        font.family: theme.font
        font.pixelSize: theme.fontSize
        color: theme.fg
    }
}

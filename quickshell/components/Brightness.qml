import QtQuick
import Quickshell.Io

Item {
    property var theme
    
    // Internal properties to track brightness
    property int current: 0
    property int max: 100
    property int percent: 0

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Process {
        id: getMax
        command: ["brightnessctl", "m"]
        stdout: SplitParser { onRead: d => max = parseInt(d.trim()) }
        Component.onCompleted: running = true
    }

    Process {
        id: getCurrent
        command: ["brightnessctl", "g"]
        stdout: SplitParser { 
            onRead: d => {
                current = parseInt(d.trim())
                if (max > 0) percent = Math.round((current / max) * 100)
            }
        }
        Component.onCompleted: running = true
    }
    
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: getCurrent.running = true
    }

    Row {
        id: content
        spacing: 6
        
        Text {
            text: "󰃠"
            font.family: theme.font
            font.pixelSize: theme.fontSize + 2
            color: theme.yellow
        }

        Text {
            text: percent + "%"
            font.family: theme.font
            font.pixelSize: theme.fontSize
            color: theme.fg
        }
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onWheel: (wheel) => {
            let change = wheel.angleDelta.y > 0 ? "+5%" : "5%-"
            let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
            p.command = ["brightnessctl", "s", change]
            p.running = true
            getCurrent.running = true
        }
    }
}

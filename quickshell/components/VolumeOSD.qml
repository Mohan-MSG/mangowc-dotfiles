import QtQuick
import Quickshell.Io

Item {
    property var theme
    property int volume: 0
    property bool muted: false
    
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Process {
        id: vol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: d => {
                let m = d.match(/Volume: ([\d.]+)/)
                if (m) volume = Math.round(parseFloat(m[1]) * 100)
                muted = d.includes("MUTED")
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: vol.running = true
    }

    Row {
        id: content
        spacing: 6
        
        Text {
            text: muted ? "󰝟" : (volume > 50 ? "󰕾" : "󰖀")
            font.family: theme.font
            font.pixelSize: theme.fontSize + 2
            color: muted ? theme.red : theme.purple
        }

        Text {
            text: volume + "%"
            font.family: theme.font
            font.pixelSize: theme.fontSize
            color: theme.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
            p.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
            p.running = true
            vol.running = true
        }
        onWheel: (wheel) => {
            let change = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
            let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
            p.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", change]
            p.running = true
            vol.running = true
        }
    }
}

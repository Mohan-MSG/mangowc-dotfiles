import QtQuick
import Quickshell.Io

Row {
    property var theme
    spacing: 6
    property int level: 0
    property bool charging: false

    Process {
        id: bat
        command: ["sh", "-c", "echo $(cat /sys/class/power_supply/BAT1/capacity) $(cat /sys/class/power_supply/BAT1/status)"]
        stdout: SplitParser {
            onRead: d => {
                let l = d.trim().split(" ")
                level = parseInt(l[0])
                charging = l[1] === "Charging"
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: bat.running = true
    }

    Text {
        text: charging ? "󰂄" :
              level > 80 ? "󰁹" :
              level > 60 ? "󰂀" :
              level > 40 ? "󰁾" :
              level > 20 ? "󰁼" : "󰁺"
        font.family: theme.font
        font.pixelSize: theme.fontSize + 2
        color: charging ? theme.green : theme.blue
    }

    Text {
        text: charging ? "Charging " + level + "%" : 
              level >= 100 ? "Full" : 
              "Discharging " + level + "%"
        font.family: theme.font
        font.pixelSize: theme.fontSize
        color: theme.fg
    }
}

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    property var theme
    width: 24
    height: 24

    Text {
        anchors.centerIn: parent
        text: "󰐥"
        font.family: theme.font
        font.pixelSize: theme.fontSize + 4
        color: theme.red

        MouseArea {
            anchors.fill: parent
            onClicked: menu.visible = !menu.visible
        }
    }

    PopupWindow {
        id: menu
        implicitWidth: 120
        implicitHeight: 140
        anchor.item: parent
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 10
        visible: false
        
        Rectangle {
            anchors.fill: parent
            color: theme.bg
            border.color: theme.muted
            border.width: 1
            radius: 8
            
            Column {
                anchors.centerIn: parent
                spacing: 10
                
                MenuButton { label: "Shutdown"; icon: "󰐥"; iconColor: theme.red; onClicked: exec("poweroff") }
                MenuButton { label: "Reboot"; icon: "󰜉"; iconColor: theme.yellow; onClicked: exec("reboot") }
                MenuButton { label: "Suspend"; icon: "󰤄"; iconColor: theme.blue; onClicked: exec("systemctl suspend") }
                MenuButton { label: "Logout"; icon: "󰍃"; iconColor: theme.purple; onClicked: exec("hyprctl dispatch exit") }
            }
        }
    }

    component MenuButton: Rectangle {
        id: menuBtn
        property string label
        property string icon
        property color iconColor
        signal clicked
        
        width: 100
        height: 24
        color: "transparent"
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            Text { text: icon; color: menuBtn.iconColor; font.family: theme.font }
            Text { text: label; color: theme.fg; font.family: theme.font }
        }
        
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    Process { id: proc }
    function exec(cmd) {
        proc.command = ["sh", "-c", cmd]
        proc.running = true
        menu.visible = false
    }
}

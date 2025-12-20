import QtQuick

import Quickshell.Hyprland

Row {
    id: strip
    property var theme
    spacing: 8

    Repeater {
        model: 9
        Rectangle {
            property int ws: index + 1
            property bool active: Hyprland.focusedWorkspace?.id === ws
            property bool occupied: Hyprland.workspaces.values.some(w => w.id === ws)

            width: active ? 32 : 24
            height: 24
            radius: 12
            color: active ? strip.theme.cyan :
                   occupied ? Qt.rgba(strip.theme.fg.r, strip.theme.fg.g, strip.theme.fg.b, 0.15) :
                   Qt.rgba(strip.theme.muted.r, strip.theme.muted.g, strip.theme.muted.b, 0.1)
            
            border.width: active ? 0 : 1
            border.color: occupied ? strip.theme.muted : "transparent"

            Text {
                anchors.centerIn: parent
                text: ws
                visible: true
                font.family: strip.theme.font
                font.pixelSize: strip.theme.fontSize - 2
                font.bold: true
                color: active ? strip.theme.bg : strip.theme.fg
            }

            Behavior on width { NumberAnimation { duration: 200 } }
            Behavior on color { ColorAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + ws)
            }
        }
    }
}

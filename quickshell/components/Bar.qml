import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    property var modelData
    property var display: modelData
    property var theme
    property bool hidden: false

    screen: modelData

    implicitHeight: 40
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: hidden ? -height - 10 : 10
    margins.left: 10
    margins.right: 10

    Behavior on margins.top {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    color: "transparent"

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.85)
            border.color: theme.muted
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            WorkspaceStrip { theme: bar.theme }

            Clock {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                theme: bar.theme
            }

            RowLayout {
                spacing: 12

                Stat {
                    label: "CPU"
                    value: "%"
                    shellCommand: "sh " + Qt.resolvedUrl("..").toString().replace("file://", "") + "/cpu_usage.sh"
                    statColor: theme.yellow
                    theme: bar.theme
                }

                Rectangle {
                    width: 3
                    height: 20
                    color: theme.cyan
                }
                
                Stat {
                    label: "MEM"
                    value: "%"
                    shellCommand: "free | awk '/Mem/ {print int($3/$2*100)}'"
                    statColor: theme.cyan
                    theme: bar.theme
                }

                Rectangle {
                    width: 3
                    height: 20
                    color: theme.red
                }
                
                Battery { theme: bar.theme }
                
                Rectangle {
                    width: 3
                    height: 20
                    color: theme.green
                }
                
                Brightness { theme: bar.theme }

                Rectangle {
                    width: 3
                    height: 20
                    color: theme.yellow
                }
                
                VolumeOSD { theme: bar.theme }

                Rectangle {
                    width: 3
                    height: 20
                    color: theme.blue
                }

                ControlPanel { theme: bar.theme }
            }
        }
    }
}

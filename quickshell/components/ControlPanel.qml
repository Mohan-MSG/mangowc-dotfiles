import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts

Item {
    property var theme
    width: 24
    height: 24

    // Status properties
    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool airplaneMode: false

    // Update status periodically
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: updateStatus()
        Component.onCompleted: updateStatus()
    }

    function updateStatus() {
        // Get WiFi status
        proc.command = ["sh", "-c", "nmcli radio wifi | grep -q 'enabled' && echo 'on' || echo 'off' "]
        proc.onFinished = function() {
            wifiEnabled = proc.readAll().trim() === 'on'
        }
        proc.running = true

        // Get Bluetooth status
        proc.command = ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 'on' || echo 'off' "]
        proc.onFinished = function() {
            bluetoothEnabled = proc.readAll().trim() === 'on'
        }
        proc.running = true
    }

    // Icon to open the control panel popup
    Text {
        id: controlIcon
        anchors.centerIn: parent
        text: "󰚨" // control panel icon
        font.family: theme.font
        font.pixelSize: theme.fontSize + 4
        color: theme.fg
        MouseArea {
            anchors.fill: parent
            onClicked: menu.visible = !menu.visible
        }
    }

    PopupWindow {
        id: menu
        implicitWidth: 180
        implicitHeight: 300
        anchor.item: parent
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 10
        visible: false

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.9)
            border.color: theme.muted
            border.width: 1
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header
                Text {
                    text: "Quick Controls"
                    color: theme.fg
                    font.family: theme.font
                    font.bold: true
                    font.pixelSize: theme.fontSize + 2
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                // Network Section
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    Text {
                        text: "NETWORK"
                        color: theme.muted
                        font.family: theme.font
                        font.pixelSize: theme.fontSize - 2
                        Layout.leftMargin: 4
                    }

                    // WiFi Toggle
                    MenuButton {
                        id: wifiButton
                        label: "Wi-Fi"
                        icon: wifiEnabled ? "󰤨" : "󰤭"
                        iconColor: theme.yellow
                        isToggle: true
                        checked: wifiEnabled
                        onClicked: {
                            wifiEnabled = !wifiEnabled
                            exec("nmcli radio wifi " + (wifiEnabled ? "on" : "off"))
                        }
                    }

                    // Bluetooth Toggle
                    MenuButton {
                        id: bluetoothButton
                        label: "Bluetooth"
                        icon: bluetoothEnabled ? "󰂯" : "󰂲"
                        iconColor: theme.cyan
                        isToggle: true
                        checked: bluetoothEnabled
                        onClicked: {
                            bluetoothEnabled = !bluetoothEnabled
                            exec("bluetoothctl power " + (bluetoothEnabled ? "on" : "off"))
                        }
                    }

                    // Airplane Mode
                    MenuButton {
                        id: airplaneButton
                        label: "Airplane Mode"
                        icon: "󰈂"
                        iconColor: theme.red
                        isToggle: true
                        checked: airplaneMode
                        onClicked: {
                            airplaneMode = !airplaneMode
                            if (airplaneMode) {
                                wifiEnabled = false
                                bluetoothEnabled = false
                                exec("nmcli radio all off && bluetoothctl power off")
                            } else {
                                wifiEnabled = true
                                bluetoothEnabled = true
                                exec("nmcli radio all on && bluetoothctl power on")
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: theme.muted
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }

                // Power Section
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    Text {
                        text: "POWER"
                        color: theme.muted
                        font.family: theme.font
                        font.pixelSize: theme.fontSize - 2
                        Layout.leftMargin: 4
                    }

                    // Power Options
                    GridLayout {
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        Layout.fillWidth: true

                        PowerButton {
                            label: "Sleep"
                            icon: "󰤄"
                            iconColor: theme.blue
                            onClicked: exec("systemctl suspend")
                        }

                        PowerButton {
                            label: "Restart"
                            icon: "󰜉"
                            iconColor: theme.yellow
                            onClicked: exec("reboot")
                        }

                        PowerButton {
                            label: "Shutdown"
                            icon: "󰐥"
                            iconColor: theme.red
                            onClicked: exec("poweroff")
                        }

                        PowerButton {
                            label: "Logout"
                            icon: "󰍃"
                            iconColor: theme.purple
                            onClicked: exec("hyprctl dispatch exit")
                        }
                    }
                }
            }
        }
    }

    // Menu Button Component
    component MenuButton: Rectangle {
        id: menuBtn
        property string label
        property string icon
        property color iconColor
        property bool isToggle: false
        property bool checked: false
        signal clicked
        
        Layout.fillWidth: true
        height: 32
        radius: 6
        color: "transparent"
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12
            
            Text { 
                text: icon 
                color: menuBtn.iconColor 
                font { 
                    family: theme.font
                    pixelSize: theme.fontSize + 2
                }
                Layout.preferredWidth: 24
            }
            
            Text { 
                text: label 
                color: theme.fg 
                font: theme.font 
                Layout.fillWidth: true
            }
            
            // Toggle indicator
            Rectangle {
                visible: isToggle
                width: 36
                height: 20
                radius: 10
                color: checked ? theme.blue : theme.muted
                border.color: checked ? theme.blue : theme.muted
                border.width: 1
                
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: checked ? parent.width - width - 2 : 2
                    width: 16
                    height: 16
                    radius: 8
                    color: theme.bg
                    Behavior on x { NumberAnimation { duration: 100 } }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: menuBtn.clicked()
                }
            }
        }
        
        MouseArea { 
            anchors.fill: parent
            onClicked: {
                if (!isToggle) {
                    parent.clicked()
                }
            }
        }
        
        // Hover effect
        states: State {
            name: "hovered"
            when: hoverHandler.hovered
            PropertyChanges { 
                target: menuBtn
                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.1)
            }
        }
        
        HoverHandler { id: hoverHandler }
    }
    
    // Power Button Component (simplified version for power menu)
    component PowerButton: Rectangle {
        property string label
        property string icon
        property color iconColor
        signal clicked
        
        Layout.fillWidth: true
        height: 60
        radius: 8
        color: Qt.rgba(theme.muted.r, theme.muted.g, theme.muted.b, 0.2)
        
        Column {
            anchors.centerIn: parent
            spacing: 4
            
            Text {
                text: icon
                color: iconColor
                font.pixelSize: 20
                font.family: theme.font
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: label
                color: theme.fg
                font.pixelSize: 10
                font.family: theme.font
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
            onPressed: parent.opacity = 0.7
            onReleased: parent.opacity = 1.0
            onCanceled: parent.opacity = 1.0
        }
    }

    // Helper to execute shell commands
    Process { 
        id: proc 
        property var onFinished: null
        
        onFinished: {
            if (onFinished) {
                onFinished()
                onFinished = null
            }
        }
    }
    
    function exec(cmd) {
        proc.command = ["sh", "-c", cmd]
        proc.running = true
        // Don't close menu for toggle operations
        if (!cmd.includes("nmcli") && !cmd.includes("bluetoothctl")) {
            menu.visible = false
        }
    }
}

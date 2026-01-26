import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // Theme colors - Neon/Brightened
    property color colBg: "#cc1a1b26" // 80% opacity
    property color colFg: "#ffffff"
    property color colMuted: "#565f89"
    property color colCyan: "#00f5ff"
    property color colPurple: "#c678dd"
    property color colRed: "#ff5a5f"
    property color colYellow: "#ffcc00"
    property color colBlue: "#2ac3de"
    property color colGreen: "#00ff99"
    property color colPink: "#ff79c6"
    property color colPeach: "#ff9e64"
    property color colLavender: "#bb9af7"

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // System info properties
    property string kernelVersion: "Linux"
    property int cpuUsage: 0
    property int memUsage: 0
    property int diskUsage: 0
    property int volumeLevel: 0
    property int batteryLevel: 0
    property string batteryStatus: "Discharging"
    property string batteryRemaining: ""
    property color batteryColor: batteryLevel < 20 ? colRed : (batteryLevel < 45 ? colYellow : colGreen)
    property string activeWindow: "Window"
    property string currentLayout: "Tile"
    property int brightnessLevel: 0
    property int workspacesPerPage: 5
    property int workspacePageStart: {
        if (!Hyprland.focusedWorkspace)
            return 1
        return Math.floor((Hyprland.focusedWorkspace.id - 1) / workspacesPerPage)
               * workspacesPerPage + 1
    }

    // CPU tracking
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    function scrollWorkspace(delta) {
        if (!Hyprland.focusedWorkspace) return;

        let target = Hyprland.focusedWorkspace.id + delta;
        if (target < 1) target = 1;

        Hyprland.dispatch("workspace " + target);
    }

    

    // Kernel version
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: SplitParser {
            onRead: data => {
                if (data) kernelVersion = data.trim()
            }
        }
        Component.onCompleted: running = true
    }

    // CPU usage
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (lastCpuTotal > 0) {
                    var totalDiff = total - lastCpuTotal
                    var idleDiff = idleTime - lastCpuIdle
                    if (totalDiff > 0) {
                        cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                lastCpuTotal = total
                lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    // Memory usage
    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    // Disk usage
    Process {
        id: diskProc
        command: ["sh", "-c", "df / | tail -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var percentStr = parts[4] || "0%"
                diskUsage = parseInt(percentStr.replace('%', '')) || 0
            }
        }
        Component.onCompleted: running = true
    }

    // Volume level (wpctl for PipeWire)
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    var match = data.match(/Volume:\s*([\d.]+)/)
                    if (match) {
                        volumeLevel = Math.round(parseFloat(match[1]) * 100)
                    }
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Battery info
    Process {
        id: batProc
        command: ["sh", "-c", "upower -i $(upower -e | grep 'BAT') | grep -E 'state|percentage|time to empty|time to full'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var lines = data.trim().split('\n')
                lines.forEach(line => {
                    var parts = line.split(':')
                    if (parts.length < 2) return
                    var key = parts[0].trim()
                    var val = parts[1].trim()
                    
                    if (key === "state") {
                        if (val === "discharging") batteryStatus = "Discharging"
                        else if (val === "charging") batteryStatus = "Charging"
                        else if (val === "fully-charged") batteryStatus = "Full"
                        else batteryStatus = val
                    } else if (key === "percentage") {
                        batteryLevel = parseInt(val.replace('%', ''))
                    } else if (key === "time to empty") {
                        batteryRemaining = val
                    } else if (key === "time to full") {
                        batteryRemaining = val
                    }
                })
                
                if (batteryStatus === "Full") {
                    batteryRemaining = "Full"
                } else if (batteryRemaining === "" || batteryRemaining === batteryStatus) {
                    batteryRemaining = "Calculating..."
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Active window title
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    activeWindow = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Current layout (Hyprland: dwindle/master/floating)
    Process {
        id: layoutProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r 'if .floating then \"Floating\" elif .fullscreen == 1 then \"Fullscreen\" else \"Tiled\" end'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    currentLayout = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Brightness level
    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) brightnessLevel = parseInt(data.trim())
            }
        }
        Component.onCompleted: running = true
    }

    
    // Slow timer for system stats
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            volProc.running = true
            batProc.running = true
            brightProc.running = true
        }
    }

    // Event-based updates for window/layout (instant)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
            layoutProc.running = true
        }
    }

    // Backup timer for window/layout (catches edge cases)
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            windowProc.running = true
            layoutProc.running = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 36
            color: "transparent"

            margins {
                top: 5
                bottom: 0
                left: 10
                right: 10
            }

            Rectangle {
                anchors.fill: parent
                color: root.colBg
                radius: 8
                border.color: "#33ffffff"
                border.width: 1

                RowLayout {
                    anchors {
                        left: parent.left
                        right: clockLayout.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 0

                    Item { width: 15 }

                    Item {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: parent.height

                        Row {
                            anchors.fill: parent
                            Repeater {
                                model: 5

                                Rectangle {
                                    width: 20
                                    height: parent.height
                                    color: "transparent"

                                    property int wsId: root.workspacePageStart + index
                                    property var workspace: Hyprland.workspaces.values.find(ws => ws.id === wsId) ?? null
                                    property bool isActive: Hyprland.focusedWorkspace?.id === wsId
                                    property bool hasWindows: workspace !== null

                                    Text {
                                        text: wsId
                                        color: parent.isActive ? root.colCyan : (parent.hasWindows ? root.colFg : root.colMuted)
                                        font.pixelSize: root.fontSize
                                        font.family: root.fontFamily
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }

                                    Rectangle {
                                        width: 20
                                        height: 3
                                        color: parent.isActive ? root.colLavender : root.colBg
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Hyprland.dispatch("workspace " + wsId)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            acceptedButtons: Qt.NoButton
                            preventStealing: true

                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y < 0)
                                    root.scrollWorkspace(1);
                                else
                                    root.scrollWorkspace(-1);
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        text: currentLayout
                        color: root.colLavender
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.leftMargin: 5
                        Layout.rightMargin: 5
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 2
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        text: activeWindow
                        color: root.colFg
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                RowLayout {
                    id: clockLayout
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        id: clockDay
                        text: Qt.formatDateTime(new Date(), "ddd")
                        color: root.colRed
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        id: clockDate
                        text: Qt.formatDateTime(new Date(), "dd MMM yyyy")
                        color: root.colLavender
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        id: clockTime
                        text: Qt.formatDateTime(new Date(), "HH:mm:ss")
                        color: root.colCyan
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            var now = new Date()
                            clockDay.text = Qt.formatDateTime(now, "ddd")
                            clockDate.text = Qt.formatDateTime(now, "dd MMM yyyy")
                            clockTime.text = Qt.formatDateTime(now, "HH:mm:ss")
                        }
                    }
                }

                RowLayout {
                    anchors {
                        right: parent.right
                        left: clockLayout.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    spacing: 0

                    Item { Layout.fillWidth: true }

                    Text {
                        text: kernelVersion
                        color: root.colRed
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        text: "CPU: " + cpuUsage + "%"
                        color: root.colYellow
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        text: "Mem: " + memUsage + "%"
                        color: root.colCyan
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Text {
                        text: "Disk: " + diskUsage + "%"
                        color: root.colBlue
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        Layout.rightMargin: 8
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 0
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Item {
                        width: volInfo.implicitWidth
                        height: parent.height
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8

                        Text {
                            id: volInfo
                            text: "Vol: " + volumeLevel + "%"
                            color: root.colPurple
                            font.pixelSize: root.fontSize
                            font.family: root.fontFamily
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            preventStealing: true

                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0)
                                    Quickshell.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"])
                                else
                                    Quickshell.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])

                                volProc.running = true
                                wheel.accepted = true
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Item {
                        width: brightInfo.implicitWidth
                        height: parent.height
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8

                        Text {
                            id: brightInfo
                            text: "Brt: " + brightnessLevel + "%"
                            color: root.colPeach
                            font.pixelSize: root.fontSize
                            font.family: root.fontFamily
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            preventStealing: true

                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0)
                                    Quickshell.exec(["brightnessctl", "set", "5%+"])
                                else
                                    Quickshell.exec(["brightnessctl", "set", "5%-"])

                                brightProc.running = true
                                wheel.accepted = true
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colMuted
                    }

                    Item {
                        id: batteryWrapper
                        implicitWidth: batInnerRow.implicitWidth
                        implicitHeight: 24
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 8
                        property bool showTime: false

                        Row {
                            id: batInnerRow
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Item {
                                width: 25
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: root.colMuted
                                    border.width: 1
                                    radius: 2

                                    Rectangle {
                                        id: batteryFill
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 2
                                        width: Math.max(2, (parent.width - 4) * (Math.min(100, root.batteryLevel) / 100))
                                        color: root.batteryColor
                                        radius: 1

                                        Rectangle {
                                            id: chargingGlow
                                            anchors.fill: parent
                                            color: "white"
                                            opacity: 0
                                            visible: root.batteryStatus !== "Discharging"
                                            radius: 1

                                            SequentialAnimation on opacity {
                                                running: root.batteryStatus !== "Discharging"
                                                loops: Animation.Infinite
                                                NumberAnimation { from: 0; to: 0.5; duration: 1000 }
                                                NumberAnimation { from: 0.5; to: 0; duration: 1000 }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 2
                                        height: 4
                                        color: root.colMuted
                                        anchors.left: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Text {
                                property bool isPlugged: root.batteryStatus !== "Discharging"
                                visible: isPlugged
                                text: "󱐋"
                                color: "#f1fa8c"
                                font.pixelSize: root.fontSize + 4
                                verticalAlignment: Text.AlignVCenter
                                font.family: root.fontFamily
                            }

                            Text {
                                text: batteryWrapper.showTime ? root.batteryRemaining : root.batteryLevel + "%"
                                color: root.batteryColor
                                font.pixelSize: root.fontSize
                                font.family: root.fontFamily
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onWheel: (wheel) => { batteryWrapper.showTime = !batteryWrapper.showTime }
                            
                            Rectangle {
                                visible: parent.containsMouse
                                anchors.bottom: parent.top
                                anchors.right: parent.right
                                anchors.bottomMargin: 8
                                width: infoText.width + 12
                                height: infoText.height + 8
                                color: root.colBg
                                border.color: root.colMuted
                                border.width: 1
                                radius: 4
                                z: 100

                                Text {
                                    id: infoText
                                    anchors.centerIn: parent
                                    text: root.batteryRemaining
                                    color: root.colFg
                                    font.pixelSize: root.fontSize - 1
                                    font.family: root.fontFamily
                                }
                            }
                        }
                    }

                    Item { width: 8 }
                }
            }
        }
    }
}

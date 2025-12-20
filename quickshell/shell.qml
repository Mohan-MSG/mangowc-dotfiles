import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root

    /* =====================
       COLORS / THEME
       ===================== */
    property bool darkMode: true
    property color bg: darkMode ? "#1a1b26" : "#eaeaea"
    property color fg: darkMode ? "#c0caf5" : "#2e3440"
    property color muted: darkMode ? "#444b6a" : "#9aa5ce"
    property color green: "#9ece6a"
    property color yellow: "#e0af68"
    property color red: "#f7768e"
    property color cyan: "#0db9d7"
    property color blue: "#7aa2f7"

    property var workspaceAccents: [
        "#7aa2f7", "#0db9d7", "#ad8ee6",
        "#e0af68", "#f7768e", "#9ece6a",
        "#bb9af7", "#2ac3de", "#ff9e64"
    ]

    property color accent:
        workspaceAccents[(Hyprland.focusedWorkspace?.id ?? 1) - 1]

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13

    /* =====================
       HELPERS
       ===================== */
    function lerp(a, b, t) { return a + (b - a) * t }

    function gradient(v) {
        if (v < 50)
            return Qt.rgba(
                lerp(green.r, yellow.r, v / 50),
                lerp(green.g, yellow.g, v / 50),
                lerp(green.b, yellow.b, v / 50), 1)
        return Qt.rgba(
            lerp(yellow.r, red.r, (v - 50) / 50),
            lerp(yellow.g, red.g, (v - 50) / 50),
            lerp(yellow.b, red.b, (v - 50) / 50), 1)
    }

    
    function bvgradient(value) {
        if (value > 75) return "red" ;
        if (value > 50) return "yellow";
        return "green";
    }

    /* =====================
       STATE
       ===================== */
    property int cpu: 0
    property int mem: 0
    property int vol: 0
    property int bat: 0
    property int bri: 0
    property string batState: "unknown"
    property string batTime: ""
    property string kernel: ""

    property int lastCpuIdle: 0
    property int lastCpuTotal: 0
    property bool lowBatWarned: false

    property var cpuHist: []
    property var memHist: []
    property var volHist: []

    /* =====================
       PROCESSES
       ===================== */
    Process {
        command: ["uname", "-r"]
        stdout: SplitParser { onRead: d => kernel = d.trim() }
        Component.onCompleted: running = true
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: d => {
                var p = d.trim().split(/\s+/)
                var idle = +p[4] + +p[5]
                var total = p.slice(1).reduce((a,b)=>a+ +b,0)
                if (lastCpuTotal) {
                    cpu = Math.round(
                        100 * ((total-lastCpuTotal)-(idle-lastCpuIdle)) /
                        (total-lastCpuTotal))
                }
                lastCpuIdle = idle
                lastCpuTotal = total
            }
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: d => {
                var p = d.split(/\s+/)
                mem = Math.round(100 * p[2] / p[1])
            }
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: d => vol = Math.round(+d.match(/([\d.]+)/)[1] * 100)
        }
    }

    
    Process {
        id: briProc
        command: ["sh", "-c", "value=$(brightnessctl get); max=$(brightnessctl max); echo $value $max" ]
        stdout: SplitParser {
            onRead: d => {
                var parts = d.trim().split(" ")
                var value = parseInt(parts[0])
                var max = parseInt(parts[1])
                if ( !isNaN(value) && !isNaN(max) && max > 0 ) {
                    bri = Math.round( value / max * 100 )
                }
            }
        }
    }

    Process {
        id: batProc
        command: ["sh", "-c",
            "upower -i $(upower -e | grep BAT) | awk "
            + "'/percentage/ {p=$2} /state/ {s=$2} "
            + "/time to/ {t=$4\" \"$5} END {print p,s,t}'"]
        stdout: SplitParser {
            onRead: d => {
                var p = d.trim().split(" ")
                bat = parseInt(p[0])
                batState = p[1]
                batTime = p.slice(2).join(" ")

                if (bat <= 20 && batState === "discharging" && !lowBatWarned) {
                    Hyprland.dispatch(
                        "exec notify-send -u critical 'Low Battery' 'Battery at " + bat + "%'"
                    )
                    lowBatWarned = true
                }
                if (bat > 25) lowBatWarned = false
            }
        }
    }

    /* =====================
       TIMER
       ===================== */
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            volProc.running = true
            batProc.running = true
            briProc.running = true

            cpuHist.push(cpu); if (cpuHist.length > 20) cpuHist.shift()
            memHist.push(mem); if (memHist.length > 20) memHist.shift()
            volHist.push(vol); if (volHist.length > 20) volHist.shift()
        }
    }

    /* =====================
       UI
       ===================== */
    Variants {
        model: Quickshell.screens

        PanelWindow {
            screen: modelData
            implicitHeight: 36
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top : 10
                left: 0
                right: 0
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                height: parent.height
                radius: 12
                color: bg
                border.color: muted

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Layout.margins: 5

                    /* WORKSPACES */
                    Repeater {
                        model: 9
                        delegate: Text {
                            text: index + 1
                            color: Hyprland.focusedWorkspace?.id === index+1
                                   ? accent : muted
                            font.bold: true
                            font.family: fontFamily
                            font.pixelSize: fontSize
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("workspace " + (index+1))
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    /* CLOCK */
                    Text {
                        text: Qt.formatDateTime(new Date(),
                            "ddd dd MMM yyyy HH:mm:ss")
                        color: accent
                        font.family: fontFamily
                        font.pixelSize: fontSize
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: parent.text =
                                Qt.formatDateTime(new Date(),
                                    "ddd dd MMM yyyy HH:mm:ss")
                        }
                    }

                    Item { Layout.fillWidth: true }

                    /* DARK MODE TOGGLE BUTTON */
                    Rectangle {
                        width: 30; height: 20
                        radius: 4
                        color: muted
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.darkMode = !root.darkMode
                        }
                        Text {
                            anchors.centerIn: parent
                            text: darkMode ? "" : "☀️"
                            font.pixelSize: fontSize
                        }
                    }

                    /* KERNEL */
                    Text {
                        text: " " + kernel
                        color: blue
                        font.family: fontFamily
                        font.pixelSize: fontSize
                    }

                    /* CPU STAT */
                    Rectangle {
                        width: 3; height: parent.height
                        color: cyan
                    }
                    Text {
                        text: "CPU " + cpu + "%"
                        color: gradient(cpu)
                        font.family: fontFamily
                        font.pixelSize: fontSize
                    }

                    /* MEM STAT */
                    Rectangle {
                        width: 3; height: parent.height
                        color: cyan
                    }
                    Text {
                        text: "MEM " + mem + "%"
                        color: gradient(mem)
                        font.family: fontFamily
                        font.pixelSize: fontSize
                    }

                    /* VOL STAT */
                    Rectangle {
                        width: 3; height: parent.height
                        color: cyan
                    }
                    Text {
                        text: "VOL " + vol + "%"
                        color: bvgradient(vol)
                        font.family: fontFamily
                        font.pixelSize: fontSize
                    }

                    
                    /* BRI STAT */
                    Rectangle {
                        width: 3; height: parent.height
                        color: cyan
                    }
                    Text {
                        text: "BRI " + bri + "%"
                        color: bvgradient(bri)
                        font.family: fontFamily
                        font.pixelSize: fontSize
                    }

                    /* BATTERY */
                    Rectangle {
                        width: 3; height: parent.height
                        color: cyan
                    }
                    Text {
                        text:
                            (batState === "charging" ? "󰂄" :
                             bat === 100 ? "󰁹 Full" :
                             bat >= 95 ? "󰁹" :
                             bat >= 75 ? "󰁾" :
                             bat >= 50 ? "󰁼" :
                             bat >= 25 ? "󰁻" : "󰁺")
                            + " " + bat + "% " + batTime
                        color: gradient(100 - bat)
                        font.family: fontFamily
                        font.pixelSize: fontSize
                    }
                }
            }
        }
    }
}


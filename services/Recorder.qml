pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed

    function start(extraArgs = []): void {
        stopGraceTimer.stop();
        props.running = true;
        props.paused = false;
        props.elapsed = 0;
        startupGraceTimer.restart();
        Quickshell.execDetached(["nilastia", "record", "--start", ...extraArgs]);
        refreshTimer.restart();
    }

    function stop(): void {
        startupGraceTimer.stop();
        stopGraceTimer.restart();
        props.running = false;
        props.paused = false;
        props.elapsed = 0;
        Quickshell.execDetached(["nilastia", "record", "--stop"]);
        refreshTimer.restart();
    }

    function togglePause(): void {
        props.paused = !props.paused;
        Quickshell.execDetached(["nilastia", "record", "-p"]);
        refreshTimer.restart();
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0

        reloadableId: "recorder"
    }

    Timer {
        id: startupGraceTimer
        interval: 3500
        repeat: false
        running: false
    }

    Timer {
        id: stopGraceTimer
        interval: 3500
        repeat: false
        running: false
    }

    Timer {
        id: refreshTimer
        interval: 300
        repeat: false
        running: false
        onTriggered: {
            if (!checkProc.running)
                checkProc.running = true;
        }
    }

    readonly property Process checkProc: Process {
        command: [
            "sh",
            "-c",
            "if pid=$(pidof wf-recorder 2>/dev/null || pidof gpu-screen-recorder 2>/dev/null); then pid=$(echo $pid | awk '{print $1}'); state=$(ps -o state= -p \"$pid\" 2>/dev/null | tr -d ' '); case \"$state\" in T*) echo 'paused' ;; *) echo 'running' ;; esac; else echo 'stopped'; fi"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                let status = line.trim();
                if (status === "running") {
                    if (!stopGraceTimer.running) {
                        props.running = true;
                        props.paused = false;
                        if (startupGraceTimer.running)
                            startupGraceTimer.stop();
                    }
                } else if (status === "paused") {
                    if (!stopGraceTimer.running) {
                        props.running = true;
                        props.paused = true;
                        if (startupGraceTimer.running)
                            startupGraceTimer.stop();
                    }
                } else if (status === "stopped") {
                    if (!startupGraceTimer.running) {
                        props.running = false;
                        props.paused = false;
                        props.elapsed = 0;
                        if (stopGraceTimer.running)
                            stopGraceTimer.stop();
                    }
                }
            }
        }
    }

    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        running: props.running && !props.paused
        onTriggered: props.elapsed++
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkProc.running)
                checkProc.running = true;
        }
    }
}

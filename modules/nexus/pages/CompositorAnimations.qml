import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import Caelestia.Services
import qs.modules.nexus.common

PageBase {
    id: root
    isSubPage: true

    title: qsTr("Animations")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Global animation settings
        SectionHeader {
            first: true
            text: qsTr("Global Animation Options")
        }

        ToggleRow {
            first: true
            text: qsTr("Enable desktop animations")
            subtext: qsTr("Toggle compositor animation transitions globally")
            checked: !Compositor.animations_off
            onToggled: Compositor.saveValue("animations_off", !checked)
        }

        StepperRow {
            last: true
            label: qsTr("Slowdown multiplier")
            subtext: qsTr("Increases animation durations globally (1.0 is default)")
            value: Compositor.animations_slowdown
            from: 0.1
            to: 10.0
            stepSize: 0.1
            onMoved: v => Compositor.saveValue("animations_slowdown", parseFloat(v.toFixed(1)))
        }

        // Workspace Transitions
        SectionHeader {
            text: qsTr("Workspace Switching")
        }

        StepperRow {
            first: true
            label: qsTr("Switch damping ratio")
            subtext: qsTr("Workspace bounce level (< 1.0 bouncy, 1.0 neutral, > 1.0 sluggish)")
            value: Compositor.ws_damping
            from: 0.05
            to: 2.0
            stepSize: 0.05
            onMoved: v => Compositor.saveValue("ws_damping", parseFloat(v.toFixed(2)))
        }

        StepperRow {
            last: true
            label: qsTr("Switch stiffness")
            subtext: qsTr("Spring snappiness speed (300 soft, 900+ responsive)")
            value: Compositor.ws_stiffness
            from: 50
            to: 2000
            stepSize: 50
            onMoved: v => Compositor.saveValue("ws_stiffness", Math.round(v))
        }

        // Window Open
        SectionHeader {
            text: qsTr("Window Open Transitions")
        }

        StepperRow {
            first: true
            label: qsTr("Open damping ratio")
            subtext: qsTr("Window expansion bounce level (< 1.0 bouncy, 1.0 neutral)")
            value: Compositor.win_open_damping
            from: 0.05
            to: 2.0
            stepSize: 0.05
            onMoved: v => Compositor.saveValue("win_open_damping", parseFloat(v.toFixed(2)))
        }

        StepperRow {
            last: true
            label: qsTr("Open stiffness")
            subtext: qsTr("Window entry snap speed (300 standard, 600 snappy)")
            value: Compositor.win_open_stiffness
            from: 50
            to: 2000
            stepSize: 50
            onMoved: v => Compositor.saveValue("win_open_stiffness", Math.round(v))
        }

        // Window Close
        SectionHeader {
            text: qsTr("Window Close Transitions")
        }

        StepperRow {
            first: true
            label: qsTr("Close damping ratio")
            subtext: qsTr("Window exit fade bounce level")
            value: Compositor.win_close_damping
            from: 0.05
            to: 2.0
            stepSize: 0.05
            onMoved: v => Compositor.saveValue("win_close_damping", parseFloat(v.toFixed(2)))
        }

        StepperRow {
            last: true
            label: qsTr("Close stiffness")
            subtext: qsTr("Window exit speed (300 standard)")
            value: Compositor.win_close_stiffness
            from: 50
            to: 2000
            stepSize: 50
            onMoved: v => Compositor.saveValue("win_close_stiffness", Math.round(v))
        }

        // Window Resize
        SectionHeader {
            text: qsTr("Window Resize Animations")
        }

        StepperRow {
            first: true
            label: qsTr("Resize damping ratio")
            subtext: qsTr("Window border resize bounce level")
            value: Compositor.resize_damping
            from: 0.05
            to: 2.0
            stepSize: 0.05
            onMoved: v => Compositor.saveValue("resize_damping", parseFloat(v.toFixed(2)))
        }

        StepperRow {
            last: true
            label: qsTr("Resize stiffness")
            subtext: qsTr("Border resize animation track speed")
            value: Compositor.resize_stiffness
            from: 50
            to: 2000
            stepSize: 50
            onMoved: v => Compositor.saveValue("resize_stiffness", Math.round(v))
        }
    }
}

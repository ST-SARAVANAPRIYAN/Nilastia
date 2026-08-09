import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import Caelestia.Services
import qs.components
import qs.modules.nexus.common

PageBase {
    id: root
    isSubPage: true

    readonly property list<MenuItem> clickMethodOptions: [
        MenuItem { text: qsTr("Button Areas") },
        MenuItem { text: qsTr("Clickfinger") }
    ]
    readonly property list<string> clickMethodValues: ["button-areas", "clickfinger"]

    readonly property list<MenuItem> accelProfileOptions: [
        MenuItem { text: qsTr("Flat (No Accel)") },
        MenuItem { text: qsTr("Adaptive") }
    ]
    readonly property list<string> accelProfileValues: ["flat", "adaptive"]

    function valueToClickMethodIndex(val: string): int {
        const idx = clickMethodValues.indexOf(val);
        return idx !== -1 ? idx : 0;
    }

    function valueToAccelProfileIndex(val: string): int {
        const idx = accelProfileValues.indexOf(val);
        return idx !== -1 ? idx : 0;
    }

    title: qsTr("Input Devices")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Keyboard
        SectionHeader {
            first: true
            text: qsTr("Keyboard")
        }

        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: kbLayoutLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: kbLayoutLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: qsTr("Keyboard layout")
                        font: Tokens.font.body.medium
                    }
                    StyledText {
                        text: qsTr("XKB layout strings (comma-separated, e.g. us,es)")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                StyledTextField {
                    Layout.preferredWidth: 150
                    text: Compositor.kb_layout
                    placeholderText: "us"
                    onEditingFinished: {
                        if (text.trim() !== "") {
                            Compositor.saveValue("kb_layout", text.trim());
                        }
                    }
                }
            }
        }

        StepperRow {
            label: qsTr("Repeat delay")
            subtext: qsTr("Time before keys start repeating (ms)")
            value: Compositor.kb_repeat_delay
            from: 100
            to: 1000
            stepSize: 50
            onMoved: v => Compositor.saveValue("kb_repeat_delay", Math.round(v))
        }

        StepperRow {
            last: true
            label: qsTr("Repeat rate")
            subtext: qsTr("Repeated key strokes per second (chars/s)")
            value: Compositor.kb_repeat_rate
            from: 10
            to: 150
            stepSize: 5
            onMoved: v => Compositor.saveValue("kb_repeat_rate", Math.round(v))
        }

        // Touchpad
        SectionHeader {
            text: qsTr("Touchpad")
        }

        ToggleRow {
            first: true
            text: qsTr("Tap to click")
            subtext: qsTr("Tap touchpad surface instead of pressing down")
            checked: Compositor.touchpad_tap
            onToggled: Compositor.saveValue("touchpad_tap", checked)
        }

        ToggleRow {
            text: qsTr("Natural scrolling")
            subtext: qsTr("Reverse touchpad scrolling direction (drag content)")
            checked: Compositor.touchpad_natural_scroll
            onToggled: Compositor.saveValue("touchpad_natural_scroll", checked)
        }

        SelectRow {
            label: qsTr("Click method")
            subtext: qsTr("How secondary and middle clicks are triggered")
            menuItems: root.clickMethodOptions
            active: root.clickMethodOptions[root.valueToClickMethodIndex(Compositor.touchpad_click_method)]
            onSelected: item => Compositor.saveValue("touchpad_click_method", root.clickMethodValues[root.clickMethodOptions.indexOf(item)])
        }

        StepperRow {
            last: true
            label: qsTr("Touchpad pointer speed")
            subtext: qsTr("Cursor sensitivity modifier (-1.0 to 1.0)")
            value: Compositor.touchpad_accel_speed
            from: -1.0
            to: 1.0
            stepSize: 0.05
            onMoved: v => Compositor.saveValue("touchpad_accel_speed", parseFloat(v.toFixed(2)))
        }

        // Mouse
        SectionHeader {
            text: qsTr("Mouse")
        }

        SelectRow {
            first: true
            label: qsTr("Acceleration profile")
            subtext: qsTr("Flat ignores speed; Adaptive dynamically accelerates pointer")
            menuItems: root.accelProfileOptions
            active: root.accelProfileOptions[root.valueToAccelProfileIndex(Compositor.mouse_accel_profile)]
            onSelected: item => Compositor.saveValue("mouse_accel_profile", root.accelProfileValues[root.accelProfileOptions.indexOf(item)])
        }

        StepperRow {
            last: true
            label: qsTr("Mouse pointer speed")
            subtext: qsTr("Cursor sensitivity modifier (-1.0 to 1.0)")
            value: Compositor.mouse_accel_speed
            from: -1.0
            to: 1.0
            stepSize: 0.05
            onMoved: v => Compositor.saveValue("mouse_accel_speed", parseFloat(v.toFixed(2)))
        }

        // Cursor
        SectionHeader {
            text: qsTr("Cursor Styling & Focus")
        }

        ToggleRow {
            first: true
            text: qsTr("Warp cursor to focus")
            subtext: qsTr("Move pointer to center of newly focused windows")
            checked: Compositor.warp_mouse_to_focus
            onToggled: Compositor.saveValue("warp_mouse_to_focus", checked)
        }

        ToggleRow {
            text: qsTr("Focus follows mouse")
            subtext: qsTr("Activate windows automatically on mouse hover")
            checked: Compositor.focus_follows_mouse
            onToggled: Compositor.saveValue("focus_follows_mouse", checked)
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: themeRowLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: themeRowLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: qsTr("Cursor theme")
                        font: Tokens.font.body.medium
                    }
                    StyledText {
                        text: qsTr("Name of target XCursor theme")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                StyledTextField {
                    Layout.preferredWidth: 150
                    text: Compositor.cursor_theme
                    placeholderText: "default"
                    onEditingFinished: {
                        if (text.trim() !== "") {
                            Compositor.saveValue("cursor_theme", text.trim());
                        }
                    }
                }
            }
        }

        StepperRow {
            label: qsTr("Cursor size")
            subtext: qsTr("Size of pointer graphics (px)")
            value: Compositor.cursor_size
            from: 8
            to: 96
            stepSize: 4
            onMoved: v => Compositor.saveValue("cursor_size", Math.round(v))
        }

        ToggleRow {
            last: true
            text: qsTr("Hide cursor when typing")
            subtext: qsTr("Fade pointer away when writing text in windows")
            checked: Compositor.cursor_hide_when_typing
            onToggled: Compositor.saveValue("cursor_hide_when_typing", checked)
        }
    }
}

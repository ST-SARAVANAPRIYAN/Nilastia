pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property string colorValue: "#ffffff"
    signal colorSelected(string hex)

    property bool showAlpha: true
    property bool showPresets: true

    property real currentH: 0.0
    property real currentS: 1.0
    property real currentV: 1.0
    property real currentA: 1.0

    property bool internalSync: false
    property bool copiedFeedback: false

    function parseHex(hex) {
        if (!hex) return { r: 1, g: 1, b: 1, a: 1 };
        let c = hex.toString().trim().replace(/^#/, "");
        if (c.length === 3) {
            c = c[0] + c[0] + c[1] + c[1] + c[2] + c[2] + "ff";
        } else if (c.length === 4) {
            c = c[0] + c[0] + c[1] + c[1] + c[2] + c[2] + c[3] + c[3];
        } else if (c.length === 6) {
            c += "ff";
        } else if (c.length !== 8) {
            return { r: 1, g: 1, b: 1, a: 1 };
        }
        const r = parseInt(c.substring(0, 2), 16) / 255.0;
        const g = parseInt(c.substring(2, 4), 16) / 255.0;
        const b = parseInt(c.substring(4, 6), 16) / 255.0;
        const a = parseInt(c.substring(6, 8), 16) / 255.0;
        return {
            r: isNaN(r) ? 1.0 : Math.max(0, Math.min(1, r)),
            g: isNaN(g) ? 1.0 : Math.max(0, Math.min(1, g)),
            b: isNaN(b) ? 1.0 : Math.max(0, Math.min(1, b)),
            a: isNaN(a) ? 1.0 : Math.max(0, Math.min(1, a))
        };
    }

    function rgbToHsv(r, g, b) {
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const d = max - min;
        let h = 0;
        const s = max === 0 ? 0 : d / max;
        const v = max;
        if (max !== min) {
            if (max === r) {
                h = (g - b) / d + (g < b ? 6 : 0);
            } else if (max === g) {
                h = (b - r) / d + 2;
            } else {
                h = (r - g) / d + 4;
            }
            h /= 6.0;
        }
        return { h: h, s: s, v: v };
    }

    function hsvToRgb(h, s, v) {
        let r, g, b;
        const i = Math.floor(h * 6.0);
        const f = h * 6.0 - i;
        const p = v * (1.0 - s);
        const q = v * (1.0 - f * s);
        const t = v * (1.0 - (1.0 - f) * s);
        switch (i % 6) {
            case 0: r = v; g = t; b = p; break;
            case 1: r = q; g = v; b = p; break;
            case 2: r = p; g = v; b = t; break;
            case 3: r = p; g = q; b = v; break;
            case 4: r = t; g = p; b = v; break;
            case 5: r = v; g = p; b = q; break;
            default: r = v; g = t; b = p; break;
        }
        return {
            r: Math.max(0, Math.min(1, r)),
            g: Math.max(0, Math.min(1, g)),
            b: Math.max(0, Math.min(1, b))
        };
    }

    function toHex(r, g, b, a) {
        const hexR = Math.min(255, Math.max(0, Math.round(r * 255.0))).toString(16).padStart(2, '0');
        const hexG = Math.min(255, Math.max(0, Math.round(g * 255.0))).toString(16).padStart(2, '0');
        const hexB = Math.min(255, Math.max(0, Math.round(b * 255.0))).toString(16).padStart(2, '0');
        const hexA = Math.min(255, Math.max(0, Math.round(a * 255.0))).toString(16).padStart(2, '0');
        if (hexA === "ff") {
            return "#" + hexR + hexG + hexB;
        }
        return "#" + hexR + hexG + hexB + hexA;
    }

    function syncFromExternalColor() {
        if (internalSync) return;
        const parsed = parseHex(colorValue);
        const hsv = rgbToHsv(parsed.r, parsed.g, parsed.b);
        internalSync = true;
        currentH = hsv.h;
        currentS = hsv.s;
        currentV = hsv.v;
        currentA = parsed.a;
        internalSync = false;
    }

    function emitColorUpdate() {
        if (internalSync) return;
        internalSync = true;
        const rgb = hsvToRgb(currentH, currentS, currentV);
        const hex = toHex(rgb.r, rgb.g, rgb.b, root.showAlpha ? currentA : 1.0);
        root.colorValue = hex;
        root.colorSelected(hex);
        internalSync = false;
    }

    function applyPreset(presetHex) {
        const parsed = parseHex(presetHex);
        const hsv = rgbToHsv(parsed.r, parsed.g, parsed.b);
        internalSync = true;
        currentH = hsv.h;
        currentS = hsv.s;
        currentV = hsv.v;
        currentA = parsed.a;
        const hex = toHex(parsed.r, parsed.g, parsed.b, root.showAlpha ? currentA : 1.0);
        root.colorValue = hex;
        root.colorSelected(hex);
        internalSync = false;
    }

    onColorValueChanged: syncFromExternalColor()
    Component.onCompleted: syncFromExternalColor()

    readonly property color currentRgbColor: {
        const rgb = hsvToRgb(currentH, currentS, currentV);
        return Qt.rgba(rgb.r, rgb.g, rgb.b, 1.0);
    }

    readonly property color currentRgbaColor: {
        const rgb = hsvToRgb(currentH, currentS, currentV);
        return Qt.rgba(rgb.r, rgb.g, rgb.b, root.showAlpha ? currentA : 1.0);
    }

    implicitWidth: 320
    implicitHeight: mainCol.implicitHeight

    ColumnLayout {
        id: mainCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Tokens.spacing.medium

        // 2D Saturation-Value Color Area
        Item {
            id: colorAreaContainer
            Layout.fillWidth: true
            height: 160

            Rectangle {
                id: colorAreaBox
                anchors.fill: parent
                radius: Tokens.rounding.medium
                clip: true
                color: Qt.hsva(root.currentH, 1.0, 1.0, 1.0)
                border.color: Colours.palette.m3outlineVariant
                border.width: 1

                // Horizontal gradient: White (S=0) to Transparent (S=1)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ffffff" }
                        GradientStop { position: 1.0; color: "#00ffffff" }
                    }
                }

                // Vertical gradient: Transparent (V=1) to Black (V=0)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                }

                // Interactive 2D reticle crosshair handle
                Rectangle {
                    id: areaHandle
                    width: 20
                    height: 20
                    radius: 10
                    x: Math.max(0, Math.min(colorAreaBox.width - width, root.currentS * colorAreaBox.width - width / 2))
                    y: Math.max(0, Math.min(colorAreaBox.height - height, (1.0 - root.currentV) * colorAreaBox.height - height / 2))
                    color: root.currentRgbColor
                    border.color: "#ffffff"
                    border.width: 2

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: 11
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.45)
                        border.width: 1
                        z: -1
                    }
                }

                MouseArea {
                    id: areaMouse
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: Qt.CrossCursor

                    function updatePos(mouse) {
                        const s = Math.max(0, Math.min(1.0, mouse.x / width));
                        const v = Math.max(0, Math.min(1.0, 1.0 - (mouse.y / height)));
                        root.currentS = s;
                        root.currentV = v;
                        root.emitColorUpdate();
                    }

                    onPressed: mouse => updatePos(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) updatePos(mouse);
                    }
                }
            }
        }

        // Rainbow Hue Slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Hue Spectrum")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: Math.round(root.currentH * 360) + "°"
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Rectangle {
                id: hueSliderTrack
                Layout.fillWidth: true
                height: 18
                radius: 9
                border.color: Colours.palette.m3outlineVariant
                border.width: 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.00; color: "#ff0000" }
                    GradientStop { position: 0.17; color: "#ffff00" }
                    GradientStop { position: 0.33; color: "#00ff00" }
                    GradientStop { position: 0.50; color: "#00ffff" }
                    GradientStop { position: 0.67; color: "#0000ff" }
                    GradientStop { position: 0.83; color: "#ff00ff" }
                    GradientStop { position: 1.00; color: "#ff0000" }
                }

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, root.currentH * (parent.width - width)))
                    color: Qt.hsva(root.currentH, 1.0, 1.0, 1.0)
                    border.color: "#ffffff"
                    border.width: 2

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: 12
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.4)
                        border.width: 1
                        z: -1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor

                    function updateHue(mouse) {
                        const h = Math.max(0, Math.min(1.0, mouse.x / width));
                        root.currentH = h;
                        root.emitColorUpdate();
                    }

                    onPressed: mouse => updateHue(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) updateHue(mouse);
                    }
                }
            }
        }

        // Opacity / Alpha Slider with Checkerboard Track
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.showAlpha
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Opacity")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: Math.round(root.currentA * 100) + "%"
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                id: alphaTrackBox
                Layout.fillWidth: true
                height: 18

                // Checkerboard pattern background
                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    clip: true
                    color: "#2a2a2a"

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d");
                            const sz = 6;
                            for (let y = 0; y < height; y += sz) {
                                for (let x = 0; x < width; x += sz) {
                                    ctx.fillStyle = ((Math.floor(x / sz) + Math.floor(y / sz)) % 2 === 0) ? "#444444" : "#222222";
                                    ctx.fillRect(x, y, sz, sz);
                                }
                            }
                        }
                    }

                    // Linear alpha gradient overlay
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: {
                                    const rgb = root.hsvToRgb(root.currentH, root.currentS, root.currentV);
                                    return Qt.rgba(rgb.r, rgb.g, rgb.b, 0.0);
                                }
                            }
                            GradientStop {
                                position: 1.0
                                color: {
                                    const rgb = root.hsvToRgb(root.currentH, root.currentS, root.currentV);
                                    return Qt.rgba(rgb.r, rgb.g, rgb.b, 1.0);
                                }
                            }
                        }
                    }

                    border.color: Colours.palette.m3outlineVariant
                    border.width: 1
                }

                // Alpha handle
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, root.currentA * (parent.width - width)))
                    color: root.currentRgbaColor
                    border.color: "#ffffff"
                    border.width: 2

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: 12
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.4)
                        border.width: 1
                        z: -1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor

                    function updateAlpha(mouse) {
                        const a = Math.max(0, Math.min(1.0, mouse.x / width));
                        root.currentA = a;
                        root.emitColorUpdate();
                    }

                    onPressed: mouse => updateAlpha(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) updateAlpha(mouse);
                    }
                }
            }
        }

        // Live Preview, Hex Code Input & Copy Action Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            // Swatch Box over Checkerboard
            Rectangle {
                width: 40
                height: 40
                radius: Tokens.rounding.small
                color: "#2a2a2a"
                clip: true
                border.color: Colours.palette.m3outline
                border.width: 1

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        const sz = 5;
                        for (let y = 0; y < height; y += sz) {
                            for (let x = 0; x < width; x += sz) {
                                ctx.fillStyle = ((Math.floor(x / sz) + Math.floor(y / sz)) % 2 === 0) ? "#444444" : "#222222";
                                ctx.fillRect(x, y, sz, sz);
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.currentRgbaColor
                }
            }

            // Editable Hex Field
            StyledTextField {
                id: hexField
                Layout.fillWidth: true
                text: root.colorValue
                placeholderText: "#ffffff"
                onEditingFinished: {
                    if (text.startsWith("#") && (text.length === 4 || text.length === 5 || text.length === 7 || text.length === 9)) {
                        root.applyPreset(text);
                    }
                }
            }

            // Copy to Clipboard Button
            Rectangle {
                width: 40
                height: 40
                radius: Tokens.rounding.small
                color: copyMouse.containsMouse ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHighest
                border.color: Colours.palette.m3outlineVariant
                border.width: 1

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.copiedFeedback ? "done" : "content_copy"
                    color: root.copiedFeedback ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                Timer {
                    id: copyTimer
                    interval: 1600
                    onTriggered: root.copiedFeedback = false
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.clipboardText = root.colorValue;
                        Quickshell.execDetached(["wl-copy", root.colorValue]);
                        root.copiedFeedback = true;
                        copyTimer.restart();
                    }
                }
            }
        }

        // Numerical Value Badges
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHighest

                StyledText {
                    anchors.centerIn: parent
                    text: "HSV: " + Math.round(root.currentH * 360) + "°, " + Math.round(root.currentS * 100) + "%, " + Math.round(root.currentV * 100) + "%"
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHighest

                StyledText {
                    anchors.centerIn: parent
                    text: {
                        const rgb = root.hsvToRgb(root.currentH, root.currentS, root.currentV);
                        return "RGB: " + Math.round(rgb.r * 255) + ", " + Math.round(rgb.g * 255) + ", " + Math.round(rgb.b * 255);
                    }
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        // Presets: System Material 3 Tokens
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.showPresets
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: qsTr("System Theme Tokens")
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { label: qsTr("Primary"), color: Colours.palette.m3primary },
                        { label: qsTr("Secondary"), color: Colours.palette.m3secondary },
                        { label: qsTr("Tertiary"), color: Colours.palette.m3tertiary },
                        { label: qsTr("Outline"), color: Colours.palette.m3outline },
                        { label: qsTr("Container"), color: Colours.palette.m3primaryContainer },
                        { label: qsTr("InvPrimary"), color: Colours.palette.m3inversePrimary }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        height: 28
                        radius: Tokens.rounding.small
                        color: modelData.color
                        border.color: Colours.palette.m3outline
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyPreset(parent.modelData.color.toString())
                        }
                    }
                }
            }
        }

        // Presets: Curated Accents
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.showPresets
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: qsTr("Palette Swatches")
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        "#f38ba8", // Red
                        "#fab387", // Peach
                        "#f9e2af", // Yellow
                        "#a6e3a1", // Green
                        "#94e2d5", // Teal
                        "#89dceb", // Sky
                        "#89b4fa", // Blue
                        "#cba6f7", // Mauve
                        "#f5c2e7", // Pink
                        "#eba0ac", // Rose
                        "#ffffff", // White
                        "#bac2de", // Silver
                        "#6c7086", // Slate
                        "#313244", // Deep Charcoal
                        "#11111b", // Dark
                        "#000000"  // Black
                    ]

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        width: 26
                        height: 26
                        radius: 13
                        color: modelData
                        border.color: root.colorValue.toLowerCase() === modelData.toLowerCase() ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                        border.width: root.colorValue.toLowerCase() === modelData.toLowerCase() ? 2 : 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyPreset(parent.modelData)
                        }
                    }
                }
            }
        }
    }
}

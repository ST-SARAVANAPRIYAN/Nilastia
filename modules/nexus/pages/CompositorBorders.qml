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

    title: qsTr("Borders & Focus Ring")

    // Helper component for interactive color editing with HSL sliders & presets
    component ColorConfigRow : ConnectedRect {
        id: colorRow
        property string label
        property string propertyName
        property string colorValue: Compositor[propertyName]
        property bool expanded: false

        property var parsedColor: parseHex(colorValue)
        property var hslColor: rgbToHsl(parsedColor.r, parsedColor.g, parsedColor.b)

        function parseHex(hex) {
            if (!hex) return { r: 128, g: 128, b: 128, a: 255 };
            let clean = hex.replace("#", "");
            if (clean.length === 3) {
                clean = clean[0]+clean[0] + clean[1]+clean[1] + clean[2]+clean[2] + "ff";
            } else if (clean.length === 4) {
                clean = clean[0]+clean[0] + clean[1]+clean[1] + clean[2]+clean[2] + clean[3]+clean[3];
            } else if (clean.length === 6) {
                clean += "ff";
            } else if (clean.length === 8) {
                // ok
            } else {
                return { r: 128, g: 128, b: 128, a: 255 };
            }
            return {
                r: parseInt(clean.substring(0, 2), 16),
                g: parseInt(clean.substring(2, 4), 16),
                b: parseInt(clean.substring(4, 6), 16),
                a: parseInt(clean.substring(6, 8), 16)
            };
        }

        function toHex(r, g, b, a) {
            const hexR = Math.round(r).toString(16).padStart(2, '0');
            const hexG = Math.round(g).toString(16).padStart(2, '0');
            const hexB = Math.round(b).toString(16).padStart(2, '0');
            const hexA = Math.round(a).toString(16).padStart(2, '0');
            if (hexA === "ff") {
                return "#" + hexR + hexG + hexB;
            }
            return "#" + hexR + hexG + hexB + hexA;
        }

        function rgbToHsl(r, g, b) {
            r /= 255;
            g /= 255;
            b /= 255;
            const max = Math.max(r, g, b);
            const min = Math.min(r, g, b);
            let h, s, l = (max + min) / 2;
            if (max === min) {
                h = s = 0;
            } else {
                const d = max - min;
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                if (max === r) {
                    h = (g - b) / d + (g < b ? 6 : 0);
                } else if (max === g) {
                    h = (b - r) / d + 2;
                } else {
                    h = (r - g) / d + 4;
                }
                h /= 6;
            }
            return {
                h: Math.round(h * 360),
                s: Math.round(s * 100),
                l: Math.round(l * 100)
            };
        }

        function hslToRgb(h, s, l) {
            h /= 360;
            s /= 100;
            l /= 100;
            let r, g, b;
            if (s === 0) {
                r = g = b = l;
            } else {
                const hue2rgb = (p, q, t) => {
                    if (t < 0) t += 1;
                    if (t > 1) t -= 1;
                    if (t < 1/6) return p + (q - p) * 6 * t;
                    if (t < 1/2) return q;
                    if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                    return p;
                };
                const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
                const p = 2 * l - q;
                r = hue2rgb(p, q, h + 1/3);
                g = hue2rgb(p, q, h);
                b = hue2rgb(p, q, h - 1/3);
            }
            return {
                r: Math.round(r * 255),
                g: Math.round(g * 255),
                b: Math.round(b * 255)
            };
        }

        Layout.fillWidth: true
        implicitHeight: mainColumn.implicitHeight + Tokens.padding.medium * 2

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: colorRow.expanded = !colorRow.expanded
        }

        ColumnLayout {
            id: mainColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            RowLayout {
                id: layout
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: colorRow.label
                        font: Tokens.font.body.medium
                    }
                    StyledText {
                        text: qsTr("Hex Color Code")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                // Interactive Color controls
                RowLayout {
                    spacing: Tokens.spacing.small

                    MouseArea {
                        width: rowControls.width
                        height: rowControls.height
                        onClicked: {} // Consume clicks to avoid toggling expanded state
                        
                        RowLayout {
                            id: rowControls
                            spacing: Tokens.spacing.small

                            // Color circle preview
                            Rectangle {
                                width: 32
                                height: 32
                                radius: Tokens.rounding.small
                                color: {
                                    try {
                                        return colorRow.colorValue || "transparent";
                                    } catch(e) {
                                        return "transparent";
                                    }
                                }
                                border.color: Colours.palette.m3outline
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: colorRow.expanded = !colorRow.expanded
                                }
                            }

                            StyledTextField {
                                Layout.preferredWidth: 120
                                text: colorRow.colorValue
                                placeholderText: "#ffffff"
                                onEditingFinished: {
                                    if (text.startsWith("#") && (text.length === 4 || text.length === 7 || text.length === 9)) {
                                        Compositor.saveValue(colorRow.propertyName, text);
                                    }
                                }
                            }
                        }
                    }

                    // Rotating expand/collapse arrow icon
                    MaterialIcon {
                        text: "expand_more"
                        fontStyle: Tokens.font.icon.medium
                        color: Colours.palette.m3onSurfaceVariant
                        rotation: colorRow.expanded ? 180 : 0
                        Behavior on rotation {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }

            // Expandable color picker
            ColumnLayout {
                Layout.fillWidth: true
                visible: colorRow.expanded
                spacing: Tokens.spacing.medium

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }

                // Preset palette (combines active theme colors + basic values)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small
                    StyledText {
                        text: qsTr("Presets:")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small
                        Repeater {
                            model: [
                                Colours.palette.m3primary,
                                Colours.palette.m3secondary,
                                Colours.palette.m3tertiary,
                                Colours.palette.m3outline,
                                "#f38ba8", // Red
                                "#fab387", // Peach
                                "#a6e3a1", // Green
                                "#94e2d5", // Teal
                                "#89b4fa", // Blue
                                "#cba6f7", // Mauve
                                "#ffffff", // White
                                "#808080"  // Gray
                            ]
                            delegate: Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: modelData
                                border.color: Colours.palette.m3outline
                                border.width: 1
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Compositor.saveValue(colorRow.propertyName, modelData);
                                    }
                                }
                            }
                        }
                    }
                }

                // User-friendly HSL sliders
                GridLayout {
                    columns: 3
                    Layout.fillWidth: true
                    columnSpacing: Tokens.spacing.medium
                    rowSpacing: Tokens.spacing.small

                    // Hue slider
                    StyledText {
                        text: qsTr("Hue (%1°)").arg(colorRow.hslColor.h)
                        font: Tokens.font.label.small
                        Layout.preferredWidth: 95
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        radius: Tokens.rounding.small
                        value: colorRow.hslColor.h / 360
                        onInteraction: (v) => {
                            var rgb = colorRow.hslToRgb(v * 360, colorRow.hslColor.s, colorRow.hslColor.l);
                            Compositor.saveValue(colorRow.propertyName, colorRow.toHex(rgb.r, rgb.g, rgb.b, colorRow.parsedColor.a));
                        }
                    }
                    Rectangle { width: 12; height: 12; radius: 6; color: Colours.palette.m3primary; border.color: Colours.palette.m3outline; border.width: 1 }

                    // Saturation slider
                    StyledText {
                        text: qsTr("Saturation (%1%)").arg(colorRow.hslColor.s)
                        font: Tokens.font.label.small
                        Layout.preferredWidth: 95
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        radius: Tokens.rounding.small
                        value: colorRow.hslColor.s / 100
                        onInteraction: (v) => {
                            var rgb = colorRow.hslToRgb(colorRow.hslColor.h, v * 100, colorRow.hslColor.l);
                            Compositor.saveValue(colorRow.propertyName, colorRow.toHex(rgb.r, rgb.g, rgb.b, colorRow.parsedColor.a));
                        }
                    }
                    Rectangle { width: 12; height: 12; radius: 6; color: "#a6e3a1"; border.color: Colours.palette.m3outline; border.width: 1 }

                    // Lightness slider
                    StyledText {
                        text: qsTr("Lightness (%1%)").arg(colorRow.hslColor.l)
                        font: Tokens.font.label.small
                        Layout.preferredWidth: 95
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        radius: Tokens.rounding.small
                        value: colorRow.hslColor.l / 100
                        onInteraction: (v) => {
                            var rgb = colorRow.hslToRgb(colorRow.hslColor.h, colorRow.hslColor.s, v * 100);
                            Compositor.saveValue(colorRow.propertyName, colorRow.toHex(rgb.r, rgb.g, rgb.b, colorRow.parsedColor.a));
                        }
                    }
                    Rectangle { width: 12; height: 12; radius: 6; color: "#ffffff"; border.color: Colours.palette.m3outline; border.width: 1 }

                    // Alpha / Opacity slider
                    StyledText {
                        text: qsTr("Opacity (%1%)").arg(Math.round(colorRow.parsedColor.a / 2.55))
                        font: Tokens.font.label.small
                        Layout.preferredWidth: 95
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        radius: Tokens.rounding.small
                        value: colorRow.parsedColor.a / 255
                        onInteraction: (v) => {
                            var c = colorRow.parsedColor;
                            Compositor.saveValue(colorRow.propertyName, colorRow.toHex(c.r, c.g, c.b, v * 255));
                        }
                    }
                    Rectangle { width: 12; height: 12; radius: 6; color: "transparent"; border.color: Colours.palette.m3outline; border.width: 1 }
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Window Geometry
        SectionHeader {
            first: true
            text: qsTr("Window Geometry")
        }

        StepperRow {
            first: true
            label: qsTr("Corner radius")
            subtext: qsTr("Rounding applied to window corners (px)")
            value: Compositor.corner_radius
            from: 0
            to: 40
            stepSize: 1
            onMoved: (value) => Compositor.saveValue("corner_radius", Math.round(value))
        }

        ToggleRow {
            last: true
            text: qsTr("Clip to rounded geometry")
            subtext: qsTr("Force window content to conform to rounded corners")
            checked: Compositor.clip_to_geometry
            onToggled: Compositor.saveValue("clip_to_geometry", checked)
        }

        // Focus Ring
        SectionHeader {
            text: qsTr("Focus Ring")
        }

        StepperRow {
            first: true
            label: qsTr("Focus ring width")
            subtext: qsTr("Thickness of active window outline (px)")
            value: Compositor.focus_ring_width
            from: 0
            to: 20
            stepSize: 1
            onMoved: (value) => Compositor.saveValue("focus_ring_width", Math.round(value))
        }

        ColorConfigRow {
            label: qsTr("Active focus ring color")
            propertyName: "focus_ring_active"
        }

        ColorConfigRow {
            last: true
            label: qsTr("Inactive focus ring color")
            propertyName: "focus_ring_inactive"
        }

        // Borders
        SectionHeader {
            text: qsTr("Borders")
        }

        ToggleRow {
            first: true
            text: qsTr("Enable borders")
            subtext: qsTr("Draw static outlines around all tiling columns")
            checked: Compositor.border_enabled
            onToggled: Compositor.saveValue("border_enabled", checked)
        }

        StepperRow {
            label: qsTr("Border width")
            subtext: qsTr("Thickness of static window borders (px)")
            value: Compositor.border_width
            from: 0
            to: 20
            stepSize: 1
            onMoved: (value) => Compositor.saveValue("border_width", Math.round(value))
        }

        ColorConfigRow {
            label: qsTr("Active border color")
            propertyName: "border_active"
        }

        ColorConfigRow {
            last: true
            label: qsTr("Inactive border color")
            propertyName: "border_inactive"
        }

        // Shadows
        SectionHeader {
            text: qsTr("Drop Shadows")
        }

        ToggleRow {
            first: true
            text: qsTr("Enable drop shadows")
            subtext: qsTr("Render shadows behind tiling window frames")
            checked: Compositor.shadow_enabled
            onToggled: Compositor.saveValue("shadow_enabled", checked)
        }

        StepperRow {
            label: qsTr("Shadow softness")
            subtext: qsTr("Blur radius for window shadows (px)")
            value: Compositor.shadow_softness
            from: 0
            to: 100
            stepSize: 2
            onMoved: (value) => Compositor.saveValue("shadow_softness", Math.round(value))
        }

        StepperRow {
            label: qsTr("Shadow spread")
            subtext: qsTr("Outer size expansion of window shadows (px)")
            value: Compositor.shadow_spread
            from: -20
            to: 50
            stepSize: 1
            onMoved: (value) => Compositor.saveValue("shadow_spread", Math.round(value))
        }

        ColorConfigRow {
            last: true
            label: qsTr("Shadow color")
            propertyName: "shadow_color"
        }
    }
}

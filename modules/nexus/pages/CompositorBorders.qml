import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components.controls
import Nilastia.Services
import qs.components
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root
    isSubPage: true

    title: qsTr("Borders & Focus Ring")

    // Helper component for interactive color editing with advanced ColorPicker
    component ColorConfigRow : ConnectedRect {
        id: colorRow
        property string label
        property string propertyName
        property string colorValue: Compositor[propertyName]
        property bool expanded: false

        Layout.fillWidth: true
        implicitHeight: mainColumn.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: mainColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            // Header summary row
            RowLayout {
                id: layout
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                MouseArea {
                    Layout.fillWidth: true
                    implicitHeight: titleCol.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: colorRow.expanded = !colorRow.expanded

                    ColumnLayout {
                        id: titleCol
                        anchors.fill: parent
                        spacing: 2

                        StyledText {
                            text: colorRow.label
                            font: Tokens.font.body.medium
                        }

                        StyledText {
                            text: colorRow.colorValue ? colorRow.colorValue.toUpperCase() : qsTr("Not set")
                            color: {
                                const c = Colours.palette.m3onSurfaceVariant;
                                return Colours.getLuminance(c) < 0.35 ? Colours.palette.m3onSurface : c;
                            }
                            font: Tokens.font.label.small
                        }
                    }
                }

                // Interactive Color badge & expand arrow
                RowLayout {
                    spacing: Tokens.spacing.small

                    // Color swatch pill
                    Rectangle {
                        width: 36
                        height: 28
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

                    // Rotating expand/collapse arrow icon
                    MaterialIcon {
                        text: "expand_more"
                        fontStyle: Tokens.font.icon.medium
                        color: Colours.palette.m3onSurfaceVariant
                        rotation: colorRow.expanded ? 180 : 0
                        Behavior on rotation {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: colorRow.expanded = !colorRow.expanded
                        }
                    }
                }
            }

            // Expandable advanced color picker
            ColumnLayout {
                Layout.fillWidth: true
                visible: colorRow.expanded
                spacing: Tokens.spacing.small

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colours.palette.m3outlineVariant
                }

                ColorPicker {
                    Layout.fillWidth: true
                    colorValue: colorRow.colorValue
                    onColorSelected: hex => {
                        Compositor.saveValue(colorRow.propertyName, hex);
                    }
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

        ToggleRow {
            first: true
            text: qsTr("Enable focus ring")
            subtext: qsTr("Draw dynamic outline around active window (inactive color for other monitors)")
            checked: Compositor.focus_ring_enabled
            onToggled: Compositor.saveValue("focus_ring_enabled", checked)
        }

        StepperRow {
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
            label: qsTr("Inactive focus ring color (Secondary monitors)")
            propertyName: "focus_ring_inactive"
        }

        // Borders
        SectionHeader {
            text: qsTr("Borders")
        }

        ToggleRow {
            first: true
            text: qsTr("Enable borders")
            subtext: qsTr("Draw static outlines around all tiling columns (active and inactive windows)")
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
            label: qsTr("Active window border color")
            propertyName: "border_active"
        }

        ColorConfigRow {
            last: true
            label: qsTr("Inactive window border color")
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

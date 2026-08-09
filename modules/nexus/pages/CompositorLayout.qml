import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components.controls
import Nilastia.Services
import qs.modules.nexus.common

PageBase {
    id: root
    isSubPage: true

    readonly property list<MenuItem> centerFocusedOptions: [
        MenuItem { text: qsTr("Never") },
        MenuItem { text: qsTr("On Overflow") },
        MenuItem { text: qsTr("Always") }
    ]
    readonly property list<string> centerFocusedValues: ["never", "on-overflow", "always"]

    readonly property list<MenuItem> displayOptions: [
        MenuItem { text: qsTr("Normal") },
        MenuItem { text: qsTr("Tabbed") }
    ]
    readonly property list<string> displayValues: ["normal", "tabbed"]

    function valueToFocusedIndex(val: string): int {
        const idx = centerFocusedValues.indexOf(val);
        return idx !== -1 ? idx : 0;
    }

    function valueToDisplayIndex(val: string): int {
        const idx = displayValues.indexOf(val);
        return idx !== -1 ? idx : 0;
    }

    title: qsTr("Layout & Tiling")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Tiling Geometry")
        }

        StepperRow {
            first: true
            label: qsTr("Gaps size")
            subtext: qsTr("Spacing between windows and screen edges (px)")
            value: Compositor.gaps
            from: 0
            to: 100
            stepSize: 1
            onMoved: (value) => Compositor.saveValue("gaps", Math.round(value))
        }

        StepperRow {
            label: qsTr("Default column width")
            subtext: qsTr("Proportion of screen width occupied by new windows")
            value: Math.round(Compositor.default_column_width * 100)
            from: 10
            to: 100
            stepSize: 5
            onMoved: (value) => Compositor.saveValue("default_column_width", value / 100)
        }

        ToggleRow {
            text: qsTr("Always center single column")
            subtext: qsTr("Keep windows centered when they are alone on a workspace")
            checked: Compositor.always_center_single_column
            onToggled: Compositor.saveValue("always_center_single_column", checked)
        }

        SelectRow {
            label: qsTr("Center focused column")
            subtext: qsTr("Scroll alignment when navigating columns")
            menuItems: root.centerFocusedOptions
            active: root.centerFocusedOptions[root.valueToFocusedIndex(Compositor.center_focused_column)]
            onSelected: item => Compositor.saveValue("center_focused_column", root.centerFocusedValues[root.centerFocusedOptions.indexOf(item)])
        }

        ToggleRow {
            text: qsTr("Empty workspace above first")
            subtext: qsTr("Open new workspaces above the first one instead of appending them")
            checked: Compositor.empty_workspace_above_first
            onToggled: Compositor.saveValue("empty_workspace_above_first", checked)
        }

        SelectRow {
            label: qsTr("Default column display")
            subtext: qsTr("Choose whether new columns open normally or in tabbed mode")
            menuItems: root.displayOptions
            active: root.displayOptions[root.valueToDisplayIndex(Compositor.default_column_display)]
            onSelected: item => Compositor.saveValue("default_column_display", root.displayValues[root.displayOptions.indexOf(item)])
        }

        StepperRow {
            last: true
            label: qsTr("Overview scale zoom")
            subtext: qsTr("Workspaces zoom level in overview mode (%)")
            value: Math.round(Compositor.overview_zoom * 100)
            from: 30
            to: 100
            stepSize: 5
            onMoved: (value) => Compositor.saveValue("overview_zoom", value / 100)
        }
    }
}

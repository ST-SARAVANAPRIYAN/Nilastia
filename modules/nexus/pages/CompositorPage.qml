import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import Nilastia.Services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Compositor")

    Component.onCompleted: {
        Compositor.load();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Compositor Customisations")
        }

        NavRow {
            first: true
            icon: "grid_view"
            text: qsTr("Layout & Tiling")
            subtext: qsTr("Manage inner/outer gaps, default widths, and center alignment")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "border_outer"
            text: qsTr("Borders & Focus Ring")
            subtext: qsTr("Configure active highlights, inactive borders and drop shadows")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "keyboard"
            text: qsTr("Input Devices")
            subtext: qsTr("Touchpad scrolling, mouse acceleration and key repeat rates")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "motion_photos_on"
            text: qsTr("Animations")
            subtext: qsTr("Spring damping, snaps, speed, and workspace transition settings")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            icon: "blur_on"
            text: qsTr("Blur & Transparency")
            subtext: qsTr("Configure compositor blur passes, active window opacity, and rules")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            last: true
            icon: "speed"
            text: qsTr("Performance")
            subtext: qsTr("Configure adaptive power saving features and display refresh rates")
            onClicked: root.nState.openSubPage(6)
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Nilastia.Config
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.clipboard

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    y: parent ? parent.height - implicitHeight + (implicitHeight + 5) * offsetScale : 0
    height: implicitHeight
    width: implicitWidth
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        asynchronous: true
        active: true
        visible: root.visible

        sourceComponent: Content {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}

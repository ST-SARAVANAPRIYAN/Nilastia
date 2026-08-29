pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Nilastia
import Nilastia.Config
import qs.components
import qs.components.filedialog
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "nilastia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "nilastia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    property real lastHeight: 400

    onImplicitHeightChanged: {
        if (implicitHeight > 0) {
            lastHeight = implicitHeight;
        }
    }

    visible: offsetScale < 1
    anchors.topMargin: (-(nonAnimHeight || lastHeight) - 5) * offsetScale
    height: implicitHeight
    width: implicitWidth
    implicitHeight: content.implicitHeight || lastHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive || root.visible
        layer.enabled: root.offsetScale > 0 && root.offsetScale < 1

        sourceComponent: Content {
            screenState: root.screenState
            facePicker: root.facePicker
        }
    }
}

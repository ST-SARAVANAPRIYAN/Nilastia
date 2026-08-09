pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates
import Quickshell
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property real nonAnimWidth
    required property ScreenState screenState
    required property var tabs

    readonly property alias count: bar.count

    property real lastMouseX: 0
    property var lastTime: 0
    property real velocity: 0

    function updateVelocity(x: real): void {
        const now = Date.now();
        const dt = now - lastTime;
        if (dt > 0 && dt < 150) {
            const dx = Math.abs(x - lastMouseX);
            velocity = dx / dt;
        } else {
            velocity = 0;
        }
        lastMouseX = x;
        lastTime = now;
    }

    implicitHeight: bar.implicitHeight + bar.anchors.topMargin + indicator.implicitHeight + indicator.anchors.topMargin + separator.implicitHeight

    TabBar {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Tokens.sizes.dashboard.tabIndicatorSpacing

        currentIndex: Math.max(0, Math.min(root.screenState.dashboardTab, root.tabs.length - 1))
        onCurrentIndexChanged: {
            if (root.screenState.dashboardTab !== currentIndex) {
                root.screenState.dashboardTab = currentIndex;
            }
        }

        implicitHeight: contentHeight
        background: null
        contentItem: RowLayout {
            spacing: 0

            Repeater {
                model: bar.contentModel
            }
        }

        Repeater {
            model: ScriptModel {
                values: root.tabs
            }

            delegate: Tab {
                required property var modelData

                iconName: modelData.iconName
                text: modelData.text
            }
        }
    }

    Item {
        id: indicator

        anchors.top: bar.bottom
        anchors.topMargin: 5

        implicitWidth: {
            const tab = bar.currentItem;
            if (tab)
                return tab.implicitWidth;
            const width = (root.nonAnimWidth - bar.spacing * (bar.count - 1)) / bar.count;
            return width;
        }
        implicitHeight: 3

        x: {
            const tab = bar.currentItem;
            const width = (root.nonAnimWidth - bar.spacing * (bar.count - 1)) / bar.count;
            const tabWidth = tab?.implicitWidth ?? width;
            return width * bar.currentIndex + (width - tabWidth) / 2;
        }

        clip: true

        StyledRect {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: parent.implicitHeight * 2

            color: Colours.palette.m3primary
            radius: Tokens.rounding.full
        }

        Behavior on x {
            Anim {}
        }

        Behavior on implicitWidth {
            Anim {}
        }
    }

    StyledRect {
        id: separator

        anchors.top: indicator.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }

    component Tab: TabButton {
        id: tab

        required property string iconName
        readonly property bool current: TabBar.tabBar.currentItem === this

        Layout.fillWidth: true
        Layout.preferredWidth: 1 // Uniform width across all tabs
        implicitWidth: implicitContentWidth
        implicitHeight: implicitContentHeight
        background: null

        contentItem: CustomMouseArea {
            id: tabMouse

            function onWheel(event: WheelEvent): void {
                if (event.angleDelta.y < 0)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, bar.count - 1);
                else if (event.angleDelta.y > 0)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
            }

            implicitWidth: Math.max(icon.width, label.width)
            implicitHeight: icon.height + label.height

            hoverEnabled: true
            cursorShape: Config.dashboard.hoverSwitchTabs ? Qt.ArrowCursor : Qt.PointingHandCursor
            Timer {
                id: hoverTimer
                interval: 120
                repeat: false
                onTriggered: {
                    root.screenState.dashboardTab = tab.TabBar.index;
                }
            }

            onContainsMouseChanged: {
                if (Config.dashboard.hoverSwitchTabs) {
                    if (containsMouse) {
                        const mappedX = tabMouse.mapToItem(bar, tabMouse.mouseX, 0).x;
                        root.updateVelocity(mappedX);
                        if (root.velocity > 0.8) {
                            hoverTimer.start();
                        } else {
                            root.screenState.dashboardTab = tab.TabBar.index;
                        }
                    } else {
                        hoverTimer.stop();
                    }
                }
            }

            onPositionChanged: {
                if (Config.dashboard.hoverSwitchTabs) {
                    const mappedX = tabMouse.mapToItem(bar, tabMouse.mouseX, 0).x;
                    root.updateVelocity(mappedX);
                    if (root.velocity > 0.8) {
                        if (hoverTimer.running) {
                            hoverTimer.restart();
                        }
                    } else {
                        if (hoverTimer.running) {
                            hoverTimer.stop();
                        }
                        if (root.screenState.dashboardTab !== tab.TabBar.index) {
                            root.screenState.dashboardTab = tab.TabBar.index;
                        }
                    }
                }
            }

            onPressed: root.screenState.dashboardTab = tab.TabBar.index

            StateLayer {
                id: stateLayer
                visible: !Config.dashboard.hoverSwitchTabs

                anchors.fill: undefined
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height + Tokens.sizes.dashboard.tabIndicatorSpacing * 2

                radius: Tokens.rounding.medium
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurface
                onClicked: root.screenState.dashboardTab = tab.TabBar.index
            }

            MaterialIcon {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: label.top

                text: tab.iconName
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fill: tab.current ? 1 : 0
                fontStyle: Tokens.font.icon.medium

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                id: label

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                text: tab.text
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}

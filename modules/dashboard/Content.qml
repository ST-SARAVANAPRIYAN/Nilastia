pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Nilastia
import Nilastia.Config
import qs.components
import qs.components.filedialog

Item {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    readonly property var dashboardTabs: {
        const allTabs = [
            {
                component: dashComponent,
                iconName: "dashboard",
                text: qsTr("Dashboard"),
                enabled: Config.dashboard.showDashboard
            },
            {
                component: mediaComponent,
                iconName: "queue_music",
                text: qsTr("Media"),
                enabled: Config.dashboard.showMedia
            },
            {
                component: performanceComponent,
                iconName: "speed",
                text: qsTr("Performance"),
                enabled: Config.dashboard.showPerformance
            },
            {
                component: weatherComponent,
                iconName: "cloud",
                text: qsTr("Weather"),
                enabled: Config.dashboard.showWeather
            }
        ];
        return allTabs.filter(tab => tab.enabled);
    }

    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly property real nonAnimHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: CUtils.clamp(anchors.margins - Config.border.thickness, 0, anchors.margins)
        anchors.margins: Tokens.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        screenState: root.screenState
        tabs: root.dashboardTabs
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        radius: Tokens.rounding.large
        color: "transparent"

        Item {
            id: view

            readonly property int currentIndex: Math.max(0, Math.min(root.screenState.dashboardTab, root.dashboardTabs.length - 1))
            readonly property Item currentItem: {
                repeater.count; // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            Repeater {
                id: repeater

                model: ScriptModel {
                    values: root.dashboardTabs
                }

                delegate: PaneLoader {}
            }
        }
    }

    component PaneLoader: Loader {
        id: pane

        required property int index
        required property var modelData

        readonly property bool shouldBeActive: pane.index === view.currentIndex

        active: false
        visible: opacity > 0

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width

        x: {
            if (shouldBeActive)
                return 0;
            return index < view.currentIndex ? -parent.width : parent.width;
        }

        opacity: shouldBeActive ? 1 : 0

        sourceComponent: modelData.component

        states: State {
            name: "active"
            when: pane.shouldBeActive

            PropertyChanges {
                pane.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                }
            }
        ]

        Behavior on x {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Component {
        id: dashComponent

        Dash {
            screenState: root.screenState
            facePicker: root.facePicker
        }
    }

    Component {
        id: mediaComponent

        Media {
            screenState: root.screenState
        }
    }

    Component {
        id: performanceComponent

        Performance {}
    }

    Component {
        id: weatherComponent

        WeatherTab {}
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}

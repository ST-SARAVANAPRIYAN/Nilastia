pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Nilastia
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: header.height + listWrapper.implicitHeight + search.height + padding * 3 + search.anchors.bottomMargin

    RowLayout {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: listWrapper.top
        anchors.bottomMargin: root.padding
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        height: 40

        StyledText {
            text: qsTr("Clipboard History")
            font: Tokens.font.title.medium
            color: Colours.palette.m3onSurface
            Layout.fillWidth: true
        }

        IconTextButton {
            text: qsTr("Clear All")
            icon: "delete_sweep"
            onClicked: {
                Quickshell.execDetached(["cliphist", "wipe"]);
                root.screenState.clipboard = false;
            }
        }
    }

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding
        height: implicitHeight

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ClipboardList {
            id: list

            screenState: root.screenState
            maxHeight: root.maxHeight - header.height - search.implicitHeight - root.padding * 4
            search: search
            width: Tokens.sizes.launcher.itemWidth
        }
    }

    SearchBar {
        id: search

        objectName: "clipboardSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: qsTr("Search Clipboard History...")

        onAccepted: {
            const currentItem = list.currentItem;
            if (currentItem) {
                currentItem.copyToClipboard();
            }
        }

        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onDownPressed: list.incrementCurrentIndex()

        Keys.onEscapePressed: root.screenState.clipboard = false

        Keys.onPressed: event => {
            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            forceActiveFocus();
        }

        Connections {
            target: root.screenState
            function onClipboardChanged(): void {
                if (root.screenState.clipboard) {
                    search.forceActiveFocus();
                } else {
                    search.text = "";
                }
            }
        }
    }
}

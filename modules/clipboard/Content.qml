pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
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
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: (staticHeader.visible ? staticHeader.height + 8 : 0) + list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        Item {
            id: staticHeader
            width: parent.width
            height: 52
            visible: list.allItems.length > 0

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.padding.medium
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Clipboard History")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
            }

            IconButton {
                id: deleteSweepBtn
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.medium
                anchors.verticalCenter: parent.verticalCenter
                icon: "delete_sweep"
                type: ButtonBase.Tonal
                inactiveOnColour: hovered ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                onClicked: {
                    Quickshell.execDetached(["cliphist", "wipe"]);
                    list.refreshList();
                }
            }
        }

        ClipboardList {
            id: list

            anchors.top: staticHeader.visible ? staticHeader.bottom : parent.top
            anchors.topMargin: staticHeader.visible ? 8 : 0

            screenState: root.screenState
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3 - (staticHeader.visible ? staticHeader.height + 8 : 0)
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

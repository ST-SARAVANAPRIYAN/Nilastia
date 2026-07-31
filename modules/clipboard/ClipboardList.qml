pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState
    required property real maxHeight

    readonly property string filterText: search.text.trim()

    property var allItems: []
    readonly property var filteredItems: {
        if (!filterText) return allItems;
        return allItems.filter(item => item.text.toLowerCase().includes(filterText.toLowerCase()));
    }

    model: filteredItems
    readonly property real maxListHeight: (Tokens.sizes.launcher.itemHeight + root.spacing) * Config.launcher.maxShown - root.spacing

    implicitHeight: Math.min(root.maxHeight, Math.min(maxListHeight, contentHeight > 0 ? contentHeight : empty.implicitHeight))

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: Tokens.spacing.extraSmall

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    function refreshList(): void {
        cliphistProc.running = false;
        cliphistProc.running = true;
    }

    Process {
        id: cliphistProc
        running: root.screenState.clipboard
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const items = [];
                for (const line of lines) {
                    if (!line) continue;
                    const tabIdx = line.indexOf("\t");
                    if (tabIdx !== -1) {
                        const id = line.slice(0, tabIdx).trim();
                        const val = line.slice(tabIdx + 1);
                        const isImg = val.startsWith("[[ binary data") && (val.includes("png") || val.includes("jpg") || val.includes("jpeg"));
                        items.push({ id: id, text: val, isImage: isImg });
                    }
                }
                root.allItems = items;
            }
        }
    }

    Connections {
        target: root.screenState
        function onClipboardChanged(): void {
            if (root.screenState.clipboard) {
                cliphistProc.running = false;
                cliphistProc.running = true;
            }
        }
    }

    delegate: Item {
        id: delegate
        width: root.width
        height: itemData.isImage ? 140 : Tokens.sizes.launcher.itemHeight

        required property var modelData
        readonly property var itemData: modelData

        function copyToClipboard() {
            Quickshell.execDetached(["sh", "-c", "cliphist decode " + itemData.id + " | wl-copy"]);
            root.screenState.clipboard = false;
        }

        StateLayer {
            radius: Tokens.rounding.large
            onClicked: delegate.copyToClipboard()
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            anchors.margins: Tokens.padding.small

            RowLayout {
                anchors.fill: parent
                spacing: Tokens.spacing.medium

                Item {
                    Layout.preferredWidth: itemData.isImage ? 120 : 36
                    Layout.fillHeight: true

                    Image {
                        id: imagePreview
                        visible: itemData.isImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        layer.enabled: true
                        layer.effect: QtObject {
                            property real radius: Tokens.rounding.medium
                        }
                    }

                    MaterialIcon {
                        visible: itemData.isImage && imagePreview.status !== Image.Ready
                        text: "image"
                        color: Colours.palette.m3outlineVariant
                        anchors.centerIn: parent
                        fontStyle: Tokens.font.icon.builders.large.scale(1.5).build()
                    }

                    MaterialIcon {
                        visible: !itemData.isImage
                        text: "content_copy"
                        color: Colours.palette.m3onSurfaceVariant
                        anchors.centerIn: parent
                        fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        text: itemData.isImage ? qsTr("Image Clip") : itemData.text
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: itemData.isImage ? 1 : 2
                    }

                    StyledText {
                        text: qsTr("Entry #%1").arg(itemData.id)
                        font: Tokens.font.body.small
                        color: Colours.palette.m3outline
                    }
                }

                IconButton {
                    id: deleteButton
                    icon: "delete"
                    type: ButtonBase.Text
                    Layout.alignment: Qt.AlignVCenter
                    
                    activeColour: "transparent"
                    inactiveColour: "transparent"
                    activeOnColour: Colours.palette.m3error
                    inactiveOnColour: hovered ? Colours.palette.m3error : Colours.palette.m3outlineVariant
                    
                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", "cliphist list | grep -E '^" + itemData.id + "[[:space:]]' | cliphist delete"]);
                        root.refreshList();
                    }
                }
            }
        }

        Process {
            id: previewProc
            running: false
            command: ["sh", "-c", "cliphist decode " + itemData.id + " > /tmp/cliphist-" + itemData.id + ".png"]
            onExited: {
                imagePreview.source = "file:///tmp/cliphist-" + itemData.id + ".png";
            }
        }

        Component.onCompleted: {
            if (itemData.isImage) {
                previewProc.running = true;
            }
        }
    }

    Row {
        id: empty

        opacity: root.filteredItems.length === 0 ? 1 : 0
        scale: root.filteredItems.length === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: "history"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.allItems.length > 0 ? qsTr("No results") : qsTr("No clipboard history")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: root.allItems.length > 0 ? qsTr("Try searching for something else") : qsTr("Copy something to populate the history")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }
}

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

    readonly property real allowedMaxHeight: Math.min(maxHeight, (Tokens.sizes.launcher.itemHeight + spacing) * Config.launcher.maxShown - spacing)

    implicitHeight: Math.min(allowedMaxHeight, contentHeight > 0 ? contentHeight : empty.implicitHeight)
    height: implicitHeight

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: Tokens.spacing.extraSmall

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
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

    function refresh(): void {
        cliphistProc.running = false;
        Qt.callLater(() => {
            cliphistProc.running = true;
        });
    }

    Connections {
        target: root.screenState
        function onClipboardChanged(): void {
            if (root.screenState.clipboard) {
                root.refresh();
            }
        }
    }

    delegate: Item {
        id: delegate
        width: root.width
        height: isImg ? 140 : Tokens.sizes.launcher.itemHeight

        required property var modelData
        readonly property var itemData: modelData
        readonly property bool isImg: itemData && itemData.isImage ? true : false
        readonly property string cText: itemData && itemData.text ? itemData.text : ""
        readonly property string cId: itemData && itemData.id ? itemData.id : ""

        function copyToClipboard() {
            Quickshell.execDetached(["sh", "-c", "cliphist decode " + cId + " | wl-copy"]);
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
                    Layout.preferredWidth: isImg ? 120 : 36
                    Layout.fillHeight: true

                    Image {
                        id: imagePreview
                        visible: isImg
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        layer.enabled: true
                        layer.effect: QtObject {
                            property real radius: Tokens.rounding.medium
                        }
                    }

                    MaterialIcon {
                        visible: isImg && imagePreview.status !== Image.Ready
                        text: "image"
                        color: Colours.palette.m3outlineVariant
                        anchors.centerIn: parent
                        fontStyle: Tokens.font.icon.builders.large.scale(1.5).build()
                    }

                    MaterialIcon {
                        visible: !isImg
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
                        text: isImg ? qsTr("Image Clip") : cText
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: isImg ? 1 : 2
                    }

                    StyledText {
                        text: qsTr("Entry #%1").arg(cId)
                        font: Tokens.font.body.small
                        color: Colours.palette.m3outline
                    }
                }

                IconButton {
                    icon: "delete"
                    type: IconButton.Text
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", "printf '%s\\t%s' '" + cId + "' '" + cText.replace(/'/g, "'\\''") + "' | cliphist delete"]);
                        root.refresh();
                    }
                }
            }
        }

        Process {
            id: previewProc
            running: false
            command: ["sh", "-c", "cliphist decode " + cId + " > /tmp/cliphist-" + cId + ".png"]
            onExited: {
                imagePreview.source = "file:///tmp/cliphist-" + cId + ".png";
            }
        }

        Component.onCompleted: {
            if (isImg) {
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
                text: qsTr("No clipboard history")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: qsTr("Copy something to populate the history")
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

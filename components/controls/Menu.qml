pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Nilastia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.drawers

MouseArea {
    id: root

    z: 99

    enum Side {
        Top,
        Bottom,
        Left,
        Right
    }

    required property Item attachTo
    property int attachSideX: Menu.Right
    property int attachSideY: Menu.Bottom
    property int thisSideX: Menu.Right
    property int thisSideY: Menu.Top
    property real marginX
    property real marginY

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded

    onExpandedChanged: {
        console.log("[Nilastia Menu] expanded:", expanded, "items count:", items.length);
        if (expanded) {
            console.log("[Nilastia Menu] root parent:", root.parent, "win:", QsWindow.window);
            console.log("[Nilastia Menu] attachTo:", root.attachTo, "root parent size:", root.parent ? root.parent.width + "x" + root.parent.height : "null");
            console.log("[Nilastia Menu] menu coords x:", menu.x, "y:", menu.y, "w:", menu.width, "h:", menu.height);
        }
    }

    signal itemSelected(item: MenuItem)

    parent: {
        let p = root.attachTo;
        let top = null;
        let target = null;
        while (p) {
            if (p.objectName === "interactionWrapper" || p.interactionWrapper) {
                target = p.interactionWrapper ?? p;
            }
            if (p.parent) {
                p = p.parent;
                top = p;
            } else {
                break;
            }
        }
        return target ?? top;
    }
    anchors.fill: parent

    visible: expanded || opacity > 0
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    layer.enabled: opacity < 1

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    TransformWatcher {
        id: watcher

        a: root.parent
        b: root.attachTo
    }

    Elevation {
        id: menu

        x: {
            watcher.transform; // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            if (!item || !root.parent) return 0;
            let off = root.attachSideX === Menu.Left ? 0 : item.width;
            if (root.thisSideX === Menu.Right)
                off -= width;
            return item.mapToItem(root.parent, off, 0).x + root.marginX;
        }
        y: {
            watcher.transform; // mapToItem is not reactive so this forces updates
            const item = root.attachTo;
            if (!item || !root.parent) return 0;
            let off = root.attachSideY === Menu.Top ? 0 : item.height;
            if (root.thisSideY === Menu.Bottom)
                off -= height;
            return item.mapToItem(root.parent, 0, off).y + root.marginY;
        }

        radius: Tokens.rounding.large
        level: 2

        width: implicitWidth
        height: Math.min(root.parent ? root.parent.height * 0.6 : 400, implicitHeight)
        implicitWidth: Math.max(200, column.implicitWidth + Tokens.padding.extraSmall * 2)
        implicitHeight: column.implicitHeight + Tokens.padding.extraSmall * 2

        transform: Scale {
            yScale: root.expanded ? 1 : 0.1
            origin.y: root.thisSideY === Menu.Bottom ? menu.height : 0

            Behavior on yScale {
                Anim {}
            }
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerLow

            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true
                interactive: contentHeight > height

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: e => {
                        e.accepted = true;
                        if (flickable.interactive) {
                            flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, flickable.contentY - e.angleDelta.y));
                        }
                    }
                }

                ColumnLayout {
                    id: column

                    width: parent.width
                    spacing: 0

                    Repeater {
                        id: repeater

                    model: root.items

                    StyledRect {
                        id: item

                        required property int index
                        required property MenuItem modelData
                        readonly property bool active: modelData === root?.active

                        Layout.fillWidth: true
                        implicitWidth: menuOptionRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: menuOptionRow.implicitHeight + Tokens.padding.medium * 2

                        radius: active ? Tokens.rounding.medium : Tokens.rounding.extraSmall
                        topLeftRadius: index === 0 ? Tokens.rounding.medium : radius
                        topRightRadius: index === 0 ? Tokens.rounding.medium : radius
                        bottomLeftRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius
                        bottomRightRadius: index === repeater?.count - 1 ? Tokens.rounding.medium : radius

                        color: Qt.alpha(Colours.palette.m3tertiaryContainer, active ? 1 : 0)

                        Behavior on radius {
                            Anim {}
                        }

                        RowLayout {
                            id: menuOptionRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: item.modelData?.icon ?? ""
                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: item.modelData?.text ?? ""
                                color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            }

                            Loader {
                                asynchronous: true
                                Layout.alignment: Qt.AlignVCenter
                                active: item.modelData?.trailingIcon.length > 0
                                visible: active

                                sourceComponent: MaterialIcon {
                                    text: item.modelData.trailingIcon
                                    color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }

                        StateLayer {
                            topLeftRadius: parent.topLeftRadius
                            topRightRadius: parent.topRightRadius
                            bottomLeftRadius: parent.bottomLeftRadius
                            bottomRightRadius: parent.bottomRightRadius

                            color: item.active ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                            disabled: !root.expanded
                            onClicked: {
                                console.log("[Nilastia Menu] Item clicked:", item.modelData.text, "value:", item.modelData.value);
                                root.itemSelected(item.modelData);
                                item.modelData.clicked();
                                root.expanded = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
}

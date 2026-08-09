pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var lock
    readonly property int lockNotifCount: Notifs.notClosed.filter(n => !Notifs.lockTime || n.time >= Notifs.lockTime).length

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    spacing: Tokens.spacing.medium

    StyledText {
        Layout.fillWidth: true
        text: root.lockNotifCount > 0 ? qsTr("%1 notification%2").arg(root.lockNotifCount).arg(root.lockNotifCount === 1 ? "" : "s") : qsTr("Notifications")
        color: Colours.palette.m3outline
        font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
        elide: Text.ElideRight
    }

    ClippingRectangle {
        id: clipRect

        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Tokens.rounding.medium
        color: "transparent"

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: opacity > 0
            opacity: root.lockNotifCount > 0 && !Config.lock.hideNotifs ? 0 : 1

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.largeIncreased

                Image {
                    asynchronous: true
                    source: Paths.absolutePath(Config.paths.lockNoNotifsPic)
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: clipRect.width * 0.8 * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

                    layer.enabled: true
                    layer.effect: Colouriser {
                        colorizationColor: Colours.palette.m3outlineVariant
                        brightness: 1
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Config.lock.hideNotifs ? qsTr("Unlock for Notifications") : qsTr("No Notifications")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.mono.builders.large.weight(Font.Medium).build()
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardExtraLarge
                }
            }
        }

        StyledListView {
            anchors.fill: parent
            visible: !Config.lock.hideNotifs
            spacing: Tokens.spacing.small
            clip: true

            model: ScriptModel {
                values: {
                    const list = Notifs.notClosed
                        .filter(n => !Notifs.lockTime || n.time >= Notifs.lockTime)
                        .map(n => [n.appName, null]);
                    return [...new Map(list).keys()];
                }
            }

            delegate: NotifGroup {}

            add: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    property: "scale"
                    from: 0
                    to: 1
                }
            }

            remove: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    property: "opacity"
                    to: 0
                }
                Anim {
                    property: "scale"
                    to: 0.6
                }
            }

            move: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    type: Anim.DefaultEffects
                    properties: "opacity,scale"
                    to: 1
                }
                Anim {
                    property: "y"
                }
            }
        }
    }
}

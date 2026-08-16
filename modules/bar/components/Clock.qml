pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Loader {
        id: styleLoader
        anchors.centerIn: parent
        asynchronous: true

        source: {
            let s = Config.bar.clock.style.toLowerCase();
            if (s === "pill") return "clocks/Pill.qml";
            if (s === "analog") return "clocks/Analog.qml";
            if (s === "cyber") return "clocks/Cyber.qml";
            return "clocks/Default.qml";
        }
    }
}

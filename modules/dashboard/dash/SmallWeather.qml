import QtQuick
import Nilastia.Config
import qs.components
import qs.services

Item {
    id: root

    anchors.centerIn: parent

    readonly property real maxAvailableTextWidth: Math.max(80, (parent ? parent.width : Tokens.sizes.dashboard.weatherWidth) - icon.implicitWidth - Tokens.spacing.largeIncreased - Tokens.padding.extraLarge * 2)

    implicitWidth: icon.implicitWidth + info.implicitWidth + info.anchors.leftMargin
    implicitHeight: Math.max(icon.implicitHeight, info.implicitHeight) + Tokens.padding.largeIncreased * 2

    Component.onCompleted: Weather.reload()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Weather.nextLocation()
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
                Weather.nextLocation();
            } else if (event.angleDelta.y > 0 || event.angleDelta.x > 0) {
                Weather.prevLocation();
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        animate: true
        text: Weather.icon
        color: Colours.palette.m3secondary
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.6).build()
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Tokens.spacing.largeIncreased

        spacing: Tokens.spacing.extraSmall

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.temp
            color: Colours.palette.m3primary
            font: Tokens.font.headline.builders.medium.weight(Font.DemiBold).build()
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.city ? (Weather.city + " • " + Weather.description) : Weather.description
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant

            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.maxAvailableTextWidth)
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property string title
    required property NexusState nState
    property bool isSubPage
    property int maxWidth: Tokens.sizes.nexus.maxContentWidth
    property int horizontalPadding: 0
    readonly property int cappedWidth: Math.min(maxWidth, width - horizontalPadding * 2)
    readonly property alias flickable: flickable

    default property Item contentChild

    MouseArea { // Prevent clicks from reaching flickable
        id: headerMouseArea
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: header.implicitHeight
        onClicked: focus = true

        RowLayout {
            id: header
            anchors.fill: parent
            spacing: Tokens.spacing.largeIncreased

            Loader {
                visible: active
                active: root.isSubPage
                asynchronous: true
                sourceComponent: IconButton {
                    icon: "arrow_back"
                    font: Tokens.font.icon.medium
                    type: IconButton.Tonal
                    isRound: true
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    onClicked: root.nState.closeSubPage()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font: Tokens.font.title.large
                elide: Text.ElideRight
            }
        }
    }

    VerticalFadeFlickable {
        id: flickable

        anchors.top: headerMouseArea.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        
        anchors.topMargin: Tokens.spacing.extraLargeIncreased
        contentWidth: width

        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]

        TapHandler {
            onTapped: flickable.focus = true
        }
    }
}

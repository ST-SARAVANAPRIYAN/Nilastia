import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property alias menuItems: splitButton.menuItems
    property alias active: splitButton.active
    property alias fallbackText: splitButton.fallbackText
    property alias fallbackIcon: splitButton.fallbackIcon
    property alias menuOnTop: splitButton.menuOnTop
    property bool disabled: false

    signal selected(item: MenuItem)

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2
    clip: false
    z: splitButton.expanded ? 1 : 0

    RowLayout {
        id: rowLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
                color: root.disabled ? Colours.palette.m3outline : Colours.palette.m3onSurface
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        SplitButton {
            id: splitButton

            type: SplitButton.Filled
            disabled: root.disabled
            stateLayer.onClicked: splitButton.expanded = !splitButton.expanded
            menu.onItemSelected: (item) => {
                console.log("[Nilastia SelectRow] itemSelected triggered for:", item.text, "value:", item.value);
                root.selected(item);
            }
        }
    }
}

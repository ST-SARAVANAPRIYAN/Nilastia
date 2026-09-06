import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property bool expanded: false

    readonly property real nonAnimHeight: layout.implicitHeight + (Hotspot.enabled ? detailsLayout.implicitHeight + Tokens.padding.medium : 0) + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            id: layout
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.large

                radius: Tokens.rounding.full
                color: Hotspot.enabled ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "wifi_tethering"
                    color: Hotspot.enabled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Wi-Fi Hotspot")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (!Hotspot.enabled)
                            return qsTr("Share network via Wi-Fi");
                        if (Hotspot.clientsCount === 0)
                            return qsTr("%1 (No devices connected)").arg(Hotspot.ssid);
                        if (Hotspot.clientsCount === 1)
                            return qsTr("%1 (1 device connected)").arg(Hotspot.ssid);
                        return qsTr("%1 (%2 devices connected)").arg(Hotspot.ssid).arg(Hotspot.clientsCount);
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            StyledSwitch {
                checked: Hotspot.enabled
                disabled: Hotspot.busy
                onToggled: Hotspot.toggle()
            }
        }

        // Expanded Details Section
        ColumnLayout {
            id: detailsLayout
            Layout.fillWidth: true
            visible: Hotspot.enabled
            opacity: Hotspot.enabled ? 1 : 0
            spacing: Tokens.spacing.small

            Behavior on opacity {
                Anim { type: Anim.StandardSmall }
            }

            // Info row (SSID & Password)
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: ssidCol.implicitHeight + Tokens.padding.medium
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerHigh

                    ColumnLayout {
                        id: ssidCol
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        anchors.leftMargin: Tokens.padding.medium
                        spacing: 0

                        StyledText {
                            text: qsTr("Network Name")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.85)).build()
                        }
                        StyledText {
                            text: Hotspot.ssid
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: passCol.implicitHeight + Tokens.padding.medium
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerHigh

                    ColumnLayout {
                        id: passCol
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        anchors.leftMargin: Tokens.padding.medium
                        spacing: 0

                        StyledText {
                            text: qsTr("Password")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.85)).build()
                        }
                        StyledText {
                            text: Hotspot.password
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // QR Code Scan Button & Band Chip
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRect {
                    implicitWidth: bandText.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: bandText.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        id: bandText
                        anchors.centerIn: parent
                        text: Hotspot.band === "a" ? "5 GHz Band" : "2.4 GHz Band"
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.85)).build()
                    }
                }

                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: qrBtnLayout.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: qrBtnLayout.implicitHeight + Tokens.padding.small
                    radius: Tokens.rounding.full
                    color: root.expanded ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = !root.expanded
                    }

                    RowLayout {
                        id: qrBtnLayout
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            text: "qr_code_2"
                            fontStyle: Tokens.font.icon.small
                            color: root.expanded ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: root.expanded ? qsTr("Hide QR") : qsTr("Scan QR")
                            color: root.expanded ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.85)).build()
                        }
                    }
                }
            }

            // QR Code Container
            StyledRect {
                id: qrContainer
                visible: root.expanded
                Layout.fillWidth: true
                implicitHeight: visible ? qrImgCol.implicitHeight + Tokens.padding.large * 2 : 0
                radius: Tokens.rounding.medium
                color: Colours.palette.m3surfaceContainerHigh

                ColumnLayout {
                    id: qrImgCol
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 140
                        implicitHeight: 140
                        radius: Tokens.rounding.small
                        color: "white"

                        Image {
                            anchors.fill: parent
                            anchors.margins: 6
                            source: "https://api.qrserver.com/v1/create-qr-code/?size=128x128&margin=0&data=" + encodeURIComponent(Hotspot.qrCodeData)
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Scan with phone camera to connect")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.small.size(Math.round(Tokens.font.body.small.pointSize * 0.85)).build()
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}

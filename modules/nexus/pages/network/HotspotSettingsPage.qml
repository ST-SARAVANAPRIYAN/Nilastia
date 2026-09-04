pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wi-Fi Hotspot")
    isSubPage: true

    property string tempSsid: Hotspot.ssid
    property string tempPassword: Hotspot.password
    property bool showPassword: false
    property bool tempPasswordEnabled: Hotspot.passwordEnabled
    property string tempBand: Hotspot.band

    function saveChanges(): void {
        const ssid = ssidField.text.trim();
        if (ssid.length === 0) {
            ssidField.isError = true;
            return;
        }

        if (root.tempPasswordEnabled && passwordField.text.length < 8) {
            passwordField.isError = true;
            return;
        }

        Hotspot.setSsid(ssid);
        Hotspot.setPasswordEnabled(root.tempPasswordEnabled);
        if (root.tempPasswordEnabled) {
            Hotspot.setPassword(passwordField.text);
        }
        Hotspot.setBand(root.tempBand);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Master Switch
        ToggleRow {
            first: true
            last: true
            text: qsTr("Hotspot")
            subtext: Hotspot.enabled ? (Hotspot.clientsCount === 1 ? qsTr("Broadcasting %1 (1 device connected)").arg(Hotspot.ssid) : qsTr("Broadcasting %1 (%2 devices connected)").arg(Hotspot.ssid).arg(Hotspot.clientsCount)) : qsTr("Share network connection with other devices")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: Hotspot.enabled
            disabled: Hotspot.busy
            onToggled: Hotspot.toggle()
        }

        // Configuration Header
        SectionHeader {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Hotspot Settings")
        }

        StyledTextField {
            id: ssidField

            Layout.fillWidth: true
            text: root.tempSsid
            placeholderText: qsTr("Hotspot name (SSID)")
            leadingIcon: "wifi_tethering"
            errorText: qsTr("Network name cannot be empty")
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            onTextChanged: root.tempSsid = text
        }

        ToggleRow {
            first: true
            last: !root.tempPasswordEnabled
            text: qsTr("Require password")
            subtext: qsTr("Protect the hotspot with WPA2-PSK security")
            checked: root.tempPasswordEnabled
            onToggled: root.tempPasswordEnabled = checked
        }

        RowLayout {
            visible: root.tempPasswordEnabled
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            StyledTextField {
                id: passwordField

                Layout.fillWidth: true
                text: root.tempPassword
                placeholderText: qsTr("Password (minimum 8 characters)")
                leadingIcon: "lock"
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                errorText: qsTr("Password must be at least 8 characters")
                onTextChanged: root.tempPassword = text
            }

            IconButton {
                type: IconButton.Tonal
                isRound: true
                icon: root.showPassword ? "visibility_off" : "visibility"
                onClicked: root.showPassword = !root.showPassword
            }
        }

        SelectRow {
            id: bandSelect

            Layout.topMargin: Tokens.spacing.extraSmall / 2
            first: true
            last: true
            label: qsTr("Frequency Band")
            fallbackText: root.tempBand === "a" ? qsTr("5 GHz Band") : qsTr("2.4 GHz Band")
            fallbackIcon: "sensors"

            menuItems: [
                MenuItem {
                    icon: "sensors"
                    text: qsTr("2.4 GHz Band")
                    onClicked: root.tempBand = "bg"
                },
                MenuItem {
                    icon: "sensors"
                    text: qsTr("5 GHz Band")
                    onClicked: root.tempBand = "a"
                }
            ]
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.medium

            Item { Layout.fillWidth: true }

            TextButton {
                text: qsTr("Apply Settings")
                type: ButtonBase.Filled
                onClicked: root.saveChanges()
            }
        }

        // Share & Scan QR Code Card
        SectionHeader {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Scan to Connect")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: qrCardLayout.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: qrCardLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Scan this QR code with any phone or tablet camera to instantly join the hotspot without entering a password.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.large

                    StyledRect {
                        implicitWidth: 150
                        implicitHeight: 150
                        radius: Tokens.rounding.small
                        color: "white"

                        Image {
                            anchors.fill: parent
                            anchors.margins: 8
                            source: "https://api.qrserver.com/v1/create-qr-code/?size=134x134&margin=0&data=" + encodeURIComponent(Hotspot.qrCodeData)
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                    }

                    ColumnLayout {
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Network: %1").arg(Hotspot.ssid)
                            font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                        }
                        StyledText {
                            text: Hotspot.passwordEnabled ? qsTr("Password: %1").arg(Hotspot.password) : qsTr("Security: Open Network")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.medium
                        }
                        StyledText {
                            text: Hotspot.band === "a" ? qsTr("Band: 5 GHz") : qsTr("Band: 2.4 GHz")
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.small
                        }
                    }
                }
            }
        }

        // Connected Devices Section
        SectionHeader {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Connected Devices (%1)").arg(Hotspot.clientsCount)
        }

        ItemList {
            id: clientList

            showList: true
            first: true
            last: true
            placeholderIcon: "devices"
            placeholderText: qsTr("No devices connected to hotspot")

            model: ScriptModel {
                values: [...Hotspot.clients]
            }

            delegate: Item {
                id: clientItem

                required property var modelData
                required property int index

                anchors.left: clientList.list.contentItem.left
                anchors.right: clientList.list.contentItem.right
                implicitHeight: clientLayout.implicitHeight + clientLayout.anchors.margins * 2

                RowLayout {
                    id: clientLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: clientIcon.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primaryContainer

                        MaterialIcon {
                            id: clientIcon
                            anchors.centerIn: parent
                            text: "smartphone"
                            color: Colours.palette.m3onPrimaryContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: clientItem.modelData?.ip ?? "10.42.0.x"
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("MAC: %1  •  Signal: %2").arg(clientItem.modelData?.mac ?? "").arg(clientItem.modelData?.signal ?? "")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }

                    IconButton {
                        type: IconButton.Tonal
                        isRound: true
                        icon: "block"
                        onClicked: Hotspot.blockDevice(clientItem.modelData?.mac ?? "")
                    }
                }
            }
        }

        // Blocked Devices Section (visible only when there are blocked devices)
        SectionHeader {
            visible: Hotspot.blockedDevices.length > 0
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Blocked Devices (%1)").arg(Hotspot.blockedDevices.length)
        }

        ItemList {
            id: blockedList

            visible: Hotspot.blockedDevices.length > 0
            showList: true
            first: true
            last: true
            placeholderIcon: "block"
            placeholderText: qsTr("No blocked devices")

            model: ScriptModel {
                values: [...Hotspot.blockedDevices]
            }

            delegate: Item {
                id: blockedItem

                required property string modelData
                required property int index

                anchors.left: blockedList.list.contentItem.left
                anchors.right: blockedList.list.contentItem.right
                implicitHeight: blockedLayout.implicitHeight + blockedLayout.anchors.margins * 2

                RowLayout {
                    id: blockedLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: blockIcon.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3errorContainer

                        MaterialIcon {
                            id: blockIcon
                            anchors.centerIn: parent
                            text: "block"
                            color: Colours.palette.m3onErrorContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("MAC: %1").arg(blockedItem.modelData)
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Blocked from connecting to this hotspot")
                            color: Colours.palette.m3error
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }

                    IconButton {
                        type: IconButton.Tonal
                        isRound: true
                        icon: "check"
                        onClicked: Hotspot.unblockDevice(blockedItem.modelData)
                    }
                }
            }
        }
    }
}

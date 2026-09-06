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

    readonly property bool isModified: (tempSsid.trim() !== Hotspot.ssid) ||
                                       (tempPasswordEnabled !== Hotspot.passwordEnabled) ||
                                       (tempPasswordEnabled && tempPassword !== Hotspot.password) ||
                                       (tempBand !== Hotspot.band)

    resources: [
        Connections {
            target: Hotspot
            function onSsidChanged(): void {
                if (!root.isModified)
                    root.tempSsid = Hotspot.ssid;
            }
            function onPasswordChanged(): void {
                if (!root.isModified)
                    root.tempPassword = Hotspot.password;
            }
            function onPasswordEnabledChanged(): void {
                if (!root.isModified)
                    root.tempPasswordEnabled = Hotspot.passwordEnabled;
            }
            function onBandChanged(): void {
                if (!root.isModified)
                    root.tempBand = Hotspot.band;
            }
        }
    ]

    function saveChanges(): void {
        const ssid = ssidField.text.trim();
        if (ssid.length === 0) {
            ssidField.isError = true;
            ssidField.forceActiveFocus();
            return;
        }

        if (root.tempPasswordEnabled && passwordField.text.length < 8) {
            passwordField.isError = true;
            passwordField.forceActiveFocus();
            return;
        }

        Hotspot.setSsid(ssid);
        Hotspot.setPasswordEnabled(root.tempPasswordEnabled);
        if (root.tempPasswordEnabled) {
            Hotspot.setPassword(passwordField.text);
        }
        Hotspot.setBand(root.tempBand);

        if (typeof Toaster !== "undefined" && Toaster) {
            Toaster.toast(qsTr("Hotspot Updated"), qsTr("Hotspot configuration applied"), "wifi_tethering");
        }
    }

    function resetChanges(): void {
        root.tempSsid = Hotspot.ssid;
        root.tempPassword = Hotspot.password;
        root.tempPasswordEnabled = Hotspot.passwordEnabled;
        root.tempBand = Hotspot.band;
        ssidField.isError = false;
        if (passwordField)
            passwordField.isError = false;
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
            text: qsTr("Wi-Fi Hotspot")
            subtext: {
                if (Hotspot.busy)
                    return Hotspot.enabled ? qsTr("Starting hotspot...") : qsTr("Stopping hotspot...");
                if (!Hotspot.enabled)
                    return qsTr("Share network connection with other devices");
                const count = Hotspot.clientsCount;
                if (count === 0)
                    return qsTr("Broadcasting \"%1\" (No devices connected)").arg(Hotspot.ssid);
                return count === 1 ? qsTr("Broadcasting \"%1\" (1 device connected)").arg(Hotspot.ssid)
                                   : qsTr("Broadcasting \"%1\" (%2 devices connected)").arg(Hotspot.ssid).arg(count);
            }
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
            supportingText: qsTr("Network name broadcast to nearby devices")
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
                supportingText: qsTr("WPA2-PSK security passphrase")
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
            first: !root.tempPasswordEnabled
            last: true
            label: qsTr("Frequency Band")
            subtext: root.tempBand === "a" ? qsTr("5 GHz (High speed, shorter range)") : qsTr("2.4 GHz (Standard speed, wider coverage)")
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
                visible: root.isModified
                text: qsTr("Reset")
                type: ButtonBase.Tonal
                onClicked: root.resetChanges()
            }

            TextButton {
                text: qsTr("Apply Settings")
                type: root.isModified ? ButtonBase.Filled : ButtonBase.Tonal
                disabled: !root.isModified
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
                        implicitWidth: 140
                        implicitHeight: 140
                        radius: Tokens.rounding.medium
                        color: "white"

                        Image {
                            anchors.fill: parent
                            anchors.margins: 10
                            source: "https://api.qrserver.com/v1/create-qr-code/?size=120x120&margin=0&data=" + encodeURIComponent(Hotspot.qrCodeData)
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                    }

                    ColumnLayout {
                        spacing: Tokens.spacing.small

                        RowLayout {
                            spacing: Tokens.spacing.small
                            MaterialIcon {
                                text: "wifi_tethering"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3primary
                            }
                            StyledText {
                                text: qsTr("Network: %1").arg(Hotspot.ssid)
                                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                            }
                        }

                        RowLayout {
                            spacing: Tokens.spacing.small
                            MaterialIcon {
                                text: Hotspot.passwordEnabled ? "lock" : "lock_open"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                            StyledText {
                                text: Hotspot.passwordEnabled ? qsTr("Password: %1").arg(Hotspot.password) : qsTr("Security: Open Network")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.medium
                            }
                            IconButton {
                                visible: Hotspot.passwordEnabled
                                implicitWidth: 26
                                implicitHeight: 26
                                isRound: true
                                type: IconButton.Standard
                                icon: "content_copy"
                                font: Tokens.font.icon.small
                                onClicked: {
                                    Quickshell.clipboardText = Hotspot.password;
                                    if (typeof Toaster !== "undefined" && Toaster) {
                                        Toaster.toast(qsTr("Copied"), qsTr("Hotspot password copied to clipboard"), "content_copy");
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: Tokens.spacing.small
                            MaterialIcon {
                                text: "sensors"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3outline
                            }
                            StyledText {
                                text: Hotspot.band === "a" ? qsTr("Frequency: 5 GHz") : qsTr("Frequency: 2.4 GHz")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
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
            placeholderText: Hotspot.enabled ? qsTr("No devices connected to hotspot") : qsTr("Hotspot is currently turned off")

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
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: clientItem.modelData?.icon ?? "smartphone"
                            color: Colours.palette.m3onPrimaryContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: clientItem.modelData?.name || clientItem.modelData?.hostname || clientItem.modelData?.ip || qsTr("Connected Device")
                            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("IP: %1  •  MAC: %2").arg(clientItem.modelData?.ip ?? "—").arg(clientItem.modelData?.mac ?? "—")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    // Signal Badge Pill
                    StyledRect {
                        visible: !!(clientItem.modelData?.signal)
                        implicitHeight: 26
                        implicitWidth: sigRow.implicitWidth + Tokens.padding.medium * 2
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3surfaceContainerHigh

                        RowLayout {
                            id: sigRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialIcon {
                                text: "signal_wifi_4_bar"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                text: clientItem.modelData?.signal ?? ""
                                font: Tokens.font.label.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
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
                        implicitWidth: 42
                        implicitHeight: 42
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
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("MAC: %1").arg(blockedItem.modelData)
                            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Blocked from connecting to this hotspot")
                            color: Colours.palette.m3error
                            font: Tokens.font.label.small
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

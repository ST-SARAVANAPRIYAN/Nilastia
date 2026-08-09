import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Updates")

    // State from dots-state.json
    property string appliedRev: ""
    property var enabledComponents: []
    property int deployedCount: 0
    property string statusText: qsTr("Checking for updates...")
    property bool updateAvailable: false
    property bool checking: false

    function checkForUpdates(): void {
        root.checking = true;
        root.statusText = qsTr("Checking for updates...")
        gitCheckProc.running = true
    }

    Component.onCompleted: {
        dotsStateFile.reload();
        checkForUpdates();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        FileView {
            id: dotsStateFile

            path: `${Paths.state}/dots-state.json`
            onLoaded: {
                try {
                    const data = JSON.parse(text());
                    root.appliedRev = data.applied_rev || "None";
                    root.enabledComponents = data.enabled_components || [];
                    root.deployedCount = Object.keys(data.deployed_files || {}).length;
                } catch (e) {
                    console.warn("Failed to parse dots state:", e);
                }
            }
            onLoadFailed: {
                root.appliedRev = qsTr("Not installed");
            }
        }

        Process {
            id: checkUpdateProc

            command: ["git", "-C", `${Paths.state}/dots`, "fetch", "origin"]
            onExited: code => {
                if (code !== 0) {
                    root.statusText = qsTr("Failed to check for updates");
                    root.checking = false;
                    return;
                }
                compareProc.running = true;
            }
        }

        Process {
            id: compareProc

            command: ["git", "-C", `${Paths.state}/dots`, "rev-list", "--count", "HEAD..origin/main"]
            onExited: code => {
                root.checking = false;
                if (code === 0) {
                    const count = parseInt(readAll().trim());
                    if (count > 0) {
                        root.updateAvailable = true;
                        root.statusText = qsTr("%1 update(s) available").arg(count);
                    } else {
                        root.updateAvailable = false;
                        root.statusText = qsTr("System is up to date");
                    }
                } else {
                    root.statusText = qsTr("Unable to check updates");
                }
            }
        }

        Process {
            id: runUpdateProc

            command: ["caelestia", "update", "--noconfirm"]
            onExited: code => {
                root.checking = false;
                if (code === 0) {
                    root.statusText = qsTr("Update complete! Restarting shell...");
                    dotsStateFile.reload();
                    // Restart shell service
                    Quickshell.execDetached(["systemctl", "--user", "restart", "niri-nilastia-shell.service"]);
                } else {
                    root.statusText = qsTr("Update failed! Check systemctl --user status niri-nilastia-shell");
                }
            }
        }

        Process {
            id: gitCheckProc

            command: ["git", "-C", `${Paths.state}/dots`, "status"]
            onExited: code => {
                if (code === 0) {
                    checkUpdateProc.running = true;
                } else {
                    root.statusText = qsTr("Initializing dots repository...");
                    initProc.running = true;
                }
            }
        }

        Process {
            id: initProc

            command: ["caelestia", "update", "--noconfirm"]
            onExited: code => {
                root.checking = false;
                dotsStateFile.reload();
                if (code === 0) {
                    root.statusText = qsTr("Dots repository initialized successfully!");
                    checkForUpdates();
                } else {
                    root.statusText = qsTr("Failed to initialize dots repository");
                }
            }
        }

        SectionHeader {
            first: true
            text: qsTr("Status")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: statusLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: statusLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.statusText
                        font: Tokens.font.body.small
                        color: root.updateAvailable ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Current revision: %1").arg(root.appliedRev.slice(0, 8))
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }

                TextButton {
                    text: root.updateAvailable ? qsTr("Update Now") : qsTr("Check Again")
                    disabled: root.checking
                    onClicked: {
                        if (root.updateAvailable) {
                            root.checking = true;
                            root.statusText = qsTr("Installing updates...");
                            runUpdateProc.running = true;
                        } else {
                            root.checkForUpdates();
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Configuration Info")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            implicitHeight: componentsLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: componentsLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased

                ColumnLayout {
                    spacing: 0
                    StyledText {
                        text: qsTr("Enabled Components")
                        font: Tokens.font.body.small
                    }
                    StyledText {
                        text: root.enabledComponents.join(", ") || qsTr("None")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            last: true
            implicitHeight: filesLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: filesLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased

                ColumnLayout {
                    spacing: 0
                    StyledText {
                        text: qsTr("Deployed Files")
                        font: Tokens.font.body.small
                    }
                    StyledText {
                        text: qsTr("%1 files managed by Caelestia").arg(root.deployedCount)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }
}

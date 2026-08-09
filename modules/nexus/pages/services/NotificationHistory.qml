import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import Caelestia.Services
import qs.components
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root
    isSubPage: true

    title: qsTr("Notification History")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Actions")
        }

        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: qsTr("Clear All History")
                        font: Tokens.font.body.medium
                    }
                    StyledText {
                        text: qsTr("Permanently delete all notifications in history")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                IconButton {
                    icon: "delete_sweep"
                    onClicked: {
                        for (const notif of Notifs.list.slice()) {
                            notif.close();
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Past Notifications")
        }

        // Notification List
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            // Placeholder when no notifications exist
            StyledText {
                visible: Notifs.list.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.padding.large
                text: qsTr("No notification history")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.large
            }

            Repeater {
                model: Notifs.list

                delegate: ConnectedRect {
                    // Check if it is the first or last item in the list
                    first: index === 0
                    last: index === Notifs.list.length - 1
                    Layout.fillWidth: true
                    implicitHeight: delegateRow.implicitHeight + Tokens.padding.medium * 2

                    RowLayout {
                        id: delegateRow
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        // App Icon or Placeholder
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            width: 36
                            height: 36
                            radius: Tokens.rounding.small
                            color: modelData.urgency === 2 ? Colours.palette.m3error : Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: modelData.urgency === 2 ? "error" : "notifications"
                                color: modelData.urgency === 2 ? Colours.palette.m3onError : Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.medium
                            }
                        }

                        // Notification Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: Tokens.spacing.small
                                StyledText {
                                    text: modelData.appName || qsTr("System")
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                }
                                StyledText {
                                    text: "•"
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                }
                                StyledText {
                                    text: modelData.timeStr || qsTr("now")
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                }
                            }

                            StyledText {
                                text: modelData.summary || ""
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3onSurface
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: modelData.body || ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                visible: modelData.body !== ""
                            }
                        }

                        // Dismiss button
                        IconButton {
                            Layout.alignment: Qt.AlignTop
                            icon: "close"
                            onClicked: modelData.close()
                        }
                    }
                }
            }
        }
    }
}

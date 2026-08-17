pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Nilastia.Components
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Parallax Wallpaper")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        SectionHeader {
            text: qsTr("Choose Parallax Flow")
        }

        RowButton {
            text: qsTr("Create New Parallax")
            subtext: qsTr("Build a brand new parallax preset from local image layers")
            icon: "add_photo_alternate"
            onClicked: {
                root.nState.editActiveWallpaperOnly = false;
                root.nState.openSubPage(4); // Open WallpaperBuilder
            }
        }

        RowButton {
            text: qsTr("Edit Active Parallax")
            subtext: qsTr("Directly tune the stiffness, depth, and layers of the current wallpaper")
            icon: "edit"
            onClicked: {
                root.nState.editActiveWallpaperOnly = true;
                root.nState.openSubPage(4); // Open WallpaperBuilder
            }
        }

        RowButton {
            text: qsTr("Import Portable Wallpaper")
            subtext: qsTr("Apply a pre-built .nilawall file from your local files")
            icon: "file_upload"
            onClicked: zenityImportPicker.running = true
        }
    }

    resources: [
        Process {
            id: zenityImportPicker
            command: ["zenity", "--file-selection", "--title=Import Portable Wallpaper", "--file-filter=Portable Wallpaper (*.nilawall) | *.nilawall"]

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    let chosenPath = importCollector.text.trim();
                    if (chosenPath) {
                        console.log("DEBUG: Importing and setting .nilawall wallpaper:", chosenPath);
                        Wallpapers.setWallpaper(chosenPath);
                        
                        // Close subpages back to main settings page
                        root.nState.closeSubPage();
                        root.nState.closeSubPage();
                    }
                }
            }

            stdout: StdioCollector {
                id: importCollector
            }
        }
    ]
}

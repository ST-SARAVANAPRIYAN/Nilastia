import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components.controls
import Nilastia.Services
import qs.components
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root
    isSubPage: true

    title: qsTr("Blur & Transparency")

    function resetToRecommended() {
        Compositor.saveValue("active_opacity", 1.0);
        Compositor.saveValue("inactive_opacity", 0.85);
        Compositor.saveValue("window_blur_enabled", true);
        Compositor.saveValue("blur_passes", 4);
        Compositor.saveValue("blur_offset", 3.0);
        Compositor.saveValue("blur_noise", 0.02);
        Compositor.saveValue("blur_saturation", 1.5);
        Compositor.saveValue("layer_blur_enabled", true);
        Compositor.saveValue("shell_blur_noise", 0.02);
        Compositor.saveValue("shell_blur_saturation", 1.5);
        Compositor.saveValue("prefer_no_csd", true);
        Compositor.saveValue("blur_xray", false);
        Compositor.saveValue("opacity_exclusions", "brave-browser,antigravity-ide,org.quickshell");
    }

    property var runningAppsModel: {
        if (!Hypr || !Hypr._windowsRaw) return [];
        let currentExclusions = Compositor.opacity_exclusions ? Compositor.opacity_exclusions.split(",") : [];
        let apps = [];
        let seen = new Set();
        for (let w of Hypr._windowsRaw) {
            let appId = w.app_id;
            if (!appId) continue;
            if (currentExclusions.indexOf(appId) !== -1) continue;
            if (seen.has(appId)) continue;
            seen.add(appId);
            
            let name = w.title || appId;
            if (name.length > 25) {
                name = name.substring(0, 22) + "...";
            }
            apps.push({ appId: appId, name: name });
        }
        return apps;
    }

    function addExclusion(appId) {
        if (!appId) return;
        let currentExclusions = Compositor.opacity_exclusions ? Compositor.opacity_exclusions.split(",") : [];
        if (currentExclusions.indexOf(appId) === -1) {
            currentExclusions.push(appId);
            Compositor.saveValue("opacity_exclusions", currentExclusions.filter(x => x.trim() !== "").join(","));
        }
    }

    function removeExclusion(appId) {
        if (!appId) return;
        let currentExclusions = Compositor.opacity_exclusions ? Compositor.opacity_exclusions.split(",") : [];
        let index = currentExclusions.indexOf(appId);
        if (index !== -1) {
            currentExclusions.splice(index, 1);
            Compositor.saveValue("opacity_exclusions", currentExclusions.filter(x => x.trim() !== "").join(","));
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Window Transparency Section
        SectionHeader {
            first: true
            text: qsTr("Window Transparency")
        }

        SliderRow {
            first: true
            icon: "opacity"
            label: qsTr("Focused window opacity")
            valueLabel: Math.round(value * 100) + "%"
            value: Compositor.active_opacity
            onMoved: (val) => Compositor.saveValue("active_opacity", parseFloat(val.toFixed(2)))
        }

        SliderRow {
            last: true
            icon: "opacity"
            label: qsTr("Unfocused window opacity")
            valueLabel: Math.round(value * 100) + "%"
            value: Compositor.inactive_opacity
            onMoved: (val) => Compositor.saveValue("inactive_opacity", parseFloat(val.toFixed(2)))
        }

        // Opacity Exclusions Section
        SectionHeader {
            text: qsTr("Opacity Exclusions")
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: exclusionsLayout.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainer

            ColumnLayout {
                id: exclusionsLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                StyledText {
                    text: qsTr("Excluded applications will not have forced window opacity rules applied.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    Layout.fillWidth: true
                }

                // Current exclusions chips
                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small
                    visible: (Compositor.opacity_exclusions ? Compositor.opacity_exclusions.split(",").filter(x => x.trim() !== "").length : 0) > 0

                    Repeater {
                        model: Compositor.opacity_exclusions ? Compositor.opacity_exclusions.split(",").filter(x => x.trim() !== "") : []
                        delegate: StyledRect {
                            implicitWidth: appRow.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: 32
                            radius: Tokens.rounding.small
                            color: Colours.palette.m3surfaceVariant

                            RowLayout {
                                id: appRow
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.extraSmall
                                spacing: Tokens.spacing.extraSmall

                                StyledText {
                                    text: modelData
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.medium
                                }

                                IconButton {
                                    icon: "close"
                                    type: IconButton.Text
                                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.icon.small
                                    padding: Tokens.padding.extraSmall / 2
                                    onClicked: removeExclusion(modelData)
                                }
                            }
                        }
                    }
                }

                // Add manual input
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledTextField {
                        id: manualExcludeInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("Add manually (e.g. firefox)")
                        onAccepted: {
                            if (text.trim() !== "") {
                                addExclusion(text.trim());
                                text = "";
                            }
                        }
                    }

                    IconButton {
                        icon: "add"
                        onClicked: {
                            if (manualExcludeInput.text.trim() !== "") {
                                addExclusion(manualExcludeInput.text.trim());
                                manualExcludeInput.text = "";
                            }
                        }
                    }
                }

                // Add from running apps
                StyledText {
                    text: qsTr("Click to exclude running apps:")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    visible: runningAppsModel.length > 0
                    Layout.topMargin: Tokens.spacing.extraSmall
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small
                    visible: runningAppsModel.length > 0

                    Repeater {
                        model: runningAppsModel
                        delegate: StyledRect {
                            implicitWidth: runningAppRow.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: 32
                            radius: Tokens.rounding.small
                            color: Colours.palette.m3surfaceVariant

                            StateLayer {
                                radius: parent.radius
                                onClicked: addExclusion(modelData.appId)
                            }

                            RowLayout {
                                id: runningAppRow
                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.medium
                                anchors.rightMargin: Tokens.padding.medium
                                spacing: Tokens.spacing.extraSmall

                                StyledText {
                                    text: modelData.name
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.body.medium
                                }

                                StyledText {
                                    text: "(" + modelData.appId + ")"
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                    opacity: 0.6
                                }
                            }
                        }
                    }
                }
            }
        }

        // Window Background Blur Section
        SectionHeader {
            text: qsTr("Window Background Blur")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Enable window background blur")
            subtext: qsTr("Apply blur filters behind transparent windows")
            checked: Compositor.window_blur_enabled
            onClicked: {
                let targetState = !Compositor.window_blur_enabled;
                Compositor.saveValue("window_blur_enabled", targetState);
                if (targetState && Compositor.blur_passes === 0) {
                    Compositor.saveValue("blur_passes", 4); // Default to 4 passes
                } else if (!targetState) {
                    Compositor.saveValue("blur_passes", 0); // Disable passes
                }
            }
        }

        // Sub-settings for Blur (only active/visible when blur passes > 0)
        ColumnLayout {
            Layout.fillWidth: true
            visible: Compositor.blur_passes > 0
            spacing: Tokens.spacing.extraSmall / 2


            StepperRow {
                label: qsTr("Blur passes")
                subtext: qsTr("Higher values increase blur strength & smooth quality")
                value: Compositor.blur_passes
                from: 1
                to: 10
                stepSize: 1
                onMoved: (value) => Compositor.saveValue("blur_passes", Math.round(value))
            }

            StepperRow {
                label: qsTr("Blur offset")
                subtext: qsTr("Offset radius for blur filter convolution (px)")
                value: Compositor.blur_offset
                from: 0.0
                to: 15.0
                stepSize: 0.5
                onMoved: (value) => Compositor.saveValue("blur_offset", parseFloat(value.toFixed(1)))
            }

            StepperRow {
                label: qsTr("Blur noise overlay")
                subtext: qsTr("Reduces color banding in blurred areas")
                value: Compositor.blur_noise
                from: 0.0
                to: 0.5
                stepSize: 0.01
                onMoved: (value) => Compositor.saveValue("blur_noise", parseFloat(value.toFixed(2)))
            }

            StepperRow {
                last: true
                label: qsTr("Blur color saturation")
                subtext: qsTr("Color vibrancy/intensity boost behind windows")
                value: Compositor.blur_saturation
                from: 0.0
                to: 3.0
                stepSize: 0.1
                onMoved: (value) => Compositor.saveValue("blur_saturation", parseFloat(value.toFixed(1)))
            }
        }

        // Shell Layer Blur Section
        SectionHeader {
            text: qsTr("Shell Layer Blur")
        }

        ToggleRow {
            first: true
            last: !Compositor.layer_blur_enabled
            text: qsTr("Enable blur on system layers")
            subtext: qsTr("Apply blur to the top bar, launcher, sidebar, and menus")
            checked: Compositor.layer_blur_enabled
            onToggled: Compositor.saveValue("layer_blur_enabled", checked)
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Compositor.layer_blur_enabled
            spacing: Tokens.spacing.extraSmall / 2

            StepperRow {
                label: qsTr("Shell blur noise overlay")
                subtext: qsTr("Reduces color banding in blurred shell regions")
                value: Compositor.shell_blur_noise
                from: 0.0
                to: 0.5
                stepSize: 0.01
                onMoved: (value) => Compositor.saveValue("shell_blur_noise", parseFloat(value.toFixed(2)))
            }

            StepperRow {
                last: true
                label: qsTr("Shell blur color saturation")
                subtext: qsTr("Color vibrancy/intensity boost behind shell panels")
                value: Compositor.shell_blur_saturation
                from: 0.0
                to: 3.0
                stepSize: 0.1
                onMoved: (value) => Compositor.saveValue("shell_blur_saturation", parseFloat(value.toFixed(1)))
            }
        }

        // Decorations Section
        SectionHeader {
            text: qsTr("Window Decorations")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Prefer no Client-Side Decorations (CSD)")
            subtext: qsTr("Enforce server-side window framing to avoid app control overlaps")
            checked: Compositor.prefer_no_csd
            onClicked: {
                Compositor.saveValue("prefer_no_csd", !Compositor.prefer_no_csd);
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.medium
            Layout.bottomMargin: Tokens.padding.medium

            Item {
                Layout.fillWidth: true
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                icon: "restart_alt"
                text: qsTr("Reset to Recommended Defaults")
                onClicked: root.resetToRecommended()
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}

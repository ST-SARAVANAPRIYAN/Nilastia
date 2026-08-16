pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Nilastia.Components
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Create Parallax Wallpaper")
    isSubPage: true

    // --- Wizard Flow States ---
    property int wizardStep: 1  // 1 = Add & Order, 2 = Configure & Preview
    property bool manualMode: false
    property string activePreset: "balanced" // "soft", "balanced", "cinematic"

    // --- Wallpaper Builder Parameters ---
    property string themeName: qsTr("My Custom Parallax")
    property real stiffnessNorm: (2.0 - 0.5) / 9.5
    property real dampingNorm: (0.8 - 0.1) / 0.9
    property real maxXNorm: (35.0 - 5.0) / 95.0
    property real maxYNorm: (20.0 - 5.0) / 95.0

    readonly property real stiffnessVal: 0.5 + 9.5 * stiffnessNorm
    readonly property real dampingVal: 0.1 + 0.9 * dampingNorm
    readonly property real maxXVal: 5.0 + 95.0 * maxXNorm
    readonly property real maxYVal: 5.0 + 95.0 * maxYNorm

    property real globalDepthScale: 1.0
    property var layersList: []

    // --- Helper function to apply presets ---
    function applyPreset(presetName) {
        activePreset = presetName;
        if (presetName === "soft") {
            stiffnessNorm = (3.5 - 0.5) / 9.5;
            dampingNorm = (0.9 - 0.1) / 0.9;
            maxXNorm = (15.0 - 5.0) / 95.0;
            maxYNorm = (15.0 - 5.0) / 95.0;
        } else if (presetName === "balanced") {
            stiffnessNorm = (2.0 - 0.5) / 9.5;
            dampingNorm = (0.8 - 0.1) / 0.9;
            maxXNorm = (35.0 - 5.0) / 95.0;
            maxYNorm = (20.0 - 5.0) / 95.0;
        } else if (presetName === "cinematic") {
            stiffnessNorm = (1.5 - 0.5) / 9.5;
            dampingNorm = (0.7 - 0.1) / 0.9;
            maxXNorm = (60.0 - 5.0) / 95.0;
            maxYNorm = (40.0 - 5.0) / 95.0;
        }
    }

    // --- Helper to auto-assign depths based on rendering order ---
    function autoAssignLayerConfigs() {
        let N = layersList.length;
        if (N === 0) return;
        
        let list = layersList.slice();
        if (N === 1) {
            list[0].depth = 0.5;
            list[0].sensitivity = 1.0;
        } else {
            for (let i = 0; i < N; i++) {
                // Background (index 0) gets 0.1 depth, Foreground (index N-1) gets 1.0 depth
                let ratio = i / (N - 1);
                list[i].depth = 0.1 + ratio * 0.9;
                list[i].sensitivity = 1.0;
            }
        }
        layersList = list;
    }

    // --- Helpers to manage layers array ---
    function addLayer(path) {
        let list = layersList.slice();
        list.push({
            path: path,
            depth: 0.5,
            sensitivity: 1.0
        });
        layersList = list;
    }

    function removeLayer(index) {
        let list = layersList.slice();
        list.splice(index, 1);
        layersList = list;
    }

    function moveLayerUp(index) {
        if (index <= 0) return;
        let list = layersList.slice();
        let temp = list[index];
        list[index] = list[index - 1];
        list[index - 1] = temp;
        layersList = list;
    }

    function moveLayerDown(index) {
        if (index >= layersList.length - 1) return;
        let list = layersList.slice();
        let temp = list[index];
        list[index] = list[index + 1];
        list[index + 1] = temp;
        layersList = list;
    }

    function updateDepth(index, newDepth) {
        let list = layersList.slice();
        list[index].depth = newDepth;
        layersList = list;
    }

    function updateSensitivity(index, newSensitivity) {
        let list = layersList.slice();
        list[index].sensitivity = newSensitivity;
        layersList = list;
    }

    // --- Live interactive preview mouse tracking ---
    property real targetX: 0
    property real targetY: 0
    property real inputX: 0
    property real inputY: 0

    Behavior on inputX {
        SpringAnimation {
            spring: root.stiffnessVal
            damping: root.dampingVal
            epsilon: 0.0005
        }
    }

    Behavior on inputY {
        SpringAnimation {
            spring: root.stiffnessVal
            damping: root.dampingVal
            epsilon: 0.0005
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraLargeIncreased

        // ==========================================
        // STEP 1: ADD & ORDER LAYERS
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.wizardStep === 1
            spacing: Tokens.spacing.extraLarge

            SectionHeader {
                text: qsTr("Step 1: Arrange Wallpaper Layers")
            }

            // Info Card explaining stack order
            ConnectedRect {
                Layout.fillWidth: true
                first: true
                last: true
                implicitHeight: infoTextCol.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: infoTextCol
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        text: qsTr("How Stacking Works")
                        font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: qsTr("Layers render from bottom to top. The top item in the list is the Background (shifts very little), and the bottom item is the Foreground (shifts the most).")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Empty state placeholder
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 180
                color: Colours.palette.m3surfaceContainerLowest
                radius: Tokens.rounding.large
                visible: root.layersList.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "layers"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No layers added yet")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.medium
                    }
                }
            }

            // List of Layers in Step 1
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small
                visible: root.layersList.length > 0

                Repeater {
                    model: root.layersList
                    delegate: ConnectedRect {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: layerRowLayout.implicitHeight + Tokens.padding.large * 2

                        RowLayout {
                            id: layerRowLayout
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.large
                            spacing: Tokens.spacing.medium

                            Image {
                                source: "file://" + modelData.path
                                fillMode: Image.PreserveAspectCrop
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 45
                                clip: true
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: Colours.palette.m3outlineVariant
                                    border.width: 1
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: index === 0 ? qsTr("Layer %1 (Background)").arg(index + 1) :
                                          index === root.layersList.length - 1 ? qsTr("Layer %1 (Foreground)").arg(index + 1) :
                                          qsTr("Layer %1").arg(index + 1)
                                    font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                                    color: index === 0 ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                }

                                StyledText {
                                    text: modelData.path.split("/").pop()
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3onSurfaceVariant
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }

                            IconButton {
                                icon: "arrow_upward"
                                disabled: index === 0
                                onClicked: root.moveLayerUp(index)
                            }

                            IconButton {
                                icon: "arrow_downward"
                                disabled: index === root.layersList.length - 1
                                onClicked: root.moveLayerDown(index)
                            }

                            IconButton {
                                icon: "delete"
                                inactiveColour: "transparent"
                                inactiveOnColour: Colours.palette.m3error
                                onClicked: root.removeLayer(index)
                            }
                        }
                    }
                }
            }

            // Big Add Layer Button
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                icon: "add_photo_alternate"
                text: qsTr("Add Layer Image")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                onClicked: zenityAddLayerPicker.running = true
            }

            // Next Step CTA
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.medium
                icon: "navigate_next"
                text: qsTr("Auto-Configure & Preview")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                disabled: root.layersList.length === 0
                
                onClicked: {
                    root.autoAssignLayerConfigs();
                    root.applyPreset("balanced");
                    root.manualMode = false;
                    root.wizardStep = 2;
                }
            }
        }

        // ==========================================
        // STEP 2: PREVIEW & CUSTOMIZE PHYSICS
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.wizardStep === 2
            spacing: Tokens.spacing.extraLarge

            SectionHeader {
                text: qsTr("Step 2: Preview & Tuning")
            }

            // Interactive Preview Box
            StyledClippingRect {
                Layout.fillWidth: true
                implicitHeight: Math.round(width * 0.45)
                color: Colours.palette.m3surfaceContainerLowest
                radius: Tokens.rounding.large

                Repeater {
                    model: root.layersList
                    delegate: Image {
                        required property var modelData
                        required property int index

                        anchors.fill: parent
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        
                        readonly property real dispX: root.inputX * modelData.depth * modelData.sensitivity * root.maxXVal * root.globalDepthScale
                        readonly property real dispY: root.inputY * modelData.depth * modelData.sensitivity * root.maxYVal * root.globalDepthScale

                        transform: Translate {
                            x: dispX
                            y: dispY
                        }
                        scale: 1.15
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onPositionChanged: {
                        let cx = width / 2;
                        let cy = height / 2;
                        root.targetX = (mouseX - cx) / cx;
                        root.targetY = (mouseY - cy) / cy;
                    }
                    onExited: {
                        root.targetX = 0;
                        root.targetY = 0;
                    }
                }
            }

            StyledTextField {
                id: wallpaperNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Wallpaper Name")
                leadingIcon: "edit"
                supportingText: qsTr("Give your custom wallpaper a name")
                text: root.themeName
                onTextChanged: root.themeName = text
            }

            // Manual Mode Toggle Switch
            ToggleRow {
                first: true
                last: !root.manualMode
                text: qsTr("Manual Tuning Mode")
                subtext: qsTr("Enable to customize individual layers and fine-tune spring easing physics")
                checked: root.manualMode
                onToggled: root.manualMode = checked
            }

            // Preset Selectors (Visible ONLY in Auto Mode)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                visible: !root.manualMode

                SectionHeader {
                    text: qsTr("Preset Sensitivity")
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        text: qsTr("Soft Drift")
                        type: root.activePreset === "soft" ? IconTextButton.Filled : IconTextButton.Tonal
                        onClicked: root.applyPreset("soft")
                    }

                    IconTextButton {
                        text: qsTr("Balanced")
                        type: root.activePreset === "balanced" ? IconTextButton.Filled : IconTextButton.Tonal
                        onClicked: root.applyPreset("balanced")
                    }

                    IconTextButton {
                        text: qsTr("Cinematic Depth")
                        type: root.activePreset === "cinematic" ? IconTextButton.Filled : IconTextButton.Tonal
                        onClicked: root.applyPreset("cinematic")
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                SectionHeader {
                    text: qsTr("Depth Effect Scale")
                }

                SliderRow {
                    first: true
                    last: true
                    icon: "layers"
                    label: qsTr("Parallax Intensity")
                    valueLabel: root.globalDepthScale.toFixed(1) + "x"
                    value: (root.globalDepthScale - 0.2) / 2.8
                    onMoved: v => root.globalDepthScale = 0.2 + 2.8 * v
                }
            }

            // Manual Easing Controls (Visible ONLY in Manual Mode)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2
                visible: root.manualMode

                SectionHeader {
                    text: qsTr("Physics Settings")
                }

                SliderRow {
                    first: true
                    icon: "speed"
                    label: qsTr("Spring Stiffness")
                    valueLabel: root.stiffnessVal.toFixed(1)
                    value: root.stiffnessNorm
                    onMoved: v => root.stiffnessNorm = v
                }

                SliderRow {
                    icon: "tune"
                    label: qsTr("Spring Damping (Friction)")
                    valueLabel: root.dampingVal.toFixed(2)
                    value: root.dampingNorm
                    onMoved: v => root.dampingNorm = v
                }

                SliderRow {
                    icon: "straighten"
                    label: qsTr("Max Panning displacement X")
                    valueLabel: Math.round(root.maxXVal) + "px"
                    value: root.maxXNorm
                    onMoved: v => root.maxXNorm = v
                }

                SliderRow {
                    last: true
                    icon: "straighten"
                    label: qsTr("Max Panning displacement Y")
                    valueLabel: Math.round(root.maxYVal) + "px"
                    value: root.maxYNorm
                    onMoved: v => root.maxYNorm = v
                }
            }

            // Manual Layer Adjustments (Visible ONLY in Manual Mode)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                visible: root.manualMode

                SectionHeader {
                    text: qsTr("Layer Settings")
                }

                Repeater {
                    model: root.layersList
                    delegate: ConnectedRect {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: manualLayerCol.implicitHeight + Tokens.padding.large * 2

                        ColumnLayout {
                            id: manualLayerCol
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.large
                            spacing: Tokens.spacing.medium

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                Image {
                                    source: "file://" + modelData.path
                                    fillMode: Image.PreserveAspectCrop
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 36
                                    clip: true
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.color: Colours.palette.m3outlineVariant
                                        border.width: 1
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: index === 0 ? qsTr("Layer %1 (Background)").arg(index + 1) :
                                              index === root.layersList.length - 1 ? qsTr("Layer %1 (Foreground)").arg(index + 1) :
                                              qsTr("Layer %1").arg(index + 1)
                                        font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                                        color: Colours.palette.m3primary
                                    }

                                    StyledText {
                                        text: modelData.path.split("/").pop()
                                        font: Tokens.font.body.small
                                        color: Colours.palette.m3onSurface
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    StyledText {
                                        text: qsTr("Depth (Shift): %1").arg(modelData.depth.toFixed(2))
                                        font: Tokens.font.label.small
                                        Layout.preferredWidth: 140
                                    }

                                    StyledSlider {
                                        Layout.fillWidth: true
                                        radius: Tokens.rounding.small
                                        value: (modelData.depth + 2.0) / 4.0
                                        onInteraction: v => root.updateDepth(index, (v * 4.0) - 2.0)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    StyledText {
                                        text: qsTr("Sensitivity: %1").arg(modelData.sensitivity.toFixed(2))
                                        font: Tokens.font.label.small
                                        Layout.preferredWidth: 140
                                    }

                                    StyledSlider {
                                        Layout.fillWidth: true
                                        radius: Tokens.rounding.small
                                        value: modelData.sensitivity / 2.0
                                        onInteraction: v => root.updateSensitivity(index, v * 2.0)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Build Actions Row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.medium

                IconTextButton {
                    icon: "arrow_back"
                    text: qsTr("Back to Layers")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    type: IconTextButton.Tonal
                    onClicked: root.wizardStep = 1
                }

                IconTextButton {
                    id: saveBtn
                    icon: "save"
                    text: qsTr("Build & Apply")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    disabled: root.layersList.length === 0 || !root.themeName.trim()
                    
                    onClicked: {
                        disabled = true;
                        saveBtn.text = qsTr("Building...");
                        
                        let simplifiedLayers = root.layersList.map(layer => ({
                            path: layer.path,
                            depth: layer.depth * root.globalDepthScale,
                            sensitivity: layer.sensitivity
                        }));
                        
                        builderProc.command = [
                            "/home/saravana/projects/calestia/nilastia/utils/scripts/wallpaper_builder.py",
                            "--name", root.themeName,
                            "--stiffness", root.stiffnessVal.toString(),
                            "--damping", root.dampingVal.toString(),
                            "--max-x", root.maxXVal.toString(),
                            "--max-y", root.maxYVal.toString(),
                            "--layers", JSON.stringify(simplifiedLayers)
                        ];
                        
                        builderProc.running = true;
                    }
                }
            }
        }
    }

    resources: [
        Binding {
            target: root
            property: "inputX"
            value: root.targetX
        },
        Binding {
            target: root
            property: "inputY"
            value: root.targetY
        },
        Process {
            id: zenityAddLayerPicker
            command: ["zenity", "--file-selection", "--title=Select Layer Image", "--file-filter=Images | *.png *.jpg *.jpeg *.webp"]

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    let chosenPath = addLayerCollector.text.trim();
                    if (chosenPath) {
                        root.addLayer(chosenPath);
                    }
                }
            }

            stdout: StdioCollector {
                id: addLayerCollector
            }
        },
        Process {
            id: builderProc

            onExited: (exitCode, exitStatus) => {
                saveBtn.text = qsTr("Build & Apply");
                saveBtn.disabled = false;

                if (exitCode === 0) {
                    let pathLine = collector.text.split("\n").find(line => line.startsWith("PATH:"));
                    let zipLine = collector.text.split("\n").find(line => line.startsWith("ZIP:"));
                    
                    let path = pathLine ? pathLine.substring(5).trim() : "";
                    let zipPath = zipLine ? zipLine.substring(4).trim() : "";

                    if (path) {
                        console.log("DEBUG: Builder successfully finished, setting wallpaper:", path);
                        Wallpapers.setWallpaper(path);
                        
                        if (zipPath && typeof Toaster !== "undefined" && Toaster) {
                            Toaster.toast(qsTr("Wallpaper Compiled"), qsTr("Portable zip package saved to: %1").arg(zipPath.split("/").pop()), "archive");
                        }
                        
                        root.nState.closeSubPage();
                    } else {
                        console.error("Builder succeeded but output is missing PATH instruction line");
                    }
                } else {
                    console.error("Wallpaper builder script failed:", collector.text);
                }
            }

            stdout: StdioCollector {
                id: collector
            }
        }
    ]
}

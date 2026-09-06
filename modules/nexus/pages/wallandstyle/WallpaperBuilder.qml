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
import "../../../background"

PageBase {
    id: root

    title: (root.nState && root.nState.editActiveWallpaperOnly) ? qsTr("Edit Parallax Wallpaper") : qsTr("Create Parallax Wallpaper")
    isSubPage: true

    readonly property bool isCurrentParallax: Wallpapers.actualCurrent && (Wallpapers.actualCurrent.toLowerCase().endsWith("wallpaper.json") || Wallpapers.actualCurrent.toLowerCase().endsWith(".nilawall"))
    readonly property bool isEditingNonParallax: root.nState && root.nState.editActiveWallpaperOnly && !root.isCurrentParallax

    Component.onCompleted: {
        if (root.nState && root.nState.editActiveWallpaperOnly && root.isCurrentParallax) {
            let localPath = Paths.toLocalFile(Wallpapers.actualCurrent);
            unpackerProc.command = [
                "python3",
                Paths.toLocalFile(Qt.resolvedUrl("../../../../utils/scripts/wallpaper_builder.py")),
                "--unpack", localPath
            ];
            if (!unpackerProc.running) {
                unpackerProc.running = true;
            }
        }
    }

    Component.onDestruction: {
        root.clearLayers();
    }

    // --- Wizard Flow States ---
    property int wizardStep: 1  // 1 = Add & Order, 2 = Configure & Preview
    property bool manualMode: false
    property string activePreset: "balanced" // "soft", "balanced", "cinematic"

    // --- Wallpaper Builder Parameters ---
    property string themeName: qsTr("My Custom Parallax")
    property int durationVal: 800
    property real maxXNorm: (75.0 - 10.0) / 170.0
    property real maxYNorm: (45.0 - 10.0) / 110.0

    readonly property real maxXVal: 10.0 + 170.0 * maxXNorm
    readonly property real maxYVal: 10.0 + 110.0 * maxYNorm

    property real globalDepthScale: 1.0
    property var layersList: []

    // --- Helper function to apply presets ---
    function applyPreset(presetName) {
        activePreset = presetName;
        if (presetName === "soft") {
            durationVal = 600;
            maxXNorm = (40.0 - 10.0) / 170.0;
            maxYNorm = (25.0 - 10.0) / 110.0;
        } else if (presetName === "balanced") {
            durationVal = 800;
            maxXNorm = (75.0 - 10.0) / 170.0;
            maxYNorm = (45.0 - 10.0) / 110.0;
        } else if (presetName === "cinematic") {
            durationVal = 1500;
            maxXNorm = (130.0 - 10.0) / 170.0;
            maxYNorm = (80.0 - 10.0) / 110.0;
        }
    }

    function createLayerItem(path, depth, sensitivity) {
        return layerItemComp.createObject(root, {
            path: path,
            depth: (typeof depth === "number") ? depth : 0.5,
            sensitivity: (typeof sensitivity === "number") ? sensitivity : 1.0
        });
    }

    function clearLayers() {
        for (let i = 0; i < layersList.length; i++) {
            if (layersList[i] && layersList[i].destroy) {
                layersList[i].destroy();
            }
        }
        layersList = [];
    }

    // --- Helper to auto-assign depths based on rendering order ---
    function autoAssignLayerConfigs() {
        let N = layersList.length;
        if (N === 0) return;
        
        if (N === 1) {
            layersList[0].depth = 0.0;
            layersList[0].sensitivity = 1.0;
        } else {
            for (let i = 0; i < N; i++) {
                // Background (index 0) gets -0.5 depth, Foreground (index N-1) gets 0.5 depth
                let ratio = i / (N - 1);
                layersList[i].depth = -0.5 + ratio * 1.0;
                layersList[i].sensitivity = 1.0;
            }
        }
    }

    // --- Helpers to manage layers array ---
    function addLayer(path) {
        addLayers([path]);
    }

    function addLayers(paths) {
        let list = layersList.slice();
        for (let i = 0; i < paths.length; i++) {
            let p = paths[i].trim();
            if (p) {
                list.push(createLayerItem(p, 0.5, 1.0));
            }
        }
        layersList = list;
    }

    function removeLayer(index) {
        if (index < 0 || index >= layersList.length) return;
        let list = layersList.slice();
        let item = list.splice(index, 1)[0];
        if (item && item.destroy) {
            item.destroy();
        }
        layersList = list;
    }

    function moveLayerUp(index) {
        if (index <= 0 || index >= layersList.length) return;
        let list = layersList.slice();
        let temp = list[index];
        list[index] = list[index - 1];
        list[index - 1] = temp;
        layersList = list;
        if (!manualMode) {
            autoAssignLayerConfigs();
        }
    }

    function moveLayerDown(index) {
        if (index < 0 || index >= layersList.length - 1) return;
        let list = layersList.slice();
        let temp = list[index];
        list[index] = list[index + 1];
        list[index + 1] = temp;
        layersList = list;
        if (!manualMode) {
            autoAssignLayerConfigs();
        }
    }

    function updateDepth(index, newDepth) {
        if (index >= 0 && index < layersList.length && layersList[index]) {
            layersList[index].depth = newDepth;
        }
    }

    function updateSensitivity(index, newSensitivity) {
        if (index >= 0 && index < layersList.length && layersList[index]) {
            layersList[index].sensitivity = newSensitivity;
        }
    }

    // --- Live interactive preview mouse tracking ---
    property real targetX: 0
    property real targetY: 0
    property real inputX: targetX
    property real inputY: targetY

    Behavior on inputX {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutCubic
        }
    }

    Behavior on inputY {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraLargeIncreased

        // Notice if in Edit mode but active wallpaper is not parallax
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: nonParallaxCol.implicitHeight + Tokens.padding.large * 2
            visible: root.isEditingNonParallax

            ColumnLayout {
                id: nonParallaxCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    spacing: Tokens.spacing.small
                    MaterialIcon {
                        text: "info"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }
                    StyledText {
                        text: qsTr("Active Wallpaper is Not Parallax")
                        font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                        color: Colours.palette.m3primary
                    }
                }

                StyledText {
                    text: qsTr("The currently active desktop wallpaper is a static image. You can build a brand new parallax wallpaper below, or apply an existing .nilawall preset from the gallery.")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // Unpacking Progress Card
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: unpackingCol.implicitHeight + Tokens.padding.large * 2
            visible: unpackerProc.running

            ColumnLayout {
                id: unpackingCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium
                    MaterialIcon {
                        text: "hourglass_top"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }
                    StyledText {
                        text: qsTr("Unpacking active parallax layers...")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }

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
                                visible: modelData.path !== "virtual://clock"
                                source: modelData.path.startsWith("data:") ? modelData.path : "file://" + modelData.path
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

                            MaterialIcon {
                                visible: modelData.path === "virtual://clock"
                                text: "schedule"
                                fontStyle: Tokens.font.icon.large
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 45
                                Layout.alignment: Qt.AlignCenter
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
                                    text: modelData.path === "virtual://clock" ? qsTr("System Desktop Clock") : modelData.path.split("/").pop()
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

            // Add Layer Actions Row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.medium

                IconTextButton {
                    icon: "add_photo_alternate"
                    text: qsTr("Add Layer Image")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    type: IconTextButton.Tonal
                    onClicked: zenityAddLayerPicker.running = true
                }

                IconTextButton {
                    icon: "schedule"
                    text: qsTr("Insert Clock Layer")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    type: IconTextButton.Tonal
                    disabled: root.layersList.some(layer => layer.path === "virtual://clock")
                    onClicked: root.addLayer("virtual://clock")
                }
            }

            // Next Step CTA
            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.medium
                icon: "navigate_next"
                text: qsTr("Preview & Tuning")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                disabled: root.layersList.length === 0
                
                onClicked: {
                    if (!root.activePreset) {
                        root.applyPreset("balanced");
                    }
                    if (root.layersList.length > 0 && root.layersList.every(l => l.depth === 0.5)) {
                        root.autoAssignLayerConfigs();
                    }
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
                    delegate: Loader {
                        id: layerLoader
                        required property var modelData
                        required property int index

                        anchors.fill: parent
                        active: modelData !== undefined
                        sourceComponent: modelData && modelData.path === "virtual://clock" ? previewClockComponent : previewImageComponent

                        onLoaded: {
                            if (item) {
                                item.modelData = modelData;
                            }
                        }

                        Binding {
                            target: layerLoader.item
                            property: "modelData"
                            value: layerLoader.modelData
                        }
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

            IconTextButton {
                visible: root.manualMode
                Layout.alignment: Qt.AlignRight
                icon: "restart_alt"
                text: qsTr("Reset to Automatic Config")
                type: IconTextButton.Tonal
                onClicked: {
                    root.manualMode = false;
                    root.applyPreset("balanced");
                    root.autoAssignLayerConfigs();
                }
            }

            // Preset Selectors
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

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
                    icon: "schedule"
                    label: qsTr("Glide Duration")
                    valueLabel: root.durationVal + " ms"
                    value: (root.durationVal - 200) / 1800
                    onMoved: v => root.durationVal = Math.round(200 + 1800 * v)
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

            // Layer Management & Settings (Visible in Step 2)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium
                visible: root.layersList.length > 0

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
                                    visible: modelData.path !== "virtual://clock"
                                    source: modelData.path.startsWith("data:") ? modelData.path : "file://" + modelData.path
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

                                MaterialIcon {
                                    visible: modelData.path === "virtual://clock"
                                    text: "schedule"
                                    fontStyle: Tokens.font.icon.medium
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 36
                                    Layout.alignment: Qt.AlignCenter
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
                                        text: modelData.path === "virtual://clock" ? qsTr("System Desktop Clock") : modelData.path.split("/").pop()
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

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small
                                visible: root.manualMode

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    StyledText {
                                        text: qsTr("Depth (Shift): %1").arg(modelData.depth.toFixed(2))
                                        font: Tokens.font.label.small
                                        Layout.preferredWidth: 140
                                    }

                                    CustomMouseArea {
                                        Layout.fillWidth: true
                                        implicitHeight: 16

                                        function onWheel(event: WheelEvent): void {
                                            const step = 0.05;
                                            let nextVal = event.angleDelta.y > 0 ? modelData.depth + step : modelData.depth - step;
                                            root.updateDepth(index, Math.max(-2.0, Math.min(2.0, nextVal)));
                                        }

                                        StyledSlider {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: Tokens.rounding.small
                                            value: (modelData.depth + 2.0) / 4.0
                                            onInteraction: v => root.updateDepth(index, (v * 4.0) - 2.0)
                                        }
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

                                    CustomMouseArea {
                                        Layout.fillWidth: true
                                        implicitHeight: 16

                                        function onWheel(event: WheelEvent): void {
                                            const step = 0.05;
                                            let nextVal = event.angleDelta.y > 0 ? modelData.sensitivity + step : modelData.sensitivity - step;
                                            root.updateSensitivity(index, Math.max(0.0, Math.min(2.0, nextVal)));
                                        }

                                        StyledSlider {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
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

                // Add Layer & Clock Actions in Step 2
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium

                    IconTextButton {
                        icon: "add_photo_alternate"
                        text: qsTr("Add Layer Image")
                        font: Tokens.font.body.medium
                        isRound: true
                        shapeMorph: true
                        type: IconTextButton.Tonal
                        onClicked: zenityAddLayerPicker.running = true
                    }

                    IconTextButton {
                        icon: "schedule"
                        text: qsTr("Insert Clock Layer")
                        font: Tokens.font.body.medium
                        isRound: true
                        shapeMorph: true
                        type: IconTextButton.Tonal
                        disabled: root.layersList.some(layer => layer.path === "virtual://clock")
                        onClicked: root.addLayer("virtual://clock")
                    }

                    IconTextButton {
                        icon: "auto_fix_high"
                        text: qsTr("Auto-Distribute Depths")
                        font: Tokens.font.body.medium
                        isRound: true
                        shapeMorph: true
                        type: IconTextButton.Tonal
                        onClicked: root.autoAssignLayerConfigs()
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
                            depth: layer.depth,
                            sensitivity: layer.sensitivity
                        }));
                        
                        builderProc.layersJson = JSON.stringify(simplifiedLayers);
                        builderProc.command = [
                            "python3",
                            Paths.toLocalFile(Qt.resolvedUrl("../../../../utils/scripts/wallpaper_builder.py")),
                            "--name", root.themeName,
                            "--duration", root.durationVal.toString(),
                            "--max-x", root.maxXVal.toString(),
                            "--max-y", root.maxYVal.toString(),
                            "--intensity", root.globalDepthScale.toString(),
                            "--layers", builderProc.layersJson
                        ];
                        
                        console.log("DEBUG: resolved builder path URL:", Qt.resolvedUrl("../../../../utils/scripts/wallpaper_builder.py"));
                        console.log("DEBUG: local builder path:", Paths.toLocalFile(Qt.resolvedUrl("../../../../utils/scripts/wallpaper_builder.py")));
                        console.log("DEBUG: builder command:", JSON.stringify(builderProc.command));
                        
                        builderProc.running = true;
                    }
                }
            }
        }
    }

    resources: [
        Component {
            id: layerItemComp
            QtObject {
                property string path: ""
                property real depth: 0.5
                property real sensitivity: 1.0
            }
        },
        Component {
            id: previewImageComponent
            Image {
                property var modelData
                anchors.fill: parent
                source: modelData && modelData.path ? (modelData.path.startsWith("data:") ? modelData.path : "file://" + modelData.path) : ""
                fillMode: Image.PreserveAspectCrop
                
                readonly property real previewScaleX: parent ? parent.width / 1920.0 : 0.35
                readonly property real previewScaleY: parent ? parent.height / 1080.0 : 0.35
                readonly property real dispX: modelData ? root.inputX * modelData.depth * modelData.sensitivity * root.maxXVal * previewScaleX * root.globalDepthScale : 0
                readonly property real dispY: modelData ? root.inputY * modelData.depth * modelData.sensitivity * root.maxYVal * previewScaleY * root.globalDepthScale : 0

                transform: Translate {
                    x: dispX
                    y: dispY
                }
                scale: 1.15
            }
        },

        Component {
            id: previewClockComponent
            Item {
                property var modelData
                anchors.fill: parent

                readonly property real previewScaleX: parent ? parent.width / 1920.0 : 0.35
                readonly property real previewScaleY: parent ? parent.height / 1080.0 : 0.35
                readonly property real dispX: modelData ? root.inputX * modelData.depth * modelData.sensitivity * root.maxXVal * previewScaleX * root.globalDepthScale : 0
                readonly property real dispY: modelData ? root.inputY * modelData.depth * modelData.sensitivity * root.maxYVal * previewScaleY * root.globalDepthScale : 0

                Loader {
                    id: previewEmbeddedClock
                    asynchronous: true
                    active: Config.background.desktopClock.enabled
                    scale: 0.45
                    
                    readonly property real defaultMargin: Tokens.padding.extraLargeIncreased
                    
                    width: item ? item.implicitWidth : 0
                    height: item ? item.implicitHeight : 0

                    anchors.centerIn: parent

                    sourceComponent: DesktopClock {
                        wallpaper: root
                        absX: previewEmbeddedClock.x + dispX
                        absY: previewEmbeddedClock.y + dispY
                    }
                }

                transform: Translate {
                    x: dispX
                    y: dispY
                }
            }
        },

        // Save/Export Prompt Overlay
        Rectangle {
            id: savePromptOverlay
            parent: root
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
            visible: false
            z: 9999
            
            property string compiledPath: ""

            // Prevent mouse clicks from propagating through the overlay
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {}
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, 420)
                height: layout.implicitHeight + Tokens.padding.extraLarge * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainerHigh
                border.color: Colours.palette.m3outlineVariant
                border.width: 1
                
                ColumnLayout {
                    id: layout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraLarge
                    spacing: Tokens.padding.large
                    
                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "archive"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    }
                    
                    StyledText {
                        text: qsTr("Wallpaper Created")
                        font: Tokens.font.title.medium
                        color: Colours.palette.m3onSurface
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    StyledText {
                        text: qsTr("The wallpaper has been successfully built and applied. Would you like to open it in your file manager to copy or share the portable file?")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    RowLayout {
                        spacing: Tokens.padding.medium
                        Layout.alignment: Qt.AlignHCenter
                        
                        IconTextButton {
                            icon: "close"
                            text: qsTr("No, Close")
                            isRound: true
                            type: IconTextButton.Tonal
                            onClicked: {
                                savePromptOverlay.visible = false;
                                root.nState.closeSubPage();
                            }
                        }
                        
                        IconTextButton {
                            icon: "folder"
                            text: qsTr("Yes, Open")
                            isRound: true
                            type: IconTextButton.Filled
                            onClicked: {
                                Quickshell.execDetached(["xdg-open", savePromptOverlay.compiledPath.substring(0, savePromptOverlay.compiledPath.lastIndexOf("/"))]);
                                savePromptOverlay.visible = false;
                                root.nState.closeSubPage();
                            }
                        }
                    }
                }
            }
        },
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
            command: ["zenity", "--file-selection", "--multiple", "--separator=|", "--title=Select Layer Images", "--file-filter=Images | *.png *.jpg *.jpeg *.webp"]

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    let chosenPath = addLayerCollector.text.trim();
                    if (chosenPath) {
                        let paths = chosenPath.split("|");
                        root.addLayers(paths);
                    }
                }
            }

            stdout: StdioCollector {
                id: addLayerCollector
            }
        },
        Process {
            id: builderProc
            property string layersJson: ""

            onExited: (exitCode, exitStatus) => {
                saveBtn.text = qsTr("Build & Apply");
                saveBtn.disabled = false;

                if (exitCode === 0) {
                    let pathLine = collector.text.split("\n").find(line => line.startsWith("PATH:"));
                    let path = pathLine ? pathLine.substring(5).trim() : "";

                    if (path) {
                        console.log("DEBUG: Builder successfully finished, setting wallpaper:", path);
                        Wallpapers.setWallpaper(path);
                        
                        if (typeof Toaster !== "undefined" && Toaster) {
                            Toaster.toast(qsTr("Wallpaper Compiled"), qsTr("Portable wallpaper saved to: %1").arg(path.split("/").pop()), "archive");
                        }
                        
                        savePromptOverlay.compiledPath = path;
                        savePromptOverlay.visible = true;
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
        },
        Process {
            id: unpackerProc

            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    try {
                        let result = JSON.parse(unpackerCollector.text);
                        root.themeName = result.name;
                        root.durationVal = result.duration;
                        root.maxXNorm = Math.max(0.0, Math.min(1.0, (result.maxX - 10.0) / 170.0));
                        root.maxYNorm = Math.max(0.0, Math.min(1.0, (result.maxY - 10.0) / 110.0));
                        root.globalDepthScale = result.intensity;

                        root.clearLayers();
                        let loadedLayers = [];
                        let layers = result.layers || [];
                        for (let i = 0; i < layers.length; i++) {
                            loadedLayers.push(root.createLayerItem(
                                layers[i].path,
                                layers[i].depth,
                                layers[i].sensitivity
                            ));
                        }
                        root.layersList = loadedLayers;
                        root.globalDepthScale = result.intensity !== undefined ? result.intensity : 1.0;
                        root.manualMode = true; // Turn on manual tuning mode
                        if (root.nState && root.nState.editActiveWallpaperOnly) {
                            root.wizardStep = 2;
                        }
                    } catch (e) {
                        console.error("Failed to parse unpacked JSON output:", e);
                    }
                } else {
                    console.error("Failed to unpack parallax wallpaper via script:", unpackerCollector.text);
                }
            }

            stdout: StdioCollector {
                id: unpackerCollector
            }
        },
        FileView {
            id: activeParallaxConfigLoader
            path: (root.nState && root.nState.editActiveWallpaperOnly && root.isCurrentParallax) ? Wallpapers.actualCurrent : ""
            printErrors: false
            
            onLoaded: {
                let localPath = Paths.toLocalFile(Wallpapers.actualCurrent);
                unpackerProc.command = [
                    "python3",
                    Paths.toLocalFile(Qt.resolvedUrl("../../../../utils/scripts/wallpaper_builder.py")),
                    "--unpack", localPath
                ];
                if (!unpackerProc.running) {
                    unpackerProc.running = true;
                }
            }
        }
    ]
}

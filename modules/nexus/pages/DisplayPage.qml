import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Display")

    property var outputsData: ({})
    property var outputNames: []
    property string selectedOutputName: ""

    // Loaded properties for the active output
    readonly property var activeOutputInfo: selectedOutputName ? outputsData[selectedOutputName] : null
    readonly property bool vrrSupported: activeOutputInfo ? activeOutputInfo.vrr_supported : false
    readonly property bool vrrEnabled: activeOutputInfo ? activeOutputInfo.vrr_enabled : false
    readonly property real currentScale: activeOutputInfo && activeOutputInfo.logical ? activeOutputInfo.logical.scale : 1.0

    // Split resolution / refresh rate list
    property var rawModes: activeOutputInfo ? activeOutputInfo.modes : []
    property var uniqueResolutions: []
    property string selectedResolution: ""

    property var supportedRefreshRates: []
    property string selectedRefreshRateStr: ""

    // Dynamic MenuItem tracking to support robust synchronous updates without Instantiator lag
    property var outputMenuItems: []
    property var resolutionMenuItems: []
    property var refreshRateMenuItems: []

    resources: [
        Component {
            id: menuItemComponent
            MenuItem {}
        }
    ]

    function clearMenuItems(menuList) {
        if (menuList) {
            for (let i = 0; i < menuList.length; i++) {
                if (menuList[i]) {
                    menuList[i].destroy();
                }
            }
        }
    }

    function createMenuItems(sourceList, isRefresh) {
        let result = [];
        for (let i = 0; i < sourceList.length; i++) {
            let itemData = sourceList[i];
            let textVal = isRefresh ? itemData.text : itemData;
            let valueVal = isRefresh ? itemData.value : itemData;

            let obj = menuItemComponent.createObject(root, {
                text: textVal,
                value: valueVal
            });
            if (obj) {
                result.push(obj);
            }
        }
        return result;
    }

    property var lastOutputNames: []
    property var lastUniqueResolutions: []
    property var lastSupportedRefreshRates: []

    function arraysEqual(a, b) {
        if (a === b) return true;
        if (!a || !b) return false;
        if (a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }

    function refreshRatesEqual(a, b) {
        if (a === b) return true;
        if (!a || !b) return false;
        if (a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i].text !== b[i].text || a[i].value !== b[i].value) return false;
        }
        return true;
    }

    function recreateOutputMenuItems() {
        if (arraysEqual(root.outputNames, root.lastOutputNames)) {
            return;
        }
        console.log("[DisplayPage debug] Recreating output menu items, source:", JSON.stringify(root.outputNames));
        clearMenuItems(root.outputMenuItems);
        root.outputMenuItems = createMenuItems(root.outputNames, false);
        root.lastOutputNames = [...root.outputNames];
        console.log("[DisplayPage debug] Output menu items count:", root.outputMenuItems.length);
    }

    function recreateResolutionMenuItems() {
        if (arraysEqual(root.uniqueResolutions, root.lastUniqueResolutions)) {
            return;
        }
        console.log("[DisplayPage debug] Recreating resolution menu items, source:", JSON.stringify(root.uniqueResolutions));
        clearMenuItems(root.resolutionMenuItems);
        root.resolutionMenuItems = createMenuItems(root.uniqueResolutions, false);
        root.lastUniqueResolutions = [...root.uniqueResolutions];
        console.log("[DisplayPage debug] Resolution menu items count:", root.resolutionMenuItems.length);
    }

    function recreateRefreshRateMenuItems() {
        if (refreshRatesEqual(root.supportedRefreshRates, root.lastSupportedRefreshRates)) {
            return;
        }
        console.log("[DisplayPage debug] Recreating refresh rate menu items, source:", JSON.stringify(root.supportedRefreshRates));
        clearMenuItems(root.refreshRateMenuItems);
        root.refreshRateMenuItems = createMenuItems(root.supportedRefreshRates, true);
        root.lastSupportedRefreshRates = JSON.parse(JSON.stringify(root.supportedRefreshRates));
        console.log("[DisplayPage debug] Refresh rate menu items count:", root.refreshRateMenuItems.length);
    }

    onOutputNamesChanged: recreateOutputMenuItems()
    onUniqueResolutionsChanged: recreateResolutionMenuItems()
    onSupportedRefreshRatesChanged: recreateRefreshRateMenuItems()

    Component.onCompleted: {
        console.log("[DisplayPage debug] Component.onCompleted triggered. Initializing MenuItems...");
        recreateOutputMenuItems();
        recreateResolutionMenuItems();
        recreateRefreshRateMenuItems();
    }

    function updateRefreshRates() {
        let tempRates = [];
        if (rawModes) {
            for (let i = 0; i < rawModes.length; i++) {
                let m = rawModes[i];
                if (m.width + "x" + m.height === root.selectedResolution) {
                    let rate = (m.refresh_rate / 1000).toFixed(3);
                    let label = rate + " Hz" + (m.is_preferred ? " (" + qsTr("preferred") + ")" : "");
                    let value = rate;
                    tempRates.push({ text: label, value: value });
                }
            }
        }
        root.supportedRefreshRates = tempRates;

        // Set initial selected refresh rate from activeOutputInfo
        if (activeOutputInfo && activeOutputInfo.modes && activeOutputInfo.modes[activeOutputInfo.current_mode]) {
            let curMode = activeOutputInfo.modes[activeOutputInfo.current_mode];
            let curRes = curMode.width + "x" + curMode.height;
            if (curRes === root.selectedResolution) {
                root.selectedRefreshRateStr = (curMode.refresh_rate / 1000).toFixed(3);
                return;
            }
        }
        if (tempRates.length > 0) {
            root.selectedRefreshRateStr = tempRates[0].value;
        }
    }

    // Rebuild resolution list when active output modes change
    onRawModesChanged: {
        console.log("[DisplayPage debug] rawModes changed, count:", rawModes ? rawModes.length : 0);
        let uniqueRes = [];
        if (rawModes) {
            for (let i = 0; i < rawModes.length; i++) {
                let m = rawModes[i];
                let resStr = m.width + "x" + m.height;
                if (!uniqueRes.includes(resStr)) {
                    uniqueRes.push(resStr);
                }
            }
        }
        root.uniqueResolutions = uniqueRes;

        // Set initial selected resolution from activeOutputInfo
        if (activeOutputInfo && activeOutputInfo.modes && activeOutputInfo.modes[activeOutputInfo.current_mode]) {
            let curMode = activeOutputInfo.modes[activeOutputInfo.current_mode];
            root.selectedResolution = curMode.width + "x" + curMode.height;
        } else if (uniqueRes.length > 0) {
            root.selectedResolution = uniqueRes[0];
        }
        updateRefreshRates();
    }

    // Rebuild refresh rate list when selected resolution changes
    onSelectedResolutionChanged: updateRefreshRates()

    // Force UI dropdown state synchronization on compositor refresh
    onActiveOutputInfoChanged: {
        if (activeOutputInfo && activeOutputInfo.modes) {
            let curIdx = activeOutputInfo.current_mode;
            if (curIdx >= 0 && curIdx < activeOutputInfo.modes.length) {
                let curMode = activeOutputInfo.modes[curIdx];
                let resStr = curMode.width + "x" + curMode.height;
                let rateStr = (curMode.refresh_rate / 1000).toFixed(3);
                
                root.selectedResolution = resStr;
                root.selectedRefreshRateStr = rateStr;
            }
        }
    }

    // Safeguard / Revert variables
    property bool showKeepRevertDialog: false
    property real revertProgress: 1.0

    property string prevMode: ""
    property real prevScale: 1.0
    property bool prevVrr: false

    function getActiveResolutionIndex(): int {
        if (!uniqueResolutions || uniqueResolutions.length === 0) return 0;
        let idx = uniqueResolutions.indexOf(root.selectedResolution);
        return idx >= 0 ? idx : 0;
    }

    function getActiveRefreshRateIndex(): int {
        if (!supportedRefreshRates || supportedRefreshRates.length === 0) return 0;
        for (let i = 0; i < supportedRefreshRates.length; i++) {
            if (supportedRefreshRates[i].value === root.selectedRefreshRateStr) {
                return i;
            }
        }
        return 0;
    }

    function getActiveScaleIndex(): int {
        let sc = root.currentScale;
        if (sc === 1.25) return 1;
        if (sc === 1.5) return 2;
        if (sc === 2.0) return 3;
        return 0;
    }

    function applyChange(modeVal, scaleVal, vrrVal, offVal) {
        if (!selectedOutputName) return;

        // If we are NOT already in the revert verification state, save the previous settings
        if (!showKeepRevertDialog && activeOutputInfo) {
            let curMode = activeOutputInfo.modes[activeOutputInfo.current_mode];
            prevMode = curMode.width + "x" + curMode.height + "@" + (curMode.refresh_rate / 1000).toFixed(3);
            prevScale = root.currentScale;
            prevVrr = root.vrrEnabled;
        }

        let cmd = ["caelestia", "output", selectedOutputName];
        if (offVal) {
            cmd.push("--off");
        } else {
            if (modeVal) {
                cmd.push("-m", modeVal);
            }
            if (scaleVal) {
                cmd.push("-s", String(scaleVal));
            }
            if (vrrVal !== null) {
                if (vrrVal) {
                    cmd.push("--vrr");
                } else {
                    cmd.push("--no-vrr");
                }
            }
        }
        applyProcess.command = cmd;
        applyProcess.running = true;

        // Show the keep / revert safeguard countdown
        if (!offVal) {
            root.showKeepRevertDialog = true;
            revertTimer.secondsRemaining = 5;
            revertTimer.start();
            progressBarAnim.start();
        }
    }

    function keepSettings() {
        revertTimer.stop();
        progressBarAnim.stop();
        root.showKeepRevertDialog = false;
    }

    function revertSettings() {
        revertTimer.stop();
        progressBarAnim.stop();
        root.showKeepRevertDialog = false;

        console.log("Reverting display settings to:", prevMode, prevScale, prevVrr);
        let cmd = ["caelestia", "output", selectedOutputName, "-m", prevMode, "-s", String(prevScale)];
        if (prevVrr) {
            cmd.push("--vrr");
        } else {
            cmd.push("--no-vrr");
        }
        applyProcess.command = cmd;
        applyProcess.running = true;
    }

    // Dynamically generate scaling items list
    readonly property list<MenuItem> scaleItems: [
        MenuItem {
            text: "1.0x (" + qsTr("No scaling") + ")"
            value: 1.0
        },
        MenuItem {
            text: "1.25x"
            value: 1.25
        },
        MenuItem {
            text: "1.5x"
            value: 1.5
        },
        MenuItem {
            text: "2.0x (" + qsTr("Double size") + ")"
            value: 2.0
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        Timer {
            id: revertTimer
            interval: 1000
            repeat: true
            running: false
            property int secondsRemaining: 5
            onTriggered: {
                secondsRemaining--;
                if (secondsRemaining <= 0) {
                    stop();
                    root.revertSettings();
                }
            }
        }
        Timer {
            id: periodicRefreshTimer
            interval: 2000
            repeat: true
            running: true
            onTriggered: {
                if (!refreshProcess.running && !applyProcess.running) {
                    refreshProcess.running = true;
                }
            }
        }

        NumberAnimation {
            id: progressBarAnim
            target: root
            property: "revertProgress"
            from: 1.0
            to: 0.0
            duration: 5000
        }

        // Process to query active Niri outputs
        Process {
            id: refreshProcess
            running: true
            command: ["niri", "msg", "-j", "outputs"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        let data = JSON.parse(text);
                        root.outputsData = data;
                        let keys = Object.keys(data);
                        root.outputNames = keys;
                        if (keys.length > 0 && !keys.includes(root.selectedOutputName)) {
                            root.selectedOutputName = keys[0];
                        }
                    } catch (e) {
                        console.log("Failed to parse Niri outputs JSON:", e);
                    }
                }
            }
        }

        // Process to apply configuration changes
        Process {
            id: applyProcess
            running: false
            onRunningChanged: {
                if (!running) {
                    refreshProcess.running = true;
                }
            }
        }

        // Safeguard Keep / Revert Dialog Card
        ConnectedRect {
            Layout.fillWidth: true
            visible: root.showKeepRevertDialog
            first: true
            last: true
            implicitHeight: revertDialogLayout.implicitHeight + Tokens.padding.large * 2
            color: Colours.palette.m3surfaceVariant

            ColumnLayout {
                id: revertDialogLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    text: qsTr("Keep these display settings?")
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: qsTr("Reverting to previous settings in %1 seconds...").arg(revertTimer.secondsRemaining)
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                // Custom smooth linear progress line (no Behavior conflict lags)
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StyledRect {
                        width: parent.width * root.revertProgress
                        height: parent.height
                        radius: parent.radius
                        color: Colours.palette.m3primary
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.spacing.small

                    TextButton {
                        text: qsTr("Keep changes")
                        type: ButtonBase.Tonal
                        onClicked: root.keepSettings()
                    }

                    TextButton {
                        text: qsTr("Revert")
                        type: ButtonBase.Text
                        onClicked: root.revertSettings()
                    }
                }
            }
        }

        SectionHeader {
            first: !root.showKeepRevertDialog
            text: qsTr("Display Devices")
        }

        // Dropdown to select active output device
        SelectRow {
            id: activeDisplayRow
            first: true
            last: true
            label: qsTr("Active Display")
            subtext: qsTr("Select display device to configure")
            menuItems: root.outputMenuItems
            active: root.outputMenuItems[Math.max(0, root.outputNames.indexOf(root.selectedOutputName))] ?? null
            onSelected: item => {
                root.selectedOutputName = item.value;
            }
        }

        SectionHeader {
            text: qsTr("Display Configuration")
            visible: !!root.selectedOutputName
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: !!root.selectedOutputName

            // Status Toggle (Hidden if there is only 1 display)
            ToggleRow {
                first: true
                text: qsTr("Enable Display")
                subtext: qsTr("Turn this display connector on or off")
                checked: activeOutputInfo ? !activeOutputInfo.off : true
                visible: root.outputNames.length > 1
                onToggled: {
                    let isOff = !checked;
                    root.applyChange(null, null, root.vrrEnabled, isOff);
                }
            }

            // Resolution dropdown
            SelectRow {
                id: resolutionRow
                first: root.outputNames.length <= 1
                label: qsTr("Resolution")
                subtext: qsTr("Select screen resolution")
                menuItems: root.resolutionMenuItems
                active: {
                    let items = root.resolutionMenuItems;
                    let sel = root.selectedResolution;
                    let idx = root.uniqueResolutions.indexOf(sel);
                    return items[idx >= 0 ? idx : 0] ?? null;
                }
                visible: !activeOutputInfo || !activeOutputInfo.off
                onSelected: item => {
                    root.selectedResolution = item.value;
                    let rates = root.supportedRefreshRates;
                    if (rates.length > 0) {
                        root.applyChange(item.value + "@" + rates[0].value, root.currentScale, root.vrrEnabled, false);
                    }
                }
            }

            // Refresh Rate dropdown
            SelectRow {
                id: refreshRateRow
                label: qsTr("Refresh Rate")
                subtext: qsTr("Select output refresh rate")
                menuItems: root.refreshRateMenuItems
                active: {
                    let items = root.refreshRateMenuItems;
                    let sel = root.selectedRefreshRateStr;
                    let idx = 0;
                    for (let i = 0; i < root.supportedRefreshRates.length; i++) {
                        if (root.supportedRefreshRates[i].value === sel) {
                            idx = i;
                            break;
                        }
                    }
                    return items[idx] ?? null;
                }
                visible: !activeOutputInfo || !activeOutputInfo.off
                disabled: GlobalConfig.general.battery.adaptiveRefreshRate
                onSelected: item => {
                    root.selectedRefreshRateStr = item.value;
                    root.applyChange(root.selectedResolution + "@" + item.value, root.currentScale, root.vrrEnabled, false);
                }
            }

            // Scale dropdown
            SelectRow {
                label: qsTr("Scaling")
                subtext: qsTr("Adjust interface size scaling factor")
                menuItems: scaleItems
                active: {
                    let items = scaleItems;
                    let sc = root.currentScale;
                    let idx = 0;
                    if (sc === 1.25) idx = 1;
                    else if (sc === 1.5) idx = 2;
                    else if (sc === 2.0) idx = 3;
                    return items[idx] ?? null;
                }
                visible: !activeOutputInfo || !activeOutputInfo.off
                onSelected: item => {
                    root.applyChange(null, item.value, root.vrrEnabled, false);
                }
            }

            // VRR Toggle
            ToggleRow {
                text: qsTr("Variable Refresh Rate")
                subtext: qsTr("Reduce screen tearing (FreeSync / G-Sync)")
                checked: root.vrrEnabled
                visible: !activeOutputInfo || (!activeOutputInfo.off && root.vrrSupported)
                onToggled: {
                    root.applyChange(null, root.currentScale, checked, false);
                }
            }

            // Adaptive Refresh Rate Toggle (for laptop battery saving)
            ToggleRow {
                last: true
                text: qsTr("Adaptive Refresh Rate")
                subtext: qsTr("Lower refresh rate automatically when running on battery")
                checked: GlobalConfig.general.battery.adaptiveRefreshRate
                visible: !activeOutputInfo || (selectedOutputName.startsWith("eDP-") && !activeOutputInfo.off)
                onToggled: {
                    GlobalConfig.general.battery.adaptiveRefreshRate = checked;
                    refreshProcess.running = true;
                }
            }
        }
    }
}

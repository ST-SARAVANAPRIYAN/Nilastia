pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Nilastia.Components
import Nilastia.Config
import Nilastia.Plugins
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Plugins")
    maxWidth: Tokens.sizes.nexus.maxContentWidth * 2
    horizontalPadding: Tokens.padding.extraLarge

    property var storePlugins: []
    property string installingPluginId: ""
    property var selectedPlugin: null
    property bool showDetails: false
    property string selectedPluginReadme: ""
    property bool fetchingReadme: false
    property bool initialized: false
    property var storeXhr: null
    property var readmeXhr: null
    readonly property var browsePlugins: {
        // Explicitly reference properties to establish QML bindings for reactivity
        let _unused1 = Plugins.plugins;
        let _unused2 = root.storePlugins;
        return root.getBrowsePlugins();
    }

    function isNewerVersion(remote, local) {
        if (!remote || !local) return false;
        let rParts = remote.split(".").map(Number);
        let lParts = local.split(".").map(Number);
        for (let i = 0; i < Math.max(rParts.length, lParts.length); i++) {
            let r = rParts[i] || 0;
            let l = lParts[i] || 0;
            if (r > l) return true;
            if (r < l) return false;
        }
        return false;
    }

    function findLocalPlugin(plugin) {
        if (!plugin) return null;
        if (plugin.dir !== undefined) return plugin;
        
        let localList = Plugins.plugins;
        for (let i = 0; i < localList.length; i++) {
            let lp = localList[i];
            if (lp && lp.id === plugin.id) {
                return lp;
            }
        }
        for (let i = 0; i < localList.length; i++) {
            let lp = localList[i];
            if (lp && lp.dir && lp.dir.endsWith("/" + plugin.id)) {
                return lp;
            }
        }
        return null;
    }

    function isPluginInstalled(plugin) {
        return root.findLocalPlugin(plugin) !== null;
    }

    function findRemotePlugin(localPlugin) {
        if (!localPlugin) return null;
        
        let storeList = root.storePlugins;
        for (let i = 0; i < storeList.length; i++) {
            let rp = storeList[i];
            if (rp && rp.id === localPlugin.id) {
                return rp;
            }
        }
        if (localPlugin.dir) {
            for (let i = 0; i < storeList.length; i++) {
                let rp = storeList[i];
                if (rp && localPlugin.dir.endsWith("/" + rp.id)) {
                    return rp;
                }
            }
        }
        return null;
    }

    function uninstallPlugin(dirPath) {
        console.log("DEBUG: uninstallPlugin called with dirPath =", dirPath);
        pluginUninstaller.uninstall(dirPath);
    }

    function filterPlugins(pluginList, query) {
        if (!pluginList) return [];
        let list = [];
        for (let i = 0; i < pluginList.length; i++) {
            list.push(pluginList[i]);
        }
        let qStr = (query || "").toString().toLowerCase().trim();
        if (qStr === "") return list;
        return list.filter(p => {
            let name = (p.name || "").toLowerCase();
            let desc = (p.description || "").toLowerCase();
            let author = (p.author || "").toLowerCase();
            let tags = p.tags || [];
            let tagMatches = false;
            for (let j = 0; j < tags.length; j++) {
                if (tags[j].toLowerCase().indexOf(qStr) !== -1) {
                    tagMatches = true;
                    break;
                }
            }
            return name.indexOf(qStr) !== -1 ||
                   desc.indexOf(qStr) !== -1 ||
                   author.indexOf(qStr) !== -1 ||
                   tagMatches;
        });
    }
    function getBrowsePlugins() {
        let list = [];
        for (let i = 0; i < root.storePlugins.length; i++) {
            let p = root.storePlugins[i];
            if (!root.isPluginInstalled(p)) {
                list.push(p);
            }
        }
        return list;
    }
    function fetchStorePlugins() {
        console.log("DEBUG: fetchStorePlugins called");
        if (root.storeXhr) {
            root.storeXhr.abort();
        }
        root.storeXhr = new XMLHttpRequest();
        let xhr = root.storeXhr;
        xhr.open("GET", "https://raw.githubusercontent.com/calestia-desktop/plugins-directory/main/plugins.json");
        xhr.onreadystatechange = function() {
            console.log("DEBUG: xhr readyState =", xhr.readyState, "status =", xhr.status);
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText);
                        if (Array.isArray(data)) {
                            console.log("DEBUG: successfully fetched", data.length, "plugins from store");
                            root.storePlugins = data;
                            root.storeXhr = null;
                            return;
                        }
                    } catch (e) {
                        console.error("Failed to parse store plugins JSON:", e);
                    }
                }
                console.log("DEBUG: using fallback store plugins list");
                // Fallback registry examples if fetch fails or raw repo is not ready yet
                root.storePlugins = [
                    {
                        "id": "org.nilastia.yoink",
                        "name": "Yoink",
                        "author": "saravana",
                        "description": "Intelligent screenshot overlay plugin using Yoink CV daemon.",
                        "repo": "https://github.com/ST-SARAVANAPRIYAN/nilastia-yoink-plugin",
                        "tags": ["utility", "screenshot", "system"],
                        "version": "1.0.0"
                    }
                ];
                console.log("DEBUG: root.storePlugins count =", root.storePlugins.length);
                root.storeXhr = null;
            }
        }
        xhr.send();
    }

    function fetchReadme(plugin) {
        root.selectedPluginReadme = "";
        if (!plugin) return;
        
        let localInfo = root.findLocalPlugin(plugin);
        let isInstalled = localInfo !== null;
        
        if (isInstalled && localInfo && localInfo.dir) {
            root.fetchingReadme = true;
            fallbackTimer.repoUrl = plugin.repo || "";
            fallbackTimer.start();
            readmeReader.path = localInfo.dir + "/README.md";
            readmeReader.reload();
        } else if (plugin.repo) {
            root.fetchReadmeFromRepo(plugin.repo);
        }
    }

    function fetchReadmeFromRepo(repoUrl) {
        if (!repoUrl) return;
        
        let rawUrl = repoUrl.replace("github.com", "raw.githubusercontent.com");
        if (!rawUrl.endsWith("/README.md")) {
            rawUrl = rawUrl.replace(/\.git$/, "");
            rawUrl += "/main/README.md";
        }
        
        root.fetchingReadme = true;
        if (root.readmeXhr) {
            root.readmeXhr.abort();
        }
        root.readmeXhr = new XMLHttpRequest();
        let xhr = root.readmeXhr;
        xhr.open("GET", rawUrl);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.fetchingReadme = false;
                if (xhr.status === 200) {
                    root.selectedPluginReadme = xhr.responseText;
                } else {
                    root.selectedPluginReadme = qsTr("Failed to load documentation from repository.");
                }
                root.readmeXhr = null;
            }
        }
        xhr.send();
    }

    Component.onCompleted: {
        fetchStorePlugins();
        console.log("DEBUG: Plugins.plugins length =", Plugins.plugins.length);
        console.log("DEBUG: storePlugins length =", root.storePlugins.length);
        Qt.callLater(() => { root.initialized = true; });
    }



    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SearchBar {
            id: searchBar
            Layout.fillWidth: true
            placeholderText: qsTr("Search available and installed plugins...")
            Layout.bottomMargin: Tokens.spacing.large
        }

        // Installed
        SectionHeader {
            first: true
            text: qsTr("Installed plugins")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.medium
            visible: Plugins.plugins.length > 0
        }

        PluginGrid {
            plugins: (typeof searchBar !== "undefined" && searchBar) ? root.filterPlugins(Plugins.plugins, searchBar.text) : Plugins.plugins
            visible: Plugins.plugins.length > 0
        }

        // Store
        SectionHeader {
            text: qsTr("Browse plugins")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.medium
            visible: root.browsePlugins.length > 0
        }

        PluginGrid {
            plugins: (typeof searchBar !== "undefined" && searchBar) ? root.filterPlugins(root.browsePlugins, searchBar.text) : root.browsePlugins
            visible: root.browsePlugins.length > 0
        }


        Rectangle {
            id: detailOverlay
            z: 999

            readonly property var localInfo: root.findLocalPlugin(root.selectedPlugin)
            readonly property var remoteInfo: {
                if (!root.selectedPlugin) return null;
                if (root.selectedPlugin.dir === undefined) return root.selectedPlugin;
                return root.findRemotePlugin(root.selectedPlugin);
            }
            
            // Slide animation from the right
            x: (root.showDetails && root.selectedPlugin !== null && parent) ? 0 : (parent ? parent.width : 0)
            y: 0
            width: parent ? parent.width : 0
            height: parent ? parent.height : 0
            visible: x < (parent ? parent.width : 1)
            
            color: Colours.palette.m3surface
            
            Behavior on x {
                enabled: root.initialized
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Component.onCompleted: {
                if (root.parent) {
                    detailOverlay.parent = root.parent;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.large

                    IconButton {
                        icon: "arrow_back"
                        font: Tokens.font.icon.medium
                        type: IconButton.Tonal
                        isRound: true
                        onClicked: root.showDetails = false
                    }

                    StyledText {
                        text: root.selectedPlugin ? root.selectedPlugin.name : ""
                        font: Tokens.font.title.large
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                // Hero/Banner Area
                StyledClippingRect {
                    Layout.fillWidth: true
                    implicitHeight: 200
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                    radius: Tokens.rounding.large

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "image"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                        visible: !heroImg.visible
                    }

                    Image {
                        id: heroImg
                        anchors.fill: parent
                        source: (detailOverlay.remoteInfo && detailOverlay.remoteInfo.image) ? detailOverlay.remoteInfo.image : ""
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                ScrollView {
                    id: settingsScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: settingsScrollView.width - Tokens.padding.medium * 2
                        Layout.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.large

                        // Version & Author Info Card
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall
                            StyledText {
                                text: {
                                    if (!root.selectedPlugin) return "";
                                    let vStr = "";
                                    if (detailOverlay.localInfo) {
                                        vStr += qsTr("Installed: v%1").arg(detailOverlay.localInfo.version || "1.0.0");
                                        if (detailOverlay.remoteInfo && detailOverlay.remoteInfo.version !== detailOverlay.localInfo.version) {
                                            vStr += qsTr(" (Latest: v%2)").arg(detailOverlay.remoteInfo.version);
                                        }
                                    } else if (detailOverlay.remoteInfo) {
                                        vStr += qsTr("Version %1").arg(detailOverlay.remoteInfo.version || "1.0.0");
                                    } else {
                                        vStr += qsTr("Version %1").arg(root.selectedPlugin.version || "1.0.0");
                                    }
                                    return vStr;
                                }
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3outline
                            }
                            StyledText {
                                text: {
                                    let author = (detailOverlay.remoteInfo && detailOverlay.remoteInfo.author) || (detailOverlay.localInfo && detailOverlay.localInfo.author) || (root.selectedPlugin && root.selectedPlugin.author) || "Unknown";
                                    return qsTr("Author: %1").arg(author);
                                }
                                font: Tokens.font.body.small
                                color: Colours.palette.m3outline
                            }
                        }

                        // Tags Flow
                        Flow {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall
                            visible: detailOverlay.remoteInfo && detailOverlay.remoteInfo.tags && detailOverlay.remoteInfo.tags.length > 0
                            Repeater {
                                model: detailOverlay.remoteInfo ? detailOverlay.remoteInfo.tags : []
                                StyledRect {
                                    required property string modelData
                                    color: Colours.palette.m3tertiaryContainer
                                    radius: Tokens.rounding.full
                                    implicitWidth: tagT.implicitWidth + Tokens.padding.medium * 2
                                    implicitHeight: tagT.implicitHeight + Tokens.padding.extraSmall * 2
                                    StyledText {
                                        id: tagT
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: Colours.palette.m3onTertiaryContainer
                                        font: Tokens.font.label.small
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Colours.palette.m3outlineVariant
                        }

                        // Settings UI (if installed and has settings QML)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall
                            visible: detailOverlay.localInfo !== null && detailOverlay.localInfo.settingsUiSource !== ""

                            StyledText {
                                text: qsTr("Configuration Settings")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            Loader {
                                id: settingsLoader
                                Layout.fillWidth: true
                                source: (root.selectedPlugin && detailOverlay.localInfo && detailOverlay.localInfo.settingsUiSource) ? detailOverlay.localInfo.settingsUiSource : ""
                                visible: source.toString() !== ""

                                onLoaded: {
                                    if (item) {
                                        item.width = Qt.binding(() => settingsLoader.width);
                                        if (item.hasOwnProperty("plugin")) {
                                            item.plugin = detailOverlay.localInfo;
                                        }
                                        if (item.hasOwnProperty("settings")) {
                                            item.settings = detailOverlay.localInfo.settings;
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Colours.palette.m3outlineVariant
                                Layout.topMargin: Tokens.spacing.medium
                                Layout.bottomMargin: Tokens.spacing.medium
                                visible: settingsLoader.visible
                            }
                        }

                        // Documentation / Description Section
                        StyledText {
                            text: qsTr("Documentation")
                            font: Tokens.font.title.small
                            color: Colours.palette.m3onSurface
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            indeterminate: true
                            visible: root.fetchingReadme
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (root.selectedPluginReadme !== "") {
                                    return root.selectedPluginReadme;
                                }
                                let desc = (detailOverlay.remoteInfo && detailOverlay.remoteInfo.description) || (root.selectedPlugin && root.selectedPlugin.description) || qsTr("No description provided.");
                                return desc;
                            }
                            textFormat: root.selectedPluginReadme !== "" ? Text.MarkdownText : Text.PlainText
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            wrapMode: Text.Wrap
                        }

                        // Repository Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.extraSmall
                            visible: detailOverlay.remoteInfo && detailOverlay.remoteInfo.repo !== undefined

                            StyledText {
                                text: qsTr("Repository")
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small
                                MaterialIcon {
                                    text: "link"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                }
                                StyledText {
                                    text: detailOverlay.remoteInfo ? detailOverlay.remoteInfo.repo : ""
                                    font: Tokens.font.body.small
                                    color: Colours.palette.m3primary
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["xdg-open", detailOverlay.remoteInfo.repo])
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer Row
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 72
                    color: Colours.tPalette.m3surfaceContainerLow
                    radius: Tokens.rounding.large

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        TextButton {
                            text: qsTr("Go Back")
                            type: TextButton.Tonal
                            onClicked: root.showDetails = false
                        }

                        Item { Layout.fillWidth: true }

                        TextButton {
                            readonly property var localInfo: detailOverlay.localInfo
                            readonly property var remoteInfo: detailOverlay.remoteInfo
                            readonly property bool isInstalled: localInfo !== null && localInfo !== undefined
                            readonly property bool updateAvailable: remoteInfo && localInfo && root.isNewerVersion(remoteInfo.version, localInfo.version)

                            isRound: true
                            shapeMorph: true
                            type: updateAvailable ? TextButton.Filled : (isInstalled ? TextButton.Tonal : TextButton.Filled)
                            
                            text: {
                                let installId = remoteInfo ? remoteInfo.id : (localInfo ? localInfo.id : "");
                                if (root.installingPluginId === installId && root.installingPluginId !== "") return qsTr("Installing...");
                                if (updateAvailable) return qsTr("Update (v%1)").arg(remoteInfo.version);
                                if (isInstalled) return qsTr("Uninstall");
                                return qsTr("Install");
                            }

                            onClicked: {
                                if (isInstalled && !updateAvailable) {
                                    if (localInfo && localInfo.dir) {
                                        root.uninstallPlugin(localInfo.dir);
                                    }
                                    root.showDetails = false;
                                } else if (remoteInfo) {
                                    root.installingPluginId = remoteInfo.id;
                                    pluginInstaller.install(remoteInfo.repo, remoteInfo.id, function() {
                                        root.installingPluginId = "";
                                        root.showDetails = false;
                                        if (typeof Toaster !== "undefined" && Toaster) {
                                            Toaster.toast(qsTr("Plugin action complete"), qsTr("%1 successfully updated/installed.").arg(remoteInfo.name), "extension");
                                        }
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component PluginGrid: LazyGridView {
        id: grid

        property alias plugins: model.values

        Layout.fillWidth: true
        implicitHeight: animatedContentHeight

        cellWidth: 300 // Minimum cell width, elements stretch to fill complete view width
        rowSpacing: Tokens.spacing.large
        columnSpacing: Tokens.spacing.large
        estimatedRowHeight: 426 // Height per plugin card with default tokens and 2 line description, at nexus initial size

        asynchronous: true
        cacheBuffer: 400
        readyDelay: 1

        // Expressive default spatial spring params
        stiffness: 380
        damping: 0.8

        enterDuration: Tokens.anim.durations.expressiveDefaultEffects
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects
        easing: Tokens.anim.expressiveDefaultEffects

        useCustomViewport: true
        viewport: {
            tWatcher.transform; // mapToItem is not reactive so use this to trigger updates
            return Qt.rect(0, root.flickable.contentY - mapToItem(root.flickable.contentItem, 0, 0).y, width, root.flickable.height);
        }

        model: ScriptModel {
            id: model
        }

        delegate: PluginCard {}

        // Frame animation to trigger move/resize springs
        FrameAnimation {
            running: grid.animating
            onTriggered: grid.step(frameTime)
        }

        TransformWatcher {
            id: tWatcher

            a: root.flickable.contentItem
            b: grid
        }
    }

    component PluginCard: StyledRect {
        id: plugin

        required property int index
        required property var modelData

        // Check if the plugin is installed locally
        readonly property var localInfo: root.findLocalPlugin(plugin.modelData)
        readonly property bool isInstalled: localInfo !== null
        readonly property bool isInstalling: root.installingPluginId !== "" && (root.installingPluginId === plugin.modelData.id || (localInfo && (root.installingPluginId === localInfo.id || (localInfo.dir && localInfo.dir.endsWith("/" + root.installingPluginId)))))
        readonly property bool updateAvailable: {
            let remoteInfo = root.findRemotePlugin(plugin.modelData) || (plugin.modelData.dir === undefined ? plugin.modelData : null);
            return isInstalled && localInfo && remoteInfo && root.isNewerVersion(remoteInfo.version, localInfo.version);
        }

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.extraLarge

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.selectedPlugin = plugin.modelData;
                root.showDetails = true;
                root.fetchReadme(plugin.modelData);
            }
        }

        implicitHeight: heroWrapper.implicitHeight + detailLayout.implicitHeight + detailLayout.anchors.topMargin + detailLayout.anchors.margins

        StyledClippingRect {
            id: heroWrapper

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: width * 9 / 16

            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
            radius: Tokens.rounding.extraLarge

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.extraLarge
                opacity: 1 - heroImage.opacity
            }

            Image {
                id: heroImage

                anchors.fill: parent
                source: plugin.modelData.image ?? ""
                retainWhileLoading: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            // Update available badge
            StyledRect {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium
                visible: plugin.updateAvailable
                color: Colours.palette.m3error
                radius: Tokens.rounding.full
                implicitWidth: updateText.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: updateText.implicitHeight + Tokens.padding.extraSmall * 2

                StyledText {
                    id: updateText
                    anchors.centerIn: parent
                    text: qsTr("Update Available")
                    color: Colours.palette.m3onError
                    font: Tokens.font.label.small
                }
            }
        }

        ColumnLayout {
            id: detailLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: heroWrapper.bottom
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.large
            anchors.topMargin: Tokens.spacing.medium

            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: plugin.modelData.name
                font: Tokens.font.title.builders.medium.width(110).build()
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            StyledText {
                Layout.topMargin: -parent.spacing / 2
                Layout.fillWidth: true
                text: qsTr("By %1").arg(plugin.modelData.author)
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: plugin.modelData.description || ""
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Flow {
                Layout.topMargin: Tokens.spacing.small
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall
                visible: plugin.modelData.tags !== undefined && plugin.modelData.tags.length > 0

                Repeater {
                    model: plugin.modelData.tags || []

                    StyledRect {
                        required property string modelData

                        color: Colours.palette.m3tertiaryContainer
                        radius: Tokens.rounding.full

                        implicitWidth: tagText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: tagText.implicitHeight + Tokens.padding.extraSmall * 2

                        StyledText {
                            id: tagText

                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Colours.palette.m3onTertiaryContainer
                            font: Tokens.font.label.small
                        }
                    }
                }
            }

            ButtonRow {
                Layout.topMargin: Tokens.spacing.medium
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                TextButton {
                    isRound: true
                    shapeMorph: true
                    fillWidth: true
                    text: plugin.isInstalling ? qsTr("Installing...") : (plugin.updateAvailable ? qsTr("Update Available") : (plugin.isInstalled ? qsTr("Manage") : qsTr("Details")))
                    font: Tokens.font.body.builders.small.width(110).build()
                    onClicked: {
                        root.selectedPlugin = plugin.modelData;
                        root.showDetails = true;
                        root.fetchReadme(plugin.modelData);
                    }
                }

                IconButton {
                    isRound: true
                    shapeMorph: true
                    icon: "home"
                    type: IconButton.Tonal
                    implicitWidth: implicitHeight + Tokens.padding.small * 2
                    visible: plugin.modelData.repo !== undefined
                    onClicked: {
                        Quickshell.execDetached(["xdg-open", plugin.modelData.repo]);
                    }
                }
            }
        }
    }

    resources: [
        FileView {
            id: readmeReader
            printErrors: false
            onLoaded: {
                fallbackTimer.stop();
                root.fetchingReadme = false;
                root.selectedPluginReadme = text();
                if (root.selectedPluginReadme.trim() === "") {
                    if (fallbackTimer.repoUrl) {
                        root.fetchReadmeFromRepo(fallbackTimer.repoUrl);
                    }
                }
            }
        },
        Timer {
            id: fallbackTimer
            property string repoUrl: ""
            interval: 100
            repeat: false
            onTriggered: {
                if (repoUrl !== "") {
                    root.fetchReadmeFromRepo(repoUrl);
                }
            }
        },
        Process {
            id: pluginInstaller
            running: false
            command: ["sh", "-c", cmd]
            property string cmd: ""
            property var callback: null

            stdout: StdioCollector {
                onStreamFinished: console.log("PluginInstaller stdout:", text)
            }
            stderr: StdioCollector {
                onStreamFinished: console.error("PluginInstaller stderr:", text)
            }

            onRunningChanged: {
                if (!running) {
                    let oldIds = [];
                    for (let i = 0; i < Plugins.plugins.length; i++) {
                        oldIds.push(Plugins.plugins[i].id);
                    }
                    Plugins.reload();
                    if (callback) {
                        callback();
                    }
                    for (let j = 0; j < Plugins.plugins.length; j++) {
                        let p = Plugins.plugins[j];
                        if (oldIds.indexOf(p.id) === -1) {
                            console.log("Automatically enabling newly installed plugin:", p.id);
                            Plugins.setPluginEnabled(p.id, true);
                        }
                    }
                }
            }

            function install(repoUrl, pluginId, onDone) {
                if (running) return;
                callback = onDone;
                cmd = "mkdir -p \"$HOME/.local/share/nilastia/plugins\" && rm -rf \"$HOME/.local/share/nilastia/plugins/" + pluginId + "\" && git clone --depth 1 \"" + repoUrl + "\" \"$HOME/.local/share/nilastia/plugins/" + pluginId + "\"";
                running = true;
            }
        },
        Process {
            id: pluginUninstaller
            running: false
            command: ["sh", "-c", cmd]
            property string cmd: ""

            stdout: StdioCollector {
                onStreamFinished: console.log("PluginUninstaller stdout:", text)
            }
            stderr: StdioCollector {
                onStreamFinished: console.error("PluginUninstaller stderr:", text)
            }

            onRunningChanged: {
                if (!running) {
                    Plugins.reload();
                    root.showDetails = false;
                    if (typeof Toaster !== "undefined" && Toaster) {
                        Toaster.toast(qsTr("Plugin Uninstalled"), qsTr("Plugin removed successfully."), "delete");
                    }
                }
            }
            function uninstall(dirPath) {
                if (running) return;
                cmd = "rm -rf \"" + dirPath + "\"";
                console.log("DEBUG: Running uninstall command:", cmd);
                running = true;
            }
        }
    ]

}

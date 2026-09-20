import QtQuick
import QtQuick.Controls
import Quickshell
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property ScreenState screenState
    required property Panels panels
    required property Bar.BarWrapper bar
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive
    property bool launcherShortcutActive
    property bool sidebarShortcutActive

    property bool dashboardOpenedByClick: false
    property bool utilitiesOpenedByClick: false
    property bool launcherOpenedByClick: false
    property bool sidebarOpenedByClick: false
    property bool osdOpenedByClick: false

    Timer {
        id: osdHoverTimer
        interval: 150
        repeat: false
        onTriggered: {
            screenState.osd = true;
            root.panels.osd.hovered = true;
        }
    }

    Timer {
        id: dashboardHoverTimer
        interval: Config.dashboard.hoverDelay
        repeat: false
        onTriggered: {
            screenState.dashboard = true;
        }
    }

    function updateOsd(showOsd) {
        if (!osdShortcutActive) {
            if (showOsd) {
                if (!osdHoverTimer.running && !screenState.osd) {
                    osdHoverTimer.start();
                }
            } else {
                osdHoverTimer.stop();
                screenState.osd = false;
                root.panels.osd.hovered = false;
            }
        } else if (showOsd) {
            osdShortcutActive = false;
            root.panels.osd.hovered = true;
        }
    }

    function isModeHover(cfg) {
        if (!cfg)
            return false;
        if (cfg.revealMode !== undefined && cfg.revealMode !== "")
            return cfg.revealMode === "hover";
        return cfg.showOnHover ?? false;
    }

    function isModeClick(cfg) {
        if (!cfg)
            return false;
        if (cfg.revealMode !== undefined && cfg.revealMode !== "")
            return cfg.revealMode === "click";
        return false;
    }

    function withinPanelHeight(panel, x, y) {
        const panelY = root.borderThickness + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel, x, y) {
        const panelX = bar.implicitWidth + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel, x, y) {
        return x < bar.implicitWidth + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    function inRightPanel(panel, x, y) {
        return x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panel.x) && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel, x, y, isOpen = false) {
        const panelHeight = (isOpen || (panel.offsetScale ?? 1) === 0) ? panel.height : panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y < Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel, x, y, isCorner = false, isOpen = false) {
        const panelHeight = (isOpen || (panel.offsetScale ?? 1) === 0) ? panel.height : panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y > height - Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y);
    }

    function onWheel(event) {
        if (fullscreen)
            return;
        if (event.x < bar.implicitWidth) {
            bar.handleWheel(event.y, event.angleDelta);
        }
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onClicked: event => {
        if (fullscreen)
            return;

        // If clicking on the taskbar, check and open popouts in click mode
        if (event.x < bar.implicitWidth) {
            if (!Config.bar.hoverOpenPopouts) {
                const prevName = popouts.hasCurrent ? popouts.currentName : "";
                const prevActive = popouts.hasCurrent;
                bar.checkPopout(event.y);
                // If they clicked the same icon again, toggle it closed
                if (prevActive && popouts.hasCurrent && popouts.currentName === prevName) {
                    popouts.hasCurrent = false;
                    bar.closeTray();
                }
                event.accepted = true;
                return;
            }
        }

        // Handle edge click reveals when panel is closed:
        // Dashboard (top edge click)
        if (isModeClick(Config.dashboard) && Config.dashboard.enabled) {
            const inTopEdge = inTopPanel(panels.dashboard, event.x, event.y, screenState.dashboard);
            if (inTopEdge) {
                if (!screenState.dashboard) {
                    dashboardOpenedByClick = true;
                    dashboardShortcutActive = false;
                    screenState.dashboard = true;
                    dashboardOpenedByClick = false;
                } else if (event.y <= Config.border.thickness) {
                    screenState.dashboard = false;
                }
                event.accepted = true;
                return;
            }
        }

        // Launcher (bottom edge click)
        if (isModeClick(Config.launcher) && Config.launcher.enabled) {
            const inBottomEdge = inBottomPanel(panels.launcher, event.x, event.y, false, screenState.launcher);
            if (inBottomEdge) {
                if (!screenState.launcher) {
                    launcherOpenedByClick = true;
                    launcherShortcutActive = false;
                    screenState.launcher = true;
                    launcherOpenedByClick = false;
                } else if (event.y >= height - Config.border.thickness) {
                    screenState.launcher = false;
                }
                event.accepted = true;
                return;
            }
        }

        // Utilities / Quick Toggles (bottom-right corner click)
        if (Config.utilities.enabled) {
            const inUtilities = inBottomPanel(panels.utilities, event.x, event.y, true, screenState.utilities);
            if (isModeClick(Config.utilities)) {
                if (inUtilities) {
                    if (!screenState.utilities) {
                        utilitiesOpenedByClick = true;
                        utilitiesShortcutActive = false;
                        screenState.utilities = true;
                        utilitiesOpenedByClick = false;
                    } else {
                        utilitiesShortcutActive = false;
                        screenState.utilities = false;
                    }
                    event.accepted = true;
                    return;
                }
            }
        }

        // Sidebar / Notification Center (right edge, top portion)
        const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);
        const inSidebarZone = event.x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x) && event.y <= sidebarTriggerY;
        if (isModeClick(Config.sidebar) && Config.sidebar.enabled) {
            if (inSidebarZone) {
                if (!screenState.sidebar) {
                    sidebarOpenedByClick = true;
                    sidebarShortcutActive = false;
                    screenState.sidebar = true;
                    sidebarOpenedByClick = false;
                } else if (event.x >= width - Config.border.thickness) {
                    screenState.sidebar = false;
                }
                event.accepted = true;
                return;
            }
        }

        // OSD / Volume & Brightness (right edge, bottom portion)
        const inOsdZone = event.x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.osdWrapper.x) && event.y > sidebarTriggerY;
        if (isModeClick(Config.osd) && Config.osd.enabled) {
            if (inOsdZone) {
                if (!screenState.osd) {
                    osdOpenedByClick = true;
                    osdShortcutActive = false;
                    screenState.osd = true;
                    root.panels.osd.hovered = true;
                    osdOpenedByClick = false;
                } else {
                    osdShortcutActive = false;
                    screenState.osd = false;
                    root.panels.osd.hovered = false;
                }
                event.accepted = true;
                return;
            }
        }

        // Taskbar (left edge click when hidden / not persistent)
        if (!Config.bar.persistent && isModeClick(Config.bar)) {
            if (event.x < bar.clampedWidth) {
                bar.isHovered = !bar.isHovered;
                event.accepted = true;
                return;
            }
        }

        if (screenState.launcher) {
            if (!inBottomPanel(panels.launcher, event.x, event.y, false, true)) {
                launcherShortcutActive = false;
                screenState.launcher = false;
                event.accepted = true;
            }
        }
        if (screenState.clipboard) {
            if (!inBottomPanel(panels.clipboard, event.x, event.y, false, true)) {
                screenState.clipboard = false;
                event.accepted = true;
            }
        }
        if (screenState.session) {
            if (!inRightPanel(panels.sessionWrapper, event.x, event.y)) {
                screenState.session = false;
                event.accepted = true;
            }
        }
        if (screenState.dashboard) {
            if (!inTopPanel(panels.dashboard, event.x, event.y, true)) {
                dashboardShortcutActive = false;
                screenState.dashboard = false;
                event.accepted = true;
            }
        }
        if (screenState.sidebar) {
            if (!inRightPanel(panels.sidebar, event.x, event.y)) {
                sidebarShortcutActive = false;
                screenState.sidebar = false;
                event.accepted = true;
            }
        }
        if (screenState.utilities) {
            if (!inBottomPanel(panels.utilities, event.x, event.y, true, true)) {
                utilitiesShortcutActive = false;
                screenState.utilities = false;
                event.accepted = true;
            }
        }
        if (screenState.osd) {
            if (!inRightPanel(panels.osdWrapper, event.x, event.y)) {
                osdShortcutActive = false;
                screenState.osd = false;
                event.accepted = true;
            }
        }

        // Close popouts when clicking outside their area
        if (popouts.hasCurrent) {
            if (!inLeftPanel(panels.popoutsWrapper, event.x, event.y)) {
                popouts.hasCurrent = false;
                bar.closeTray();
                event.accepted = true;
            }
        }
    }
    onContainsMouseChanged: {
        if (!containsMouse) {
            dashboardHoverTimer.stop();
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                screenState.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive)
                screenState.dashboard = false;

            if (!utilitiesShortcutActive)
                screenState.utilities = false;

            if (!launcherShortcutActive && (isModeClick(Config.launcher) || isModeHover(Config.launcher)))
                screenState.launcher = false;

            if (!sidebarShortcutActive && (isModeClick(Config.sidebar) || isModeHover(Config.sidebar)))
                screenState.sidebar = false;

            if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) {
                popouts.hasCurrent = false;
                bar.closeTray();
            }

            if (isModeHover(Config.bar) || isModeClick(Config.bar))
                bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            root.panels.osd.hovered = inRightPanel(panels.osdWrapper, x, y);
            return;
        }

        // Show/hide bar in non-exclusive mode
        if (isModeHover(Config.bar)) {
            if (x < bar.clampedWidth) {
                bar.isHovered = true;
            } else {
                bar.isHovered = false;
            }
        } else if (isModeClick(Config.bar) && !Config.bar.persistent) {
            if (bar.isHovered && x >= bar.clampedWidth && !inLeftPanel(panels.popoutsWrapper, x, y)) {
                bar.isHovered = false;
            }
        }

        // Show/hide bar on drag
        if (pressed && dragStart.x < bar.clampedWidth) {
            if (dragX > Config.bar.dragThreshold)
                screenState.bar = true;
            else if (dragX < -Config.bar.dragThreshold)
                screenState.bar = false;
        }

        const sidebarTriggerY = Math.max(Config.sidebar.minHoverThreshold, panels.notifications.y + panels.notifications.height + borderThickness);

        if (panels.sidebar.offsetScale === 1) {
            // Show osd on hover (triggered anywhere on right edge below the sidebar trigger, and kept open when mouse is on the OSD panel)
            const inOsdTriggerZone = x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.osdWrapper.x) && y > sidebarTriggerY;
            const showOsd = (isModeHover(Config.osd) && inOsdTriggerZone) || (screenState.osd && inRightPanel(panels.osdWrapper, x, y));

            updateOsd(showOsd);

            const showSidebar = pressed && dragStart.x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x);

            // Show sidebar on hover (top-right corner, bounded by notification panel height)
            if (isModeHover(Config.sidebar)) {
                const showSidebarHover = x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x) && y <= sidebarTriggerY;
                if (showSidebarHover && !screenState.sidebar)
                    screenState.sidebar = true;
            }

            // Show/hide session on drag
            if (pressed && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    screenState.session = true;
                else if (dragX > Config.session.dragThreshold)
                    screenState.session = false;

                // Show sidebar on drag if in session area and session is nearly fully visible
                if (showSidebar && panels.session.offsetScale <= 0 && dragX < -Config.sidebar.dragThreshold)
                    screenState.sidebar = true;
            } else if (showSidebar && dragX < -Config.sidebar.dragThreshold) {
                // Show sidebar on drag if not in session area
                screenState.sidebar = true;
            }
        } else {
            const outOfSidebar = x < width - panels.sidebar.width * (1 - panels.sidebar.offsetScale);
            // Show osd on hover
            const inOsdTriggerZone = x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.osdWrapper.x) && y > sidebarTriggerY;
            const showOsd = outOfSidebar && ((isModeHover(Config.osd) && inOsdTriggerZone) || (screenState.osd && inRightPanel(panels.osdWrapper, x, y)));

            updateOsd(showOsd);

            // Show/hide session on drag
            if (pressed && outOfSidebar && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    screenState.session = true;
                else if (dragX > Config.session.dragThreshold)
                    screenState.session = false;
            }

            // Show/hide sidebar on hover or click-revealed hover-to-close
            if (!pressed) {
                const inSidebarArea = inRightPanel(panels.sidebar, x, y) || inRightPanel(panels.sessionWrapper, x, y);
                if (isModeHover(Config.sidebar)) {
                    const showSidebarHover = x > Math.min(width - Config.border.minThickness, bar.implicitWidth + panels.sidebar.x) && y <= sidebarTriggerY;
                    if (showSidebarHover && !screenState.sidebar) {
                        screenState.sidebar = true;
                    } else if (!sidebarShortcutActive && !inSidebarArea) {
                        screenState.sidebar = false;
                    } else if (inSidebarArea && sidebarShortcutActive) {
                        sidebarShortcutActive = false;
                    }
                } else if (isModeClick(Config.sidebar)) {
                    if (screenState.sidebar && !sidebarShortcutActive && !inSidebarArea) {
                        screenState.sidebar = false;
                    }
                }
            }

            // Hide sidebar on drag
            if (pressed && inRightPanel(panels.sidebar, dragStart.x, 0) && dragX > Config.sidebar.dragThreshold)
                screenState.sidebar = false;
        }

        // Show launcher on hover, or close like hover in click mode when moving away
        const inLauncherArea = inBottomPanel(panels.launcher, x, y, false, screenState.launcher);
        if (isModeHover(Config.launcher)) {
            if (!launcherShortcutActive) {
                if (!screenState.launcher && inLauncherArea) {
                    screenState.launcher = true;
                } else if (screenState.launcher && !inLauncherArea) {
                    screenState.launcher = false;
                }
            } else if (inLauncherArea) {
                launcherShortcutActive = false;
            }
        } else if (isModeClick(Config.launcher)) {
            if (screenState.launcher && !launcherShortcutActive) {
                if (!inLauncherArea) {
                    screenState.launcher = false;
                }
            }
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                screenState.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                screenState.launcher = false;
        }

        // Show dashboard on hover (requires 1.5s hover to reveal), or close like hover in click mode
        const inCloseCorner = x > width - 120;
        const inDashboardArea = inTopPanel(panels.dashboard, x, y, screenState.dashboard);

        if (!dashboardShortcutActive) {
            if (screenState.dashboard) {
                // If dashboard is currently open, close it when mouse leaves dashboard area
                if (!inDashboardArea) {
                    dashboardHoverTimer.stop();
                    screenState.dashboard = false;
                }
            } else {
                // If dashboard is closed, start 1.5s timer when mouse stays in top trigger area
                if (isModeHover(Config.dashboard) && inDashboardArea && !inCloseCorner) {
                    if (!dashboardHoverTimer.running) {
                        dashboardHoverTimer.start();
                    }
                } else {
                    dashboardHoverTimer.stop();
                }
            }
        } else if (inDashboardArea) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control if hover enabled
            if (isModeHover(Config.dashboard)) {
                dashboardHoverTimer.stop();
                dashboardShortcutActive = false;
            }
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inTopPanel(panels.dashboard, dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                screenState.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                screenState.dashboard = false;
        }

        // Show utilities on hover, or close like hover in click mode
        const showUtilities = inBottomPanel(panels.utilities, x, y, true, screenState.utilities);

        // Update visibility based on hover or click mode
        if (isModeHover(Config.utilities)) {
            if (!utilitiesShortcutActive) {
                screenState.utilities = showUtilities;
            } else if (showUtilities) {
                // If hovering over utilities area while in shortcut mode, transition to hover control
                utilitiesShortcutActive = false;
            }
        } else if (isModeClick(Config.utilities)) {
            if (screenState.utilities && !utilitiesShortcutActive) {
                if (!showUtilities) {
                    screenState.utilities = false;
                }
            }
        }

        // Show popouts on hover
        if (x < bar.implicitWidth) {
            if (Config.bar.hoverOpenPopouts) {
                bar.checkPopout(y);
            }
        } else if ((!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inLeftPanel(panels.popoutsWrapper, x, y)) {
            popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            if (root.screenState.launcher) {
                if (root.launcherOpenedByClick) {
                    root.launcherShortcutActive = false;
                } else if (root.isModeClick(Config.launcher)) {
                    root.launcherShortcutActive = true;
                } else {
                    const inLauncherArea = root.inBottomPanel(root.panels.launcher, root.mouseX, root.mouseY, false, true);
                    if (!inLauncherArea) {
                        root.launcherShortcutActive = true;
                    }
                }
            } else {
                root.launcherShortcutActive = false;
                // If launcher is hidden, clear shortcut flags for dashboard and OSD
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY, false);
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.screenState.dashboard = false;
                }
                if (!inOsdArea) {
                    root.screenState.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.screenState.dashboard) {
                if (root.dashboardOpenedByClick) {
                    root.dashboardShortcutActive = false;
                } else if (root.isModeClick(Config.dashboard)) {
                    root.dashboardShortcutActive = true;
                } else {
                    const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY, false);
                    if (!inDashboardArea) {
                        root.dashboardShortcutActive = true;
                    }
                }
            } else {
                // Dashboard hidden, clear shortcut flag and stop hover timer
                dashboardHoverTimer.stop();
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.screenState.osd) {
                if (root.osdOpenedByClick) {
                    root.osdShortcutActive = false;
                } else if (root.isModeClick(Config.osd) || !root.isModeHover(Config.osd)) {
                    root.osdShortcutActive = true;
                } else {
                    const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);
                    if (!inOsdArea) {
                        root.osdShortcutActive = true;
                    }
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.screenState.utilities) {
                if (root.utilitiesOpenedByClick) {
                    root.utilitiesShortcutActive = false;
                } else if (root.isModeClick(Config.utilities)) {
                    root.utilitiesShortcutActive = true;
                } else {
                    const inUtilitiesArea = root.inBottomPanel(root.panels.utilities, root.mouseX, root.mouseY, true, true);
                    if (!inUtilitiesArea) {
                        root.utilitiesShortcutActive = true;
                    }
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        function onSidebarChanged() {
            if (root.screenState.sidebar) {
                if (root.sidebarOpenedByClick) {
                    root.sidebarShortcutActive = false;
                } else if (root.isModeClick(Config.sidebar)) {
                    root.sidebarShortcutActive = true;
                } else {
                    const inSidebarArea = root.inRightPanel(root.panels.sidebar, root.mouseX, root.mouseY) || root.inRightPanel(root.panels.sessionWrapper, root.mouseX, root.mouseY);
                    if (!inSidebarArea) {
                        root.sidebarShortcutActive = true;
                    }
                }
            } else {
                root.sidebarShortcutActive = false;
            }
        }

        target: root.screenState
    }
}

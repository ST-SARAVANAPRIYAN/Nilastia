pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Nilastia.Blobs
import Nilastia.Config
import Nilastia.Services
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property var monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject?.specialWorkspace?.name?.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels?.values?.some(t => t.lastIpcObject?.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject?.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces?.values?.find(ws => ws.name === specialName);
            return specialWs?.toplevels?.values?.some(t => t.lastIpcObject?.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 1.5 + 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property bool focusGrabActive: {
        const s = root.screenState;
        const conf = root.contentItem.Config;
        if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled) || s.clipboard)
            return true;
        if (!conf.dashboard.showOnHover && s.dashboard && conf.dashboard.enabled)
            return true;
        if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
            return true;
        return false;
    }

    readonly property int dragMaskPadding: {
        if (root.focusGrabActive || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace?.lastIpcObject.windows > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.max(...thresholds);
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session || screenState.clipboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: (isTransitioning || screenState.launcher || screenState.session || screenState.dashboard || screenState.clipboard) ? null : (hasFullscreen ? emptyRegion : regions)

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + bar.implicitWidth
        y: panels.notifications.y + root.borderThickness
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.width - width
            y: panels.osdWrapper.y + root.borderThickness
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness
            height: panels.osd.height
        }
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }



    StyledRect {
        anchors.fill: parent
        opacity: (root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    readonly property bool isTransitioning: {
        if (typeof panels === "undefined" || !panels) return false;
        
        const launcherScale = panels.launcher ? panels.launcher.offsetScale : 1;
        const clipboardScale = panels.clipboard ? panels.clipboard.offsetScale : 1;
        const dashboardScale = panels.dashboard ? panels.dashboard.offsetScale : 1;
        const sidebarScale = panels.sidebar ? panels.sidebar.offsetScale : 1;
        const sessionScale = panels.session ? panels.session.offsetScale : 1;
        const utilitiesScale = panels.utilities ? panels.utilities.offsetScale : 1;
        const popoutsScale = panels.popoutsWrapper ? panels.popoutsWrapper.offsetScale : 1;
        const osdScale = panels.osd ? panels.osd.offsetScale : 1;
        
        return (launcherScale > 0 && launcherScale < 1) ||
               (clipboardScale > 0 && clipboardScale < 1) ||
               (dashboardScale > 0 && dashboardScale < 1) ||
               (sidebarScale > 0 && sidebarScale < 1) ||
               (sessionScale > 0 && sessionScale < 1) ||
               (utilitiesScale > 0 && utilitiesScale < 1) ||
               (popoutsScale > 0 && popoutsScale < 1) ||
               (osdScale > 0 && osdScale < 1);
    }

    onIsTransitioningChanged: console.log("DEBUG: isTransitioning changed to:", isTransitioning, "scales:",
        panels.launcher ? panels.launcher.offsetScale : -1,
        panels.clipboard ? panels.clipboard.offsetScale : -1,
        panels.dashboard ? panels.dashboard.offsetScale : -1,
        panels.sidebar ? panels.sidebar.offsetScale : -1,
        panels.session ? panels.session.offsetScale : -1,
        panels.utilities ? panels.utilities.offsetScale : -1,
        panels.popoutsWrapper ? panels.popoutsWrapper.offsetScale : -1,
        panels.osd ? panels.osd.offsetScale : -1
    )

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: false

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: bar.implicitWidth - anchors.margins - root.sdfBorderOffset
            borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderTop: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg
            objectName: "dashBg"

            panel: panels.dashboard
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg
            objectName: "launcherBg"

            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: clipboardBg
            objectName: "clipboardBg"

            panel: panels.clipboard
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg
            objectName: "sessionBg"

            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + panels.session.x + bar.implicitWidth
            implicitWidth: panels.session.width
        }

        PanelBg {
            id: sidebarBg
            objectName: "sidebarBg"

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: osdBg
            objectName: "osdBg"

            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.osd.x + bar.implicitWidth
            implicitWidth: panels.osd.width
        }

        PanelBg {
            id: notifsBg
            objectName: "notifsBg"

            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg
            objectName: "utilsBg"

            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: popoutBg
            objectName: "popoutBg"

            // Extra width to prevent vertical movement deformation partially detaching panel from bar
            property real extraWidth: panels.popouts.isDetached ? 0 : 0.2

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: panels.popoutsWrapper.x + panels.popouts.x + bar.implicitWidth - panels.popouts.width * extraWidth
            implicitWidth: panels.popouts.width * (1 + extraWidth)

            Behavior on extraWidth {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        screenState: root.screenState
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            borderThickness: root.borderThickness

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            clipboard.transform: Matrix4x4 {
                matrix: clipboardBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts

            fullscreen: root.hasFullscreen
        }
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        visible: panel ? (panel.visible && panel.opacity > 0) : false
        x: panel ? panel.x + bar.implicitWidth : 0
        y: panel ? panel.y + root.borderThickness : 0
        implicitWidth: panel ? panel.width : 0
        implicitHeight: panel ? panel.height : 0
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }

    BackgroundEffect.blurRegion: Compositor.layer_blur_enabled ? blurRegionRef : null

    Region {
        id: blurRegionRef

        Region {
            x: 0
            y: 0
            width: bar.width
            height: root.height
        }

        Region {
            x: dashBg.x
            y: Math.max(0, dashBg.y)
            width: root.screenState.dashboard ? dashBg.width : 0
            height: root.screenState.dashboard ? Math.max(0, dashBg.height + Math.min(0, dashBg.y)) : 0
            radius: dashBg.radius
        }

        Region {
            x: launcherBg.x
            y: launcherBg.y
            width: root.screenState.launcher ? launcherBg.width : 0
            height: root.screenState.launcher ? launcherBg.height : 0
            radius: launcherBg.radius
        }

        Region {
            x: sidebarBg.x
            y: sidebarBg.y
            width: root.screenState.sidebar ? sidebarBg.width : 0
            height: root.screenState.sidebar ? sidebarBg.height : 0
            radius: sidebarBg.radius
        }

        Region {
            x: clipboardBg.x
            y: clipboardBg.y
            width: root.screenState.clipboard ? clipboardBg.width : 0
            height: root.screenState.clipboard ? clipboardBg.height : 0
            radius: clipboardBg.radius
        }

        Region {
            x: sessionBg.x
            y: sessionBg.y
            width: root.screenState.session ? sessionBg.width : 0
            height: root.screenState.session ? sessionBg.height : 0
            radius: sessionBg.radius
        }

        Region {
            x: popoutBg.x
            y: popoutBg.y
            width: panels.popouts.hasCurrent ? popoutBg.width : 0
            height: panels.popouts.hasCurrent ? popoutBg.height : 0
            radius: popoutBg.radius
        }

        Region {
            x: utilsBg.x
            y: utilsBg.y
            width: root.screenState.utilities ? utilsBg.width : 0
            height: root.screenState.utilities ? utilsBg.height : 0
            radius: utilsBg.radius
        }
    }
}

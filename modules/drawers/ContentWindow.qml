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

    readonly property bool anyPanelOpen: isTransitioning
        || screenState.launcher
        || screenState.session
        || screenState.dashboard
        || screenState.sidebar
        || screenState.clipboard
        || screenState.utilities
        || screenState.osd
        || panels.popouts.hasCurrent
        || (panels.osd && panels.osd.offsetScale < 1.0)
        || panels.notifications.visible

    readonly property bool focusGrabActive: {
        const s = root.screenState;
        const conf = root.contentItem.Config;
        if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled) || (s.sidebar && conf.sidebar.enabled) || s.clipboard)
            return true;
        if ((!conf.dashboard.showOnHover || conf.dashboard.revealMode === "click") && s.dashboard && conf.dashboard.enabled)
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

        const conf = contentItem.Config;
        const anyDragPanel = ["dashboard", "launcher", "session", "sidebar"].some(p => {
            const c = conf[p];
            return c && c.enabled && (c.revealMode === "drag" || (!c.revealMode && !c.showOnHover));
        });
        if (!anyDragPanel)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.min(30, Math.max(...thresholds));
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

    Item {
        id: shellShadows
        anchors.fill: parent
        visible: Config.appearance.shellShadow.enabled && opacity > 0
        opacity: root.shadowOpacity
        Behavior on opacity { Anim {} }

        component PanelShadow: ShaderEffect {
            id: shadowComp
            required property Item bg
            property bool active: true

            readonly property real pad: Math.max(Compositor.shadow_softness, 32) + 8.0
            readonly property real itemW: bg ? (bg.width > 0 ? bg.width : bg.implicitWidth) : 0
            readonly property real itemH: bg ? (bg.height > 0 ? bg.height : bg.implicitHeight) : 0

            visible: Boolean(active && bg && bg.visible && itemW > 0 && itemH > 0 && opacity > 0.01)
            opacity: {
                if (!active || !bg || !bg.visible) return 0.0;
                if (bg.panel) {
                    if (bg.panel.offsetScale !== undefined) {
                        return (1.0 - bg.panel.offsetScale) * (bg.panel.opacity !== undefined ? bg.panel.opacity : 1.0);
                    }
                    if (bg.panel.opacity !== undefined) return bg.panel.opacity;
                }
                return bg.opacity !== undefined ? bg.opacity : 1.0;
            }
            Behavior on opacity { Anim {} }

            x: bg ? bg.x - pad : 0
            y: bg ? bg.y - pad : 0
            width: Math.max(1, itemW + pad * 2)
            height: Math.max(1, itemH + pad * 2)

            property real radius: bg ? (bg.radius || 0) : 0
            property vector2d resolution: Qt.vector2d(width, height)
            property vector2d center: Qt.vector2d(pad + itemW * 0.5, pad + itemH * 0.5)
            property vector2d halfSize: Qt.vector2d(itemW * 0.5, itemH * 0.5)
            property color shadowColor: Compositor.shadow_color || Colours.palette.m3shadow || "#000000"
            property real shadowSoftness: Compositor.shadow_softness
            property real shadowOpacity: 1.0

            fragmentShader: Qt.resolvedUrl("shaders/panel_edge_shadow.frag.qsb")
        }

        // Left Bar Shadow (when bar is expanded beyond border thickness)
        ShaderEffect {
            readonly property real pad: Math.max(Compositor.shadow_softness, 32) + 8.0
            readonly property real barW: bar.implicitWidth

            visible: barW > Config.border.thickness && opacity > 0.01
            x: -pad
            y: -pad
            width: Math.max(1, barW + pad * 2)
            height: Math.max(1, root.height + pad * 2)

            property real radius: 0
            property vector2d resolution: Qt.vector2d(width, height)
            property vector2d center: Qt.vector2d(pad + barW * 0.5, pad + root.height * 0.5)
            property vector2d halfSize: Qt.vector2d(barW * 0.5, root.height * 0.5)
            property color shadowColor: Compositor.shadow_color || Colours.palette.m3shadow || "#000000"
            property real shadowSoftness: Compositor.shadow_softness
            property real shadowOpacity: 1.0

            fragmentShader: Qt.resolvedUrl("shaders/panel_edge_shadow.frag.qsb")
        }

        PanelShadow {
            bg: dashBg
            active: (root.screenState.dashboard || panels.dashboard.visible) && panels.dashboard.offsetScale < 0.05
        }
        PanelShadow {
            bg: launcherBg
            active: (root.screenState.launcher || panels.launcher.visible) && panels.launcher.offsetScale < 0.05
        }
        PanelShadow {
            bg: clipboardBg
            active: (root.screenState.clipboard || panels.clipboard.visible) && panels.clipboard.offsetScale < 0.05
        }
        PanelShadow {
            bg: sessionBg
            active: (root.screenState.session || panels.session.visible) && panels.session.offsetScale < 0.05
        }
        PanelShadow {
            bg: sidebarBg
            active: (root.screenState.sidebar || panels.sidebar.visible) && panels.sidebar.offsetScale < 0.05
        }
        PanelShadow {
            bg: osdBg
            active: (root.screenState.osd || panels.osd.visible) && panels.osd.offsetScale < 0.05
        }
        PanelShadow {
            bg: notifsBg
            active: panels.notifications.visible
        }
        PanelShadow {
            bg: utilsBg
            active: (root.screenState.utilities || root.screenState.sidebar || panels.utilities.visible) && panels.utilities.offsetScale < 0.05
        }
        PanelShadow {
            bg: popoutBg
            active: panels.popouts.hasCurrent
        }
    }

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
            deformAmount: 0.0
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
            visible: panels.session.visible && panels.session.opacity > 0
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
            visible: panels.osd.visible && panels.osd.opacity > 0
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
        objectName: "interactionWrapper"

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

    readonly property bool shellBlurActive: Compositor.layer_blur_enabled

    // Permanently bind blurRegionRef with its offscreen 1x1 anchor so Quickshell never unsets
    // the Wayland blur region with nullptr. When shellBlurActive is false, all visual subregions
    // evaluate to 0 width/height, ensuring zero blur is requested from the compositor.
    BackgroundEffect.blurRegion: blurRegionRef

    Region {
        id: blurRegionRef

        // Keep a non-empty offscreen region so Quickshell never unsets the Wayland blur
        // region with set_blur_region(nullptr). This prevents Niri from falling back
        // to fullscreen surface geometry blur, which erases application windows in X-ray mode.
        Region {
            x: -100
            y: -100
            width: 1
            height: 1
        }

        Region {
            x: 0
            y: 0
            width: shellBlurActive && (bar.implicitWidth > Config.border.thickness) ? bar.implicitWidth : 0
            height: shellBlurActive ? root.height : 0
        }

        Region {
            x: dashBg.x
            y: 0
            width: shellBlurActive && root.screenState.dashboard && panels.dashboard.offsetScale < 0.05 ? dashBg.width : 0
            height: shellBlurActive && root.screenState.dashboard && panels.dashboard.offsetScale < 0.05 ? dashBg.height : 0
            radius: dashBg.radius
        }

        Region {
            x: launcherBg.x
            y: launcherBg.y
            width: shellBlurActive && root.screenState.launcher && panels.launcher.offsetScale < 0.05 ? launcherBg.width : 0
            height: shellBlurActive && root.screenState.launcher && panels.launcher.offsetScale < 0.05 ? launcherBg.height : 0
            radius: launcherBg.radius
        }

        Region {
            x: sidebarBg.x
            y: sidebarBg.y
            width: shellBlurActive && root.screenState.sidebar && panels.sidebar.offsetScale < 0.05 ? sidebarBg.width : 0
            height: shellBlurActive && root.screenState.sidebar && panels.sidebar.offsetScale < 0.05 ? sidebarBg.height : 0
            radius: sidebarBg.radius
        }

        Region {
            x: clipboardBg.x
            y: clipboardBg.y
            width: shellBlurActive && root.screenState.clipboard && panels.clipboard.offsetScale < 0.05 ? clipboardBg.width : 0
            height: shellBlurActive && root.screenState.clipboard && panels.clipboard.offsetScale < 0.05 ? clipboardBg.height : 0
            radius: clipboardBg.radius
        }

        Region {
            x: sessionBg.x
            y: sessionBg.y
            width: shellBlurActive && root.screenState.session && panels.session.offsetScale < 0.05 ? sessionBg.width : 0
            height: shellBlurActive && root.screenState.session && panels.session.offsetScale < 0.05 ? sessionBg.height : 0
            radius: sessionBg.radius
        }

        Region {
            x: popoutBg.x
            y: popoutBg.y
            width: shellBlurActive && panels.popouts.hasCurrent ? popoutBg.width : 0
            height: shellBlurActive && panels.popouts.hasCurrent ? popoutBg.height : 0
            radius: popoutBg.radius
        }

        Region {
            x: utilsBg.x
            y: utilsBg.y
            width: shellBlurActive && root.screenState.utilities && panels.utilities.offsetScale < 0.05 ? utilsBg.width : 0
            height: shellBlurActive && root.screenState.utilities && panels.utilities.offsetScale < 0.05 ? utilsBg.height : 0
            radius: utilsBg.radius
        }

        Region {
            x: osdBg.x
            y: osdBg.y
            width: shellBlurActive && (root.screenState.osd || (panels.osd && panels.osd.offsetScale < 0.05)) ? osdBg.width : 0
            height: shellBlurActive && (root.screenState.osd || (panels.osd && panels.osd.offsetScale < 0.05)) ? osdBg.height : 0
            radius: osdBg.radius
        }

        Region {
            x: notifsBg.x
            y: notifsBg.y
            width: shellBlurActive && panels.notifications.visible ? notifsBg.width : 0
            height: shellBlurActive && panels.notifications.visible ? notifsBg.height : 0
            radius: notifsBg.radius
        }
    }
}

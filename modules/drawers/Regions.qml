pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Nilastia.Config
import qs.modules.bar as Bar
import qs.components

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: bar.clampedWidth + win.dragMaskPadding
    y: clampedThickness + win.dragMaskPadding
    width: win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2
    height: win.height - clampedThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel ? panel.height * (1 - panel.offsetScale) + root.borderThickness : 0
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel ? panel.height * (1 - panel.offsetScale) + root.borderThickness : 0
    }

    R {
        panel: root.panels.clipboard
        y: root.win.height - height
        height: panel ? panel.height * (1 - panel.offsetScale) + root.borderThickness : 0
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel ? panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width : 0
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel ? panel.width * (1 - panel.offsetScale) + root.borderThickness : 0
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel ? panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.width : 0
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel ? panel.height + root.borderThickness : 0
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel ? panel.height * (1 - panel.offsetScale) + root.borderThickness : 0
    }

    R {
        panel: root.panels.popoutsWrapper
        width: panel ? panel.width * (1 - panel.offsetScale) : 0
    }

    component R: Region {
        required property Item panel

        x: panel ? panel.x + root.bar.implicitWidth : 0
        y: panel ? panel.y + root.borderThickness : 0
        width: panel ? panel.width : 0
        height: panel ? panel.height : 0
        radius: panel ? Tokens.rounding.extraLarge : 0
        intersection: Intersection.Subtract
    }
}

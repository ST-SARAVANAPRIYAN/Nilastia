import QtQuick

Item {
    // Mock CustomShortcut for Niri compositor.
    // Keyboard shortcuts are handled natively via Niri's KDL configurations.
    property string appid: ""
    property var shortcut: null
    property string name: ""
    property string description: ""
    signal pressed()
    signal released()
}

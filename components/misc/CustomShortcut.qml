import QtQuick

Item {
    // Mock CustomShortcut for Niri compositor.
    // Keyboard shortcuts are handled natively via Niri's KDL configurations.
    property string appid: ""
    property var shortcut: null
    signal pressed()
}

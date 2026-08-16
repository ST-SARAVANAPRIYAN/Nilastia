import QtQuick
import Quickshell
import Nilastia.Images

Image {
    id: root

    property string path

    asynchronous: path && path.startsWith("data:") ? false : true
    fillMode: Image.PreserveAspectCrop
    source: path && path.startsWith("data:") ? path : IUtils.urlForPath(path, fillMode)
    sourceSize: {
        if (path && path.startsWith("data:")) return undefined;
        if (width <= 0 || height <= 0) return undefined;
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }
}

import QtQuick
import Quickshell
import Nilastia.Images

Image {
    id: root

    property string path

    asynchronous: true
    cache: true
    mipmap: true
    smooth: true
    fillMode: Image.PreserveAspectCrop
    source: path && path.startsWith("data:") ? path : IUtils.urlForPath(path, fillMode)
    sourceSize: {
        if (width <= 0 || height <= 0) return undefined;
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(Math.ceil(width * 1.15 * dpr), Math.ceil(height * 1.15 * dpr));
    }
}

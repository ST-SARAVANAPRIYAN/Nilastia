pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Nilastia.Config
import Nilastia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    property string parallaxPreviewPath: ""
    readonly property string currentPreviewPath: {
        let path = root.current;
        if (!path) return "";
        if (path.toLowerCase().endsWith("wallpaper.json")) {
            return root.parallaxPreviewPath;
        }
        return path;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached(["nilastia", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["nilastia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    property bool isInitializingFallback: false

    FileView {
        path: Paths.state ? root.currentNamePath : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                if (!root.isInitializingFallback) {
                    root.isInitializingFallback = true;
                    Quickshell.execDetached(["nilastia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
                }
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            if (!root.isInitializingFallback) {
                root.isInitializingFallback = true;
                Quickshell.execDetached(["nilastia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: ["nilastia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    FileView {
        id: activeWallpaperReader
        path: root.current && root.current.toLowerCase().endsWith("wallpaper.json") ? root.current : ""
        printErrors: false
        
        onLoaded: {
            try {
                let json = JSON.parse(text());
                if (json.parallax && json.parallax.layers && json.parallax.layers.length > 0) {
                    let idx = root.current.lastIndexOf("/");
                    let basePath = idx >= 0 ? root.current.slice(0, idx + 1) : "";
                    root.parallaxPreviewPath = basePath + json.parallax.layers[0].source;
                } else {
                    root.parallaxPreviewPath = "";
                }
            } catch(e) {
                root.parallaxPreviewPath = "";
            }
        }
        onLoadFailed: {
            root.parallaxPreviewPath = "";
        }
    }
}

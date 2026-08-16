pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Niri state properties
    property bool niriAvailable: false
    property var _workspacesRaw: []
    property var _windowsRaw: []
    property var _outputsRaw: ({})
    property string _focusedWorkspaceId: ""
    property string _focusedWindowId: ""
    property string _focusedMonitorName: ""

    // Hyprland compatibility interfaces (mocked)
    readonly property var toplevels: ({ get values() { return root._toplevelsList; } })
    readonly property var workspaces: ({ get values() { return root._workspacesList; } })
    readonly property var monitors: ({ get values() { return root._monitorsList; } })
    readonly property bool usingLua: false

    readonly property var activeToplevel: {
        if (root._focusedWindowId) {
            const w = root._windowsRaw.find(x => x.id === root._focusedWindowId);
            if (w) {
                const scrSize = getScreenSizeForWindow(w);
                const rect = getWindowScreenRect(w, scrSize.width, scrSize.height);
                return {
                    title: w.title || "",
                    lastIpcObject: {
                        "class": w.app_id || "",
                        initialClass: w.app_id || "",
                        address: w.id.toString(),
                        title: w.title || "",
                        pinned: 0,
                        fullscreen: w.is_focused && root._inOverview ? 1 : 0,
                        floating: w.is_floating ? 1 : 0,
                        at: [rect.x, rect.y],
                        size: [rect.w, rect.h]
                    },
                    wayland: null,
                    address: w.id.toString(),
                    workspace: {
                        id: (function() {
                            const ws = root._workspacesRaw.find(x => x.id === w.workspace_id);
                            return ws ? ws.idx + 1 : 1;
                        })(),
                        name: (function() {
                            const ws = root._workspacesRaw.find(x => x.id === w.workspace_id);
                            return ws ? ws.name || (ws.idx + 1).toString() : "";
                        })()
                    }
                };
            }
        }
        return null;
    }

    readonly property var focusedWorkspace: {
        if (root._focusedWorkspaceId) {
            const ws = root._workspacesRaw.find(x => x.id === root._focusedWorkspaceId);
            if (ws) {
                return {
                    id: ws.idx + 1,
                    name: ws.name || (ws.idx + 1).toString(),
                    lastIpcObject: {
                        windows: root._windowsRaw.filter(w => w.workspace_id === ws.id).length
                    }
                };
            }
        }
        return null;
    }

    readonly property var focusedMonitor: {
        if (root._focusedMonitorName) {
            return {
                name: root._focusedMonitorName,
                lastIpcObject: {
                    specialWorkspace: { name: "" }
                }
            };
        }
        return null;
    }

    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // Keyboard state (using Niri event stream)
    property var kbLayoutsArray: []
    property int kbLayoutIndex: 0
    readonly property bool capsLock: false
    readonly property bool numLock: false
    readonly property string defaultKbLayout: kbLayoutsArray[0] || "??"
    readonly property string kbLayoutFull: (kbLayoutsArray.length > 0 && kbLayoutIndex >= 0 && kbLayoutIndex < kbLayoutsArray.length) ? kbLayoutsArray[kbLayoutIndex] : "Unknown"
    readonly property string kbLayout: (kbLayoutsArray.length > 0 && kbLayoutIndex >= 0 && kbLayoutIndex < kbLayoutsArray.length) ? kbLayoutsArray[kbLayoutIndex].slice(0, 2).toLowerCase() : "??"
    readonly property var kbMap: new Map()

    // Unused / mock extras
    readonly property var extras: ({
        devices: { keyboards: [] },
        options: {},
        refreshDevices: () => {},
        batchMessage: () => {}
    })
    readonly property var options: ({})
    readonly property var devices: ({ keyboards: [] })
    property bool hadKeyboard: false
    property string lastSpecialWorkspace: ""

    signal configReloaded

    // Internal QML mappings
    property var _toplevelsList: []
    property var _workspacesList: []
    property var _monitorsList: []
    property var windowsByWorkspace: ({})
    property bool _inOverview: false
    readonly property bool inOverview: _inOverview

    function updateLists() {
        // Rebuild toplevels list
        const toplevelsTmp = [];
        for (const w of root._windowsRaw) {
            const scrSize = getScreenSizeForWindow(w);
            const rect = getWindowScreenRect(w, scrSize.width, scrSize.height);
            toplevelsTmp.push({
                title: w.title || "",
                lastIpcObject: {
                    "class": w.app_id || "",
                    initialClass: w.app_id || "",
                    address: w.id.toString(),
                    title: w.title || "",
                    pinned: 0,
                    fullscreen: 0,
                    floating: w.is_floating ? 1 : 0,
                    at: [rect.x, rect.y],
                    size: [rect.w, rect.h]
                },
                wayland: null,
                address: w.id.toString(),
                workspace: {
                    id: (function() {
                        const ws = root._workspacesRaw.find(x => x.id === w.workspace_id);
                        return ws ? ws.idx + 1 : 1;
                    })(),
                    name: (function() {
                        const ws = root._workspacesRaw.find(x => x.id === w.workspace_id);
                        return ws ? ws.name || (ws.idx + 1).toString() : "";
                    })()
                }
            });
        }
        root._toplevelsList = toplevelsTmp;

        // Group toplevels by workspace ID
        const winByWs = {};
        for (let i = 0; i < toplevelsTmp.length; i++) {
            const t = toplevelsTmp[i];
            const wsId = t.workspace.id;
            if (!winByWs[wsId]) {
                winByWs[wsId] = [];
            }
            winByWs[wsId].push(t);
        }
        root.windowsByWorkspace = winByWs;

        // Rebuild workspaces list
        const workspacesTmp = [];
        for (const ws of root._workspacesRaw) {
            workspacesTmp.push({
                id: ws.idx + 1,
                name: ws.name || (ws.idx + 1).toString(),
                monitor: ws.output,
                lastIpcObject: {
                    windows: root._windowsRaw.filter(w => w.workspace_id === ws.id).length
                }
            });
        }
        root._workspacesList = workspacesTmp;

        // Rebuild monitors list
        const monitorsTmp = [];
        const outputsKeys = Object.keys(root._outputsRaw);
        for (let i = 0; i < outputsKeys.length; i++) {
            const name = outputsKeys[i];
            monitorsTmp.push({
                name: name,
                id: i,
                focused: name === root._focusedMonitorName,
                activeWorkspace: {
                    id: (function() {
                        const ws = root._workspacesRaw.find(x => x.output === name && x.is_active);
                        return ws ? ws.idx + 1 : 1;
                    })()
                },
                lastIpcObject: {
                    specialWorkspace: { name: "" }
                }
            });
        }
        root._monitorsList = monitorsTmp;
    }

    on_WindowsRawChanged: updateLists()
    on_WorkspacesRawChanged: updateLists()
    on_OutputsRawChanged: updateLists()
    on_FocusedMonitorNameChanged: updateLists()

    function getScreenSizeForWindow(w) {
        const ws = root._workspacesRaw.find(x => x.id === w.workspace_id);
        if (ws && ws.output) {
            const scr = Screens.screens.find(s => s.name === ws.output);
            if (scr) {
                return { width: scr.width, height: scr.height };
            }
        }
        const pri = Screens.primary;
        return pri ? { width: pri.width, height: pri.height } : { width: 1920, height: 1080 };
    }

    function getWindowScreenRect(w, screenWidth, screenHeight) {
        if (!w.layout || !w.layout.window_size) {
            return { x: 0, y: 0, w: screenWidth, h: screenHeight };
        }

        const winW = w.layout.window_size[0];
        const winH = w.layout.window_size[1];

        const fw = root._windowsRaw.find(x => x.id === root._focusedWindowId);
        if (!fw || !fw.layout || !fw.layout.window_size || !fw.layout.pos_in_scrolling_layout) {
            return { x: (screenWidth - winW) / 2, y: (screenHeight - winH) / 2, w: winW, h: winH };
        }

        const fwW = fw.layout.window_size[0];
        const fwH = fw.layout.window_size[1];
        const fwCol = fw.layout.pos_in_scrolling_layout[0];
        const fwRow = fw.layout.pos_in_scrolling_layout[1];

        const col = w.layout.pos_in_scrolling_layout ? w.layout.pos_in_scrolling_layout[0] : 0;
        const row = w.layout.pos_in_scrolling_layout ? w.layout.pos_in_scrolling_layout[1] : 0;

        const colOffset = col - fwCol;
        const rowOffset = row - fwRow;

        const fwScreenX = (screenWidth - fwW) / 2;
        const winScreenX = fwScreenX + colOffset * winW;

        const fwScreenY = (screenHeight - fwH) / 2;
        const winScreenY = fwScreenY + rowOffset * winH;

        return { x: winScreenX, y: winScreenY, w: winW, h: winH };
    }

    // Hyprland to Niri translation functions
    function dispatch(request: string): void {
        const parts = request.trim().split(/\s+/);
        if (parts.length === 0) return;

        const cmd = parts[0];
        if (cmd === "workspace") {
            const arg = parts[1];
            if (arg === "r+1") {
                switchToWorkspaceUpDown("down");
            } else if (arg === "r-1") {
                switchToWorkspaceUpDown("up");
            } else if (arg.startsWith("special")) {
                // Special workspace cycle or toggle (n/a under Niri)
            } else {
                const num = parseInt(arg);
                if (!isNaN(num)) {
                    switchToWorkspaceByNumber(num);
                }
            }
        } else if (cmd === "movetoworkspace" || cmd === "movetoworkspacesilent") {
            const arg = parts[1] || "";
            const subparts = arg.split(",");
            const num = parseInt(subparts[0]);
            if (!isNaN(num)) {
                let winId = "";
                if (subparts.length > 1) {
                    winId = subparts[1].replace("address:0x", "").replace("address:", "");
                }
                moveWindowToWorkspaceByNumber(num, winId);
            }
        } else if (cmd === "closewindow") {
            const addr = parts[1] || "";
            const id = addr.replace("address:0x", "").replace("address:", "");
            closeWindow(id);
        } else if (cmd === "focuswindow") {
            const addr = parts[1] || "";
            const id = addr.replace("address:0x", "").replace("address:", "");
            focusWindow(id);
        } else if (cmd === "togglefloating") {
            const addr = parts[1] || "";
            const id = addr.replace("address:0x", "").replace("address:", "");
            if (id) {
                Quickshell.execDetached(["niri", "msg", "action", "toggle-window-floating", "--id", id.toString()]);
            } else {
                Quickshell.execDetached(["niri", "msg", "action", "toggle-window-floating"]);
            }
        } else if (cmd === "killwindow") {
            const addr = parts[1] || "";
            const id = addr.replace("address:0x", "").replace("address:", "");
            closeWindow(id);
        } else {
            console.log("HyprMock: unhandled dispatch command:", request);
        }
    }

    function cycleSpecialWorkspace(direction: string): void {
        // Niri has no special workspace concept, do nothing
    }

    // Custom helper return type is list of string, using var instead to prevent strict type check issue
    function monitorNames(): var {
        return root._monitorsList.map(e => e.name);
    }

    function monitorFor(screen: ShellScreen): var {
        const name = screen.name;
        const isFocused = name === root._focusedMonitorName;
        const ws = root._workspacesRaw.find(x => x.output === name && x.is_active);
        const wsId = ws ? ws.idx + 1 : 1;
        const wsUuid = ws ? ws.id : "";
        return {
            name: name,
            focused: isFocused,
            id: screen.index,
            activeWorkspace: {
                id: wsId,
                toplevels: {
                    get values() {
                        return root._toplevelsList.filter(t => t.workspace.id === wsId);
                    }
                },
                lastIpcObject: {
                    windows: root._windowsRaw.filter(w => w.workspace_id === wsUuid).length
                }
            },
            lastIpcObject: {
                specialWorkspace: { name: "" }
            }
        };
    }

    function reloadDynamicConfs(): void {
        // Niri has no dynamic config reloading via Hyprland commands, trigger signal only
        root.configReloaded();
    }

    // Niri commands implementation helpers
    function switchToWorkspace(workspaceId) {
        if (!niriAvailable) return;
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceId.toString()]);
    }

    function switchToWorkspaceUpDown(direction) {
        if (!niriAvailable) return;
        Quickshell.execDetached(["niri", "msg", "action", `focus-workspace-${direction}`]);
    }

    function switchToWorkspaceByNumber(number) {
        if (!niriAvailable || !root._focusedMonitorName) return;
        const outputWorkspaces = root._workspacesRaw.filter(w => w.output === root._focusedMonitorName).sort((a, b) => a.idx - b.idx);
        if (number >= 1 && number <= outputWorkspaces.length) {
            const workspace = outputWorkspaces[number - 1];
            switchToWorkspace(workspace.id);
        }
    }

    function moveWindowToWorkspaceByNumber(number, windowId) {
        if (!niriAvailable || !root._focusedMonitorName) return;
        const outputWorkspaces = root._workspacesRaw.filter(w => w.output === root._focusedMonitorName).sort((a, b) => a.idx - b.idx);
        if (number >= 1 && number <= outputWorkspaces.length) {
            const workspace = outputWorkspaces[number - 1];
            if (windowId) {
                Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", workspace.id.toString(), "--window-id", windowId.toString()]);
            } else {
                Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", workspace.id.toString()]);
            }
        }
    }

    function focusWindow(windowID) {
        if (!niriAvailable) return;
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", windowID.toString()]);
    }

    function closeWindow(windowId) {
        if (!niriAvailable) return;
        const targetId = windowId || root._focusedWindowId;
        if (targetId) {
            Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", targetId.toString()]);
        }
    }

    // Process-based Niri client implementation
    Component.onCompleted: {
        checkNiriAvailability();
    }

    Process {
        id: niriCheck
        command: ["which", "niri"]
        onExited: exitCode => {
            root.niriAvailable = exitCode === 0;
            if (root.niriAvailable) {
                eventStreamProcess.running = true;
                loadInitialNiriData();
            }
        }
    }

    function checkNiriAvailability() {
        niriCheck.running = true;
    }

    // Load initial workspaces data
    Process {
        id: initialWorkspacesQuery
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const workspaces = JSON.parse(text.trim());
                        root.handleWorkspacesChanged({ workspaces: workspaces });
                    } catch (e) {
                        console.warn("HyprMock: Failed to parse initial workspaces:", e);
                    }
                }
            }
        }
    }

    // Load initial windows data
    Process {
        id: initialWindowsQuery
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const windowsData = JSON.parse(text.trim());
                        if (windowsData) {
                            root.handleWindowsChanged({ windows: windowsData });
                        }
                    } catch (e) {
                        console.warn("HyprMock: Failed to parse initial windows:", e);
                    }
                }
            }
        }
    }

    // Load initial focused window data
    Process {
        id: initialFocusedWindowQuery
        command: ["niri", "msg", "-j", "focused-window"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const focusedData = JSON.parse(text.trim());
                        if (focusedData && focusedData.id) {
                            root.handleWindowFocusChanged({ id: focusedData.id });
                        }
                    } catch (e) {
                        console.warn("HyprMock: Failed to parse initial focused window:", e);
                    }
                }
            }
        }
    }

    // Load initial outputs data
    Process {
        id: initialOutputsQuery
        command: ["niri", "msg", "-j", "outputs"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const outputsData = JSON.parse(text.trim());
                        root.handleOutputsChanged(outputsData);
                    } catch (e) {
                        console.warn("HyprMock: Failed to parse initial outputs:", e);
                    }
                }
            }
        }
    }

    // Load initial keyboard layout data
    Process {
        id: initialKeyboardLayoutsQuery
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const kbData = JSON.parse(text.trim());
                        root.handleKeyboardLayoutsChanged({ keyboard_layouts: kbData });
                    } catch (e) {
                        console.warn("HyprMock: Failed to parse initial keyboard layouts:", e);
                    }
                }
            }
        }
    }

    function loadInitialNiriData() {
        initialWorkspacesQuery.running = true;
        initialWindowsQuery.running = true;
        initialFocusedWindowQuery.running = true;
        initialOutputsQuery.running = true;
        initialKeyboardLayoutsQuery.running = true;
    }

    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "-j", "event-stream"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    root.handleNiriEvent(event);
                } catch (e) {
                    console.warn("HyprMock: Failed to parse event:", data, e);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0 && root.niriAvailable) {
                eventStreamProcess.running = true;
            }
        }
    }

    function handleNiriEvent(event) {
        if (event.WorkspacesChanged) {
            handleWorkspacesChanged(event.WorkspacesChanged);
        } else if (event.WorkspaceActivated) {
            handleWorkspaceActivated(event.WorkspaceActivated);
        } else if (event.WindowLayoutsChanged) {
            handleWindowLayoutsChanged(event.WindowLayoutsChanged);
        } else if (event.WindowsChanged) {
            handleWindowsChanged(event.WindowsChanged);
        } else if (event.WindowClosed) {
            handleWindowClosed(event.WindowClosed);
        } else if (event.WindowFocusChanged) {
            handleWindowFocusChanged(event.WindowFocusChanged);
        } else if (event.WindowOpenedOrChanged) {
            handleWindowOpenedOrChanged(event.WindowOpenedOrChanged);
        } else if (event.OverviewOpenedOrClosed) {
            handleOverviewChanged(event.OverviewOpenedOrClosed);
        } else if (event.KeyboardLayoutsChanged) {
            handleKeyboardLayoutsChanged(event.KeyboardLayoutsChanged);
        }
    }

    function handleKeyboardLayoutsChanged(data) {
        const layouts = data.keyboard_layouts;
        if (layouts && layouts.names && layouts.names.length > 0) {
            root.kbLayoutsArray = layouts.names;
            const idx = layouts.current_idx;
            root.kbLayoutIndex = (idx >= 0 && idx < layouts.names.length) ? idx : 0;
        }
    }

    function handleWindowLayoutsChanged(data) {
        if (!data.changes) return;
        const updatedWindows = root._windowsRaw.map(w => Object.assign({}, w));
        for (let i = 0; i < data.changes.length; i++) {
            const id = data.changes[i][0];
            const layout = data.changes[i][1];
            const idx = updatedWindows.findIndex(w => w.id === id);
            if (idx >= 0) {
                updatedWindows[idx].layout = layout;
            }
        }
        root._windowsRaw = sortWindows(updatedWindows);
    }

    function handleWorkspacesChanged(data) {
        root._workspacesRaw = [...data.workspaces].sort((a, b) => a.idx - b.idx);
        const focusedIdx = root._workspacesRaw.findIndex(w => w.is_focused);
        if (focusedIdx >= 0) {
            const focusedWs = root._workspacesRaw[focusedIdx];
            root._focusedWorkspaceId = focusedWs.id;
            root._focusedMonitorName = focusedWs.output;
        }
    }

    function handleWorkspaceActivated(data) {
        root._focusedWorkspaceId = data.id;
        const idx = root._workspacesRaw.findIndex(w => w.id === data.id);
        if (idx >= 0) {
            const activatedWs = root._workspacesRaw[idx];
            for (let i = 0; i < root._workspacesRaw.length; i++) {
                if (root._workspacesRaw[i].output === activatedWs.output) {
                    root._workspacesRaw[i].is_active = false;
                    root._workspacesRaw[i].is_focused = false;
                }
            }
            root._workspacesRaw[idx].is_active = true;
            root._workspacesRaw[idx].is_focused = data.focused || false;
            root._focusedMonitorName = activatedWs.output || "";
            root._workspacesRawChanged(); // Trigger updates
        }
    }

    function sortWindows(windows) {
        return windows.slice().sort((a, b) => {
            const aPos = (a.layout && a.layout.pos_in_scrolling_layout) || [0, 0];
            const bPos = (b.layout && b.layout.pos_in_scrolling_layout) || [0, 0];
            if (aPos[0] !== bPos[0]) {
                return aPos[0] - bPos[0];
            }
            return aPos[1] - bPos[1];
        });
    }

    function handleWindowsChanged(data) {
        const newWindows = data.windows.slice();
        for (let i = 0; i < newWindows.length; i++) {
            if (!newWindows[i].layout) {
                newWindows[i].layout = {};
            }
        }
        root._windowsRaw = sortWindows(newWindows);
    }

    // Custom helper return type is list of string, using var instead to prevent strict type check issue
    function handleWindowClosed(data) {
        root._windowsRaw = root._windowsRaw.filter(w => w.id !== data.id);
    }

    function handleWindowFocusChanged(data) {
        if (data.id) {
            root._focusedWindowId = data.id;
        } else {
            root._focusedWindowId = "";
        }
    }

    function handleOutputsChanged(data) {
        root._outputsRaw = data;
    }

    function handleWindowOpenedOrChanged(data) {
        if (!data.window) return;
        const window = data.window;
        const updatedWindows = root._windowsRaw.slice();
        const existingIndex = updatedWindows.findIndex(w => w.id === window.id);
        if (existingIndex >= 0) {
            updatedWindows[existingIndex] = Object.assign({}, updatedWindows[existingIndex], window);
        } else {
            updatedWindows.push(window);
        }
        root._windowsRaw = sortWindows(updatedWindows);
        if (window.is_focused) {
            root._focusedWindowId = window.id;
        }
    }

    function handleOverviewChanged(data) {
        console.log("DEBUG: handleOverviewChanged: is_open =", data.is_open);
        root._inOverview = data.is_open;
    }
}

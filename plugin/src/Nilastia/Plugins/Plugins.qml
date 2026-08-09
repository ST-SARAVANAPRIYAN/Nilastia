pragma Singleton

import Nilastia.Plugins

PluginsBase {
    function entryPoints(type: int): list<pluginEntryPoint> {
        entryPointsRevision; // For reactivity
        return __entryPoints(type);
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.modules.common
import qs.modules.common.functions

/**
 * Configs Hyprland via hyprset.lua
 */
Singleton {
    id: root
    
    signal reloaded()

    function set(key: string, value: var) {
        Quickshell.execDetached([Directories.cliPath, "hyprset", "key", key, String(value)])
    }
    
    function setMany(entries: var) {
        for (let key in entries) {
            Quickshell.execDetached([Directories.cliPath, "hyprset", "key", key, String(entries[key])])
        }
    }
    
    function reset(key: string) {
        Quickshell.execDetached([Directories.cliPath, "hyprset", "reset", key])
    }
    
    function resetMany(keys: list<string>) {
        for (let i = 0; i < keys.length; i++) {
            Quickshell.execDetached([Directories.cliPath, "hyprset", "reset", keys[i]])
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reloaded()
            }
        }
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        try {
            if (!fileContent || fileContent.trim() === "") {
                console.log("[MaterialThemeLoader] applyColors: empty content, skipping")
                return;
            }
            const json = JSON.parse(fileContent)
            for (const key in json) {
                if (json.hasOwnProperty(key)) {
                    // Convert snake_case to CamelCase
                    const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                    const m3Key = `m3${camelCaseKey}`
                    Appearance.m3colors[m3Key] = json[key]
                }
            }
            
            Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
            console.log("[MaterialThemeLoader] applyColors: darkmode=", Appearance.m3colors.darkmode, "bg=", Appearance.m3colors.m3background)
        } catch(e) {
            console.log("[MaterialThemeLoader] Error parsing colors.json:", e)
        }
    }

    property int retryCount: 0

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: retryTimer
        interval: 150
        repeat: false
        running: false
        onTriggered: {
            if (root.retryCount < 5) {
                root.retryCount++
                console.log("[MaterialThemeLoader] Retrying file reload, attempt:", root.retryCount)
                themeFileView.reload()
            } else {
                console.log("[MaterialThemeLoader] Max retries reached, resetting path to re-establish watch")
                root.filePath = ""
                root.filePath = Directories.generatedMaterialThemePath
                root.retryCount = 0
            }
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

	FileView { 
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            console.log("[MaterialThemeLoader] onFileChanged triggered, reloading...")
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            console.log("[MaterialThemeLoader] onLoadedChanged, loaded=", themeFileView.loaded)
            if (themeFileView.loaded) {
                root.retryCount = 0
                retryTimer.stop()
                const fileContent = themeFileView.text()
                root.applyColors(fileContent)
            }
        }
        onLoadFailed: {
            console.log("[MaterialThemeLoader] onLoadFailed, starting retry timer")
            retryTimer.start()
        }
    }

    function toggleLightDark() {
        const currentlyDark = Appearance.m3colors.darkmode;
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", currentlyDark ? "light" : "dark", "--noswitch"]);
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggles between dark theme and light theme"

        onPressed: {
            root.toggleLightDark();
        }
    }

    IpcHandler {
        target: "theme"

        function toggleLightDark(): void {
            root.toggleLightDark();
        }

        function reapplyTheme(): void {
            root.reapplyTheme();
        }
    }
}

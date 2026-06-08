import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs
import QtQuick

import "./widgets"

DockButton {
    id: root

    property var appToplevel: null
    property var dockContent: null
    property int delegateIndex: -1
    property int lastFocused: -1

    readonly property real dockHeight: Config.options?.dock.height ?? 60
    property int dotMargin: Math.round(dockHeight * 0.2) - 2

    readonly property var desktopEntry: appToplevel ? TaskbarApps.getCachedDesktopEntry(appToplevel.appId) : null
    property bool isVertical: dockContent?.isVertical ?? false

    readonly property bool appIsActive: focusedWindowIndex >= 0
    readonly property int focusedWindowIndex: {
        if (!appToplevel || !appToplevel.toplevels) return -1
        for (let i = 0; i < appToplevel.toplevels.length; i++) {
            if (appToplevel.toplevels[i].activated) return i
        }
        return -1
    }

    readonly property bool appIsRunning: appToplevel && appToplevel.toplevels && appToplevel.toplevels.length > 0

    property bool _pressed: false

    width: buttonSize + dotMargin * 2
    height: buttonSize + dotMargin * 2

    opacity: 1.0
    z: 0
    scale: _pressed ? 0.88 : 1.0

    Behavior on scale {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Hover-only MouseArea for running apps (shows preview popup)
    Loader {
        anchors.fill: parent
        active: appIsRunning
        sourceComponent: MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (dockContent?.suppressHover) return
                dockContent.lastHoveredButton = root
                dockContent.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (dockContent?.lastHoveredButton === root)
                    dockContent.buttonHovered = false
            }
        }
    }

    // Drag overlay (dots-hyprland pattern)
    Loader {
        anchors.fill: parent
        z: 10
        active: true
        sourceComponent: MouseArea {
            id: dragOverlay
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            property real pressCoord: 0
            property bool dragActive: false

            onPressed: (event) => {
                root._pressed = true
                if (event.button === Qt.LeftButton) {
                    pressCoord = root.isVertical ? event.y : event.x
                }
            }
            onPositionChanged: (event) => {
                if (!pressed) return
                var cur = root.isVertical ? event.y : event.x
                var dist = Math.abs(cur - pressCoord)
                // Only allow drag when delegateIndex >= 0 (reorderable items)
                if (!dragActive && dist > 5 && root.delegateIndex >= 0) {
                    dragActive = true
                    root._pressed = false
                    if (dockContent) {
                        dockContent.buttonHovered = false
                        dockContent.startItemDrag(root.delegateIndex, dragOverlay, event.x, event.y)
                    }
                }
                if (dragActive) {
                    if (dockContent) dockContent.moveItemDrag(dragOverlay, event.x, event.y)
                }
            }
            onReleased: (event) => {
                root._pressed = false
                if (dragActive) {
                    dragActive = false
                    if (dockContent) dockContent.endItemDrag()
                    return
                }
                if (event.button === Qt.RightButton) {
                    if (dockContent) {
                        dockContent.buttonHovered = false
                        dockContent.lastHoveredButton = null
                    }
                    dockContextMenu.open()
                    return
                }
                if (event.button === Qt.MiddleButton) {
                    root.desktopEntry?.execute()
                    return
                }
                if (!appToplevel || appToplevel.toplevels.length === 0) {
                    root.desktopEntry?.execute()
                    return
                }
                lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
                appToplevel.toplevels[lastFocused].activate()
            }
            onCanceled: {
                root._pressed = false
                if (dragActive) {
                    dragActive = false
                    if (dockContent) dockContent.cancelDrag()
                }
            }
        }
    }

    altAction: () => {
        if (dockContent) {
            dockContent.buttonHovered = false
            dockContent.lastHoveredButton = null
        }
        dockContextMenu.open()
    }

    DockContextMenu {
        id: dockContextMenu
        appToplevel: root.appToplevel
        desktopEntry: root.desktopEntry
        anchorItem: root
    }

    Connections {
        target: dockContextMenu
        function onActiveChanged() {
            if (!dockContent) return
            if (dockContextMenu.active)
                dockContent.registerContextMenuOpen()
            else
                dockContent.registerContextMenuClose()
        }
    }

    // Safety: if this button is destroyed while menu is open, clean up the counter
    Component.onDestruction: {
        if (dockContent && dockContextMenu.active)
            dockContent.registerContextMenuClose()
    }

    DockAppIcon {}
    DockAppIndicator {}
}

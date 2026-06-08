import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick.Controls
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Services.Mpris

import "./widgets"

Item {
    id: root

    signal togglePinRequested

    property var currentScreen: null
    property bool isPinned: false

    readonly property real dockPadding: 0
    readonly property bool isVertical: dock.isVertical
    readonly property real dotMargin: (Config.options?.dock.height ?? 60) * 0.2 - 2
    readonly property real sepThickness: Math.max(3, Math.round(Appearance.sizes.dockButtonSize * 0.06))
    readonly property real buttonSlotSize: Appearance.sizes.dockButtonSize + dotMargin * 2

    readonly property real visualWidth: isVertical ? buttonSlotSize : unifiedRow.width
    readonly property real visualHeight: isVertical ? unifiedColumn.height : buttonSlotSize

    readonly property bool requestDockShow: previewPopupLoader.item?.visible || anyContextMenuOpen

    readonly property real maxWindowPreviewHeight: 200
    readonly property real maxWindowPreviewWidth: 300
    readonly property real windowControlsHeight: 30

    property int _contextMenuOpenCount: 0
    function registerContextMenuOpen() {
        _contextMenuOpenCount++
        _contextMenuSafetyTimer.restart()
    }
    function registerContextMenuClose() {
        _contextMenuOpenCount = Math.max(0, _contextMenuOpenCount - 1)
        _contextMenuSafetyTimer.restart()
    }
    readonly property bool anyContextMenuOpen: _contextMenuOpenCount > 0

    // Safety: if the counter stays > 0 for too long (e.g. a menu was destroyed
    // while open without properly decrementing), reset it to unstick the dock.
    Timer {
        id: _contextMenuSafetyTimer
        interval: 8000
        onTriggered: {
            if (_contextMenuOpenCount > 0) {
                _contextMenuOpenCount = 0
            }
        }
    }
    property bool popupIsResizing: false
    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property bool suppressHover: false
    property point hoveredButtonCenter: Qt.point(0, 0)
    property string externalDragIcon: ""
    property bool externalDragOver: false

    readonly property var activePlayer: MprisController.activePlayer
    readonly property string rawTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || ""
    readonly property bool hasRealData: activePlayer !== null && rawTitle !== ""
    property bool showMusicPlayer: hasRealData

    onHasRealDataChanged: {
        if (hasRealData) { switchHoldTimer.stop(); showMusicPlayer = true }
        else switchHoldTimer.restart()
    }

    Timer { id: suppressHoverTimer; interval: 250; onTriggered: root.suppressHover = false }
    Timer { id: switchHoldTimer; interval: 2000; onTriggered: if (!root.hasRealData) root.showMusicPlayer = false }

    onLastHoveredButtonChanged: {
        if (root.lastHoveredButton)
            hoveredButtonCenter = root.lastHoveredButton.mapToItem(null, root.lastHoveredButton.width / 2, root.lastHoveredButton.height / 2)
    }

    readonly property bool showPin: Config.options?.dock?.showPinButton ?? true
    readonly property bool showOverview: Config.options?.dock?.showOverviewButton ?? true
    readonly property bool showTrash: Config.options?.dock?.showTrashButton ?? true
    readonly property bool showMedia: (Config.options?.dock?.enableMediaWidget ?? false) && root.showMusicPlayer
    readonly property bool showWeather: Config.options?.dock?.enableWeatherWidget ?? false

    // ── Drag-to-reorder state (dots-hyprland pattern, adapted for variable-width items) ──
    property bool dragging: false
    property bool _reordering: false
    property bool _suppressTranslateAnim: false
    property int dragSourceIndex: -1
    property real dragCursorX: 0
    property real dragStartCursorX: 0
    property real slotWidth: 0
    property int _dragTargetIndex: -1

    // ── Helper: get the active Repeater instance ─────────────────────────
    function _getActiveRepeater() {
        return root.isVertical ? columnItemRepeater : itemRepeater
    }
    function getItemWrapper(index) {
        var repeater = _getActiveRepeater()
        return repeater ? repeater.itemAt(index) : null
    }

    // ── Helper: estimate item width in the current orientation ───────────
    function getItemWidth(index) {
        var wrapper = getItemWrapper(index)
        if (wrapper) {
            return root.isVertical ? wrapper.height : wrapper.width
        }
        // Fallback: estimate from model data
        var entry = flattenedItems[index]
        if (!entry) return buttonSlotSize
        switch (entry.type) {
            case "media":
            case "weather":
                return root.isVertical ? buttonSlotSize : buttonSlotSize * 3
            default:
                return buttonSlotSize
        }
    }

    // ── Compute drag target by walking through variable-width items ──────
    function recomputeDragTarget() {
        if (!dragging) {
            _dragTargetIndex = dragSourceIndex
            return
        }
        var delta = dragCursorX - dragStartCursorX
        var src = dragSourceIndex
        var count = flattenedItems.length
        if (count <= 1 || Math.abs(delta) < 5) {
            _dragTargetIndex = src
            return
        }
        var spacing = 2
        var step = delta > 0 ? 1 : -1
        var remaining = Math.abs(delta)
        var current = src
        while (remaining > 0) {
            var next = current + step
            if (next < 0 || next >= count) break
            // Distance from current item's center to next item's center
            var curHalf = (getItemWidth(current) + spacing) / 2
            var nextHalf = (getItemWidth(next) + spacing) / 2
            var threshold = curHalf + nextHalf
            if (remaining < threshold) break
            remaining -= threshold
            current = next
        }
        _dragTargetIndex = current
    }

    function finishDrag() {
        _suppressTranslateAnim = true
        var src = dragSourceIndex
        var tgt = _dragTargetIndex
        if (dragging && src !== tgt) {
            _reordering = true
            if (src >= 0 && src < flattenedItems.length && tgt >= 0 && tgt < flattenedItems.length) {
                var srcEntry = flattenedItems[src]
                var tgtEntry = flattenedItems[tgt]
                if (srcEntry && srcEntry.orderKey && tgtEntry && tgtEntry.orderKey
                    && srcEntry.orderKey !== tgtEntry.orderKey) {
                    var order = Array.from(Config.options.dock.order)
                    var orderSrc = order.indexOf(srcEntry.orderKey)
                    var orderDst = order.indexOf(tgtEntry.orderKey)

                    // Ensure source orderKey exists in the order array
                    // (needed for dynamic runningApp:* keys)
                    if (orderSrc === -1) {
                        var runningMarker = order.indexOf("runningApps")
                        if (runningMarker !== -1) {
                            order.splice(runningMarker + 1, 0, srcEntry.orderKey)
                        } else {
                            order.push(srcEntry.orderKey)
                        }
                    }

                    // Ensure target orderKey exists too
                    if (orderDst === -1) {
                        var rm2 = order.indexOf("runningApps")
                        if (rm2 !== -1) {
                            order.splice(rm2 + 1, 0, tgtEntry.orderKey)
                        } else {
                            order.push(tgtEntry.orderKey)
                        }
                    }

                    // Recalculate both after potential inserts
                    orderSrc = order.indexOf(srcEntry.orderKey)
                    orderDst = order.indexOf(tgtEntry.orderKey)

                    // Prevent duplicate: only proceed if both keys are at distinct positions
                    if (orderSrc !== -1 && orderDst !== -1 && orderSrc !== orderDst) {
                        order.splice(orderSrc, 1)
                        order.splice(orderDst, 0, srcEntry.orderKey)
                        Config.options.dock.order = order
                    }
                }
            }
        }
        dragging = false
        dragSourceIndex = -1
        _dragTargetIndex = -1
        dragCursorX = 0
        dragStartCursorX = 0
        buttonHovered = false
        lastHoveredButton = null
        suppressHover = true
        suppressHoverTimer.restart()
        Qt.callLater(function() {
            _reordering = false
            _suppressTranslateAnim = false
        })
    }

    function cancelDrag() {
        _suppressTranslateAnim = true
        dragging = false
        dragSourceIndex = -1
        _dragTargetIndex = -1
        dragCursorX = 0
        dragStartCursorX = 0
        Qt.callLater(function() { _suppressTranslateAnim = false })
    }

    function startItemDrag(delegateIndex, child, eventX, eventY) {
        _suppressTranslateAnim = true
        dragSourceIndex = delegateIndex
        _dragTargetIndex = delegateIndex
        var mapped = child.mapToItem(root, eventX, eventY)
        var mappedCoord = isVertical ? mapped.y : mapped.x
        dragStartCursorX = mappedCoord
        dragCursorX = mappedCoord
        // Get the dragged item's actual wrapper for slotWidth
        var wrapper = getItemWrapper(delegateIndex)
        slotWidth = (wrapper ? (isVertical ? wrapper.height : wrapper.width) : buttonSlotSize) + 2
        dragging = true
        buttonHovered = false
        if (previewPopupLoader.item) previewPopupLoader.item.show = false
        Qt.callLater(function() { _suppressTranslateAnim = false })
    }

    function moveItemDrag(child, eventX, eventY) {
        if (!dragging) return
        var mapped = child.mapToItem(root, eventX, eventY)
        dragCursorX = isVertical ? mapped.y : mapped.x
        recomputeDragTarget()
    }

    function endItemDrag() {
        finishDrag()
    }

    function mapDragToRoot(item, x, y) {
        return item.mapToItem(root, x, y)
    }

    // ── Flattened items model ─────────────────────────────────────────────
    readonly property var pinnedAppMap: {
        var m = {}
        var allApps = TaskbarApps.apps ?? []
        for (var i = 0; i < allApps.length; i++) {
            var a = allApps[i]
            if (a.pinned) m[a.appId] = a
        }
        return m
    }

    readonly property var runningAppMap: {
        var m = {}
        var allApps = TaskbarApps.apps ?? []
        for (var i = 0; i < allApps.length; i++) {
            var a = allApps[i]
            if (!a.pinned && a.toplevels && a.toplevels.length > 0)
                m[a.appId] = a
        }
        return m
    }

    readonly property var pinnedFileMap: {
        var m = {}
        var files = Config.options?.dock?.pinnedFiles ?? []
        for (var i = 0; i < files.length; i++)
            m[files[i]] = { path: files[i] }
        return m
    }

    readonly property var flattenedItems: {
        var result = []
        var order = Config.options.dock.order ?? []
        var allApps = TaskbarApps.apps ?? []
        var allAppIds = []
        for (var i = 0; i < allApps.length; i++)
            allAppIds.push(allApps[i].appId)

        // Track seen orderKeys to avoid duplicates
        var seenOrderKeys = {}

        // Pre-scan explicit running apps and apps to avoid them being swallowed by "runningApps" marker
        var explicitKeys = {}
        for (var e_i = 0; e_i < order.length; e_i++) {
            if (order[e_i].startsWith("runningApp:") || order[e_i].startsWith("app:")) {
                explicitKeys[order[e_i]] = true
            }
        }

        for (var oi = 0; oi < order.length; oi++) {
            var entry = order[oi]
            if (entry === "pin" && root.showPin) {
                result.push({ type: "action", actionId: "pin", orderKey: "pin" })
                seenOrderKeys["pin"] = true
            } else if (entry === "trash" && root.showTrash) {
                result.push({ type: "action", actionId: "trash", orderKey: "trash" })
                seenOrderKeys["trash"] = true
            } else if (entry === "overview" && root.showOverview) {
                result.push({ type: "action", actionId: "overview", orderKey: "overview" })
                seenOrderKeys["overview"] = true
            } else if (entry === "media" && root.showMedia) {
                result.push({ type: "media", orderKey: "media" })
                seenOrderKeys["media"] = true
            } else if (entry === "weather" && root.showWeather) {
                result.push({ type: "weather", orderKey: "weather" })
                seenOrderKeys["weather"] = true
            } else if (entry === "runningApps") {
                // Expand running apps as individual entries at this position
                var ras = Object.values(runningAppMap)
                for (var ri = 0; ri < ras.length; ri++) {
                    var runningKey = "runningApp:" + ras[ri].appId
                    if (!seenOrderKeys[runningKey] && !explicitKeys[runningKey] && !explicitKeys["app:" + ras[ri].appId]) {
                        result.push({ type: "app", appId: ras[ri].appId, appData: ras[ri], orderKey: runningKey })
                        seenOrderKeys[runningKey] = true
                        // Also mark the app: variant to prevent duplicates
                        seenOrderKeys["app:" + ras[ri].appId] = true
                    }
                }
            } else if (entry.startsWith("runningApp:")) {
                // Individual running app that was previously reordered
                var runningAppId = entry.substring(11)
                if (!seenOrderKeys[entry]) {
                    var runningAppData = runningAppMap[runningAppId]
                    if (runningAppData) {
                        result.push({ type: "app", appId: runningAppId, appData: runningAppData, orderKey: entry })
                        seenOrderKeys[entry] = true
                        // Also mark the app: variant to prevent duplicates
                        seenOrderKeys["app:" + runningAppId] = true
                    }
                    // If app is not running anymore, skip (cleanup)
                }
            } else if (entry.startsWith("app:")) {
                var appId = entry.substring(4)
                var appKey = "app:" + appId
                if (!seenOrderKeys[appKey]) {
                    var appData = pinnedAppMap[appId] || runningAppMap[appId]
                    if (appData || allAppIds.indexOf(appId) !== -1) {
                        result.push({ type: "app", appId: appId, appData: appData || { appId: appId, pinned: true, toplevels: [] }, orderKey: appKey })
                        seenOrderKeys[appKey] = true
                        // Also mark the runningApp variant to prevent duplicates
                        // (e.g. when an app goes from pinned→unpinned but stays running)
                        seenOrderKeys["runningApp:" + appId] = true
                    }
                }
            } else if (entry.startsWith("file:")) {
                var path = entry.substring(5)
                var fileKey = "file:" + path
                if (!seenOrderKeys[fileKey] && pinnedFileMap[path]) {
                    result.push({ type: "file", path: path, orderKey: fileKey })
                    seenOrderKeys[fileKey] = true
                }
            }
        }

        // Append any running apps that weren't in the order at all
        var remainingRas = Object.values(runningAppMap)
        for (var rj = 0; rj < remainingRas.length; rj++) {
            var rKey = "runningApp:" + remainingRas[rj].appId
            if (!seenOrderKeys[rKey]) {
                result.push({ type: "app", appId: remainingRas[rj].appId, appData: remainingRas[rj], orderKey: rKey })
                seenOrderKeys[rKey] = true
                seenOrderKeys["app:" + remainingRas[rj].appId] = true
            }
        }

        // Append pinned apps that aren't in the order at all (e.g. newly pinned apps)
        var remainingPinned = Object.values(pinnedAppMap)
        for (var pk = 0; pk < remainingPinned.length; pk++) {
            var pKey = "app:" + remainingPinned[pk].appId
            if (!seenOrderKeys[pKey]) {
                result.push({ type: "app", appId: remainingPinned[pk].appId, appData: remainingPinned[pk], orderKey: pKey })
                seenOrderKeys[pKey] = true
                seenOrderKeys["runningApp:" + remainingPinned[pk].appId] = true
            }
        }

        // Append pinned files that aren't in the order at all (e.g. newly pinned folders)
        var remainingFiles = Object.values(pinnedFileMap)
        for (var fk = 0; fk < remainingFiles.length; fk++) {
            var fKey = "file:" + remainingFiles[fk].path
            if (!seenOrderKeys[fKey]) {
                result.push({ type: "file", path: remainingFiles[fk].path, orderKey: fKey })
                seenOrderKeys[fKey] = true
            }
        }

        return result
    }

    // ── Separator helpers ──────────────────────────────────────────────────
    function isSpecialItem(item) {
        if (!item) return false
        var t = item.type
        return t === "media" || t === "weather" || t === "action"
    }

    function mimeIconFromPath(path) {
        const p = (path ?? "").toString().toLowerCase()
        if (/\.(png|jpe?g|webp|gif|svg|bmp|ico)$/.test(p)) return "image"
        if (/\.(mp3|flac|ogg|wav|aac|m4a)$/.test(p)) return "music_note"
        if (/\.(mp4|mkv|webm|avi|mov)$/.test(p)) return "movie"
        if (p.endsWith(".pdf")) return "picture_as_pdf"
        if (/\.(txt|md|rst|log)$/.test(p)) return "description"
        if (/\.(zip|tar|gz|zst|rar|7z)$/.test(p)) return "folder_zip"
        const last = p.split("/").filter(s => s).pop() || ""
        return last.includes(".") ? "insert_drive_file" : "folder"
    }

    // ── Layout ────────────────────────────────────────────────────────────
    Flickable {
        id: scrollArea
        anchors.fill: parent
        clip: true
        contentWidth: root.isVertical ? parent.width : unifiedRow.width
        contentHeight: root.isVertical ? unifiedColumn.height : parent.height
        interactive: root.isVertical ? contentHeight > height : contentWidth > width
        flickableDirection: root.isVertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick

        WheelHandler {
            onWheel: event => {
                let d = (event.angleDelta.y !== 0) ? event.angleDelta.y : event.angleDelta.x
                if (root.isVertical)
                    scrollArea.contentY = Math.max(0, Math.min(scrollArea.contentHeight - scrollArea.height, scrollArea.contentY - d))
                else
                    scrollArea.contentX = Math.max(0, Math.min(scrollArea.contentWidth - scrollArea.width, scrollArea.contentX - d))
                event.accepted = true
            }
        }

        Row {
            id: unifiedRow
            visible: !root.isVertical
            spacing: 2
            Repeater {
                id: itemRepeater
                model: root.flattenedItems
                delegate: unifiedItemDelegate
            }
        }

        Column {
            id: unifiedColumn
            visible: root.isVertical
            spacing: 2
            Repeater {
                id: columnItemRepeater
                model: root.flattenedItems
                delegate: unifiedItemDelegate
            }
        }
    }

    // ── Unified item delegate ──────────────────────────────────────────────
    Component {
        id: unifiedItemDelegate

        Item {
            id: delegateWrapper
            required property var modelData
            required property int index
            readonly property int delegateIndex: index
            readonly property var itemData: modelData
            readonly property real itemWidth: {
                if (root.isVertical) return root.buttonSlotSize
                switch (itemData.type) {
                    case "media": case "weather": return root.buttonSlotSize * 3
                    default: return root.buttonSlotSize
                }
            }
            readonly property real itemHeight: root.buttonSlotSize

            width: root.isVertical ? itemHeight : itemWidth
            height: root.isVertical ? itemWidth : itemHeight

            // Drag translation (adapted from dots-hyprland, variable-width support)
            readonly property bool isDragged: root.dragging && delegateIndex === root.dragSourceIndex
            readonly property real dragTranslate: {
                if (!root.dragging) return 0
                if (isDragged) return root.dragCursorX - root.dragStartCursorX
                var src = root.dragSourceIndex
                var tgt = root._dragTargetIndex
                var idx = delegateIndex
                var sw = root.slotWidth
                if (src < tgt && idx > src && idx <= tgt) return -sw
                if (src > tgt && idx >= tgt && idx < src) return sw
                return 0
            }
            z: isDragged ? 100 : 0
            opacity: isDragged ? 0.85 : 1
            scale: isDragged ? 1.05 : 1

            Behavior on opacity {
                enabled: !root._suppressTranslateAnim
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on scale {
                enabled: !root._suppressTranslateAnim
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            transform: Translate {
                x: root.isVertical ? 0 : delegateWrapper.dragTranslate
                y: root.isVertical ? delegateWrapper.dragTranslate : 0
                Behavior on x {
                    enabled: !delegateWrapper.isDragged && !root._suppressTranslateAnim
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    enabled: !delegateWrapper.isDragged && !root._suppressTranslateAnim
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            // ── Intelligent separators ──────────────────────────────────────
            readonly property bool _sepIsSpecial: root.isSpecialItem(delegateWrapper.itemData)
            readonly property bool _sepNextIsSpecial: {
                if (delegateIndex >= root.flattenedItems.length - 1) return false
                return root.isSpecialItem(root.flattenedItems[delegateIndex + 1])
            }
            readonly property bool _sepDividersOn: Config.options?.dock?.showDividers ?? true
            readonly property bool _sepShowBefore: _sepDividersOn && _sepIsSpecial && delegateIndex > 0
            readonly property bool _sepShowAfter: _sepDividersOn && _sepIsSpecial
                && delegateIndex < root.flattenedItems.length - 1
                && !_sepNextIsSpecial
            readonly property real _sepGapCenter: -(root.sepThickness / 2 + 1)

            // Horizontal mode: left vertical line
            Rectangle {
                visible: delegateWrapper._sepShowBefore && !root.isVertical
                anchors.left: parent.left
                anchors.leftMargin: delegateWrapper._sepGapCenter
                anchors.verticalCenter: parent.verticalCenter
                width: root.sepThickness
                height: parent.height - root.dotMargin * 2
                radius: Appearance.rounding.full
                color: Appearance.colors.colOutlineVariant
            }
            // Horizontal mode: right vertical line
            Rectangle {
                visible: delegateWrapper._sepShowAfter && !root.isVertical
                anchors.right: parent.right
                anchors.rightMargin: delegateWrapper._sepGapCenter
                anchors.verticalCenter: parent.verticalCenter
                width: root.sepThickness
                height: parent.height - root.dotMargin * 2
                radius: Appearance.rounding.full
                color: Appearance.colors.colOutlineVariant
            }
            // Vertical mode: top horizontal line
            Rectangle {
                visible: delegateWrapper._sepShowBefore && root.isVertical
                anchors.top: parent.top
                anchors.topMargin: delegateWrapper._sepGapCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - root.dotMargin * 2
                height: root.sepThickness
                radius: Appearance.rounding.full
                color: Appearance.colors.colOutlineVariant
            }
            // Vertical mode: bottom horizontal line
            Rectangle {
                visible: delegateWrapper._sepShowAfter && root.isVertical
                anchors.bottom: parent.bottom
                anchors.bottomMargin: delegateWrapper._sepGapCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - root.dotMargin * 2
                height: root.sepThickness
                radius: Appearance.rounding.full
                color: Appearance.colors.colOutlineVariant
            }

            Loader {
                id: contentLoader
                anchors.centerIn: parent

                // Expose delegate data so loaded components can access it via parent
                readonly property var _itemData: delegateWrapper.itemData
                readonly property int _index: delegateWrapper.index

                sourceComponent: {
                    switch (itemData.type) {
                        case "action": return actionItemComponent
                        case "app": return appItemComponent
                        case "file": return fileItemComponent
                        case "media": return mediaItemComponent
                        case "weather": return weatherItemComponent
                        case "runningAppsGroup": return runningAppsGroupComponent
                        default: return null
                    }
                }
            }
        }
    }

    // ── Item type components ───────────────────────────────────────────────

    Component {
        id: actionItemComponent
        Item {
            id: actionItemRoot
            width: root.buttonSlotSize
            height: root.buttonSlotSize
            readonly property var _itemData: parent._itemData
            readonly property int _index: parent._index
            DockActionButton {
                anchors.centerIn: parent
                property int _delegateIndex: actionItemRoot._index
                symbolName: {
                    switch (actionItemRoot._itemData.actionId) {
                        case "pin": return "keep"
                        case "trash": return "delete"
                        case "overview": return "apps"
                        default: return "drag_indicator"
                    }
                }
                toggledSymbolName: actionItemRoot._itemData.actionId === "pin" ? "bookmark" : ""
                toggled: actionItemRoot._itemData.actionId === "pin" && root.isPinned
                normalShape: actionItemRoot._itemData.actionId === "overview" ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Pill
                activeShape: actionItemRoot._itemData.actionId === "overview" ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Cookie9Sided
                symbolSize: Math.round(Appearance.sizes.dockButtonSize * 0.5)
                dockContent: root
                delegateIndex: actionItemRoot._index
                onClicked: {
                    if (actionItemRoot._itemData.actionId === "pin") root.togglePinRequested()
                    else if (actionItemRoot._itemData.actionId === "trash") Quickshell.execDetached(["nautilus", "trash:///"])
                    else if (actionItemRoot._itemData.actionId === "overview") GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                }
                customImageSource: actionItemRoot._itemData.actionId === "trash"
                    ? ("file://" + Directories.assetsPath + "/icons/" + (Appearance.m3colors.darkmode ? "macos-trash-dark.png" : "macos-trash.png"))
                    : ""
                dragActive: false
                dragOver: false
                dragSymbol: ""
            }
        }
    }

    Component {
        id: appItemComponent
        Item {
            id: appItemRoot
            width: root.buttonSlotSize
            height: root.buttonSlotSize
            readonly property var _itemData: parent._itemData
            readonly property int _index: parent._index
            DockAppButton {
                anchors.centerIn: parent
                appToplevel: appItemRoot._itemData.appData
                dockContent: root
                delegateIndex: appItemRoot._index
            }
        }
    }

    Component {
        id: fileItemComponent
        Item {
            id: fileItemRoot
            width: root.buttonSlotSize
            height: root.buttonSlotSize
            readonly property var _itemData: parent._itemData
            readonly property int _index: parent._index
            DockFileButton {
                anchors.centerIn: parent
                filePath: fileItemRoot._itemData.path
                dockContent: root
                delegateIndex: fileItemRoot._index
            }
        }
    }

    Component {
        id: mediaItemComponent
        Item {
            id: mediaItemRoot
            width: root.isVertical ? root.buttonSlotSize : root.buttonSlotSize * 3
            height: root.isVertical ? root.buttonSlotSize : root.buttonSlotSize
            readonly property int _index: parent._index
            DockMediaWidget {
                anchors.centerIn: parent
                isVertical: root.isVertical
                dockContent: root
                delegateIndex: mediaItemRoot._index
            }
        }
    }

    Component {
        id: weatherItemComponent
        Item {
            id: weatherItemRoot
            width: root.isVertical ? root.buttonSlotSize : root.buttonSlotSize * 3
            height: root.isVertical ? root.buttonSlotSize : root.buttonSlotSize
            readonly property int _index: parent._index
            DockWeatherWidget {
                anchors.centerIn: parent
                isVertical: root.isVertical
                dockContent: root
                delegateIndex: weatherItemRoot._index
            }
        }
    }

    Component {
        id: runningAppsGroupComponent
        Item {
            id: runningAppsRoot
            width: runningAppsRow.implicitWidth + root.dotMargin * 2
            height: root.buttonSlotSize
            readonly property var _itemData: parent._itemData
            readonly property int _index: parent._index
            Row {
                id: runningAppsRow
                spacing: 2
                anchors.centerIn: parent
                Repeater {
                    model: runningAppsRoot._itemData.apps ?? []
                    delegate: DockAppButton {
                        required property var modelData
                        appToplevel: modelData
                        dockContent: root
                        delegateIndex: -1
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                propagateComposedEvents: true
                property real pressCoord: 0
                property bool dragActive: false
                onPressed: (event) => {
                    pressCoord = root.isVertical ? event.y : event.x
                    event.accepted = false
                }
                onPositionChanged: (event) => {
                    if (!pressed) return
                    var cur = root.isVertical ? event.y : event.x
                    var dist = Math.abs(cur - pressCoord)
                    if (!dragActive && dist > 5) {
                        dragActive = true
                        root.startItemDrag(parent._index, this, event.x, event.y)
                    }
                    if (dragActive) {
                        root.moveItemDrag(this, event.x, event.y)
                        event.accepted = true
                    } else {
                        event.accepted = false
                    }
                }
                onReleased: (event) => {
                    if (dragActive) {
                        dragActive = false
                        root.endItemDrag()
                        event.accepted = true
                    } else {
                        event.accepted = false
                    }
                }
                onCanceled: (event) => {
                    if (dragActive) {
                        dragActive = false
                        root.cancelDrag()
                        event.accepted = true
                    } else {
                        event.accepted = false
                    }
                }
            }
        }
    }

    // ── Preview Popup ──────────────────────────────────────────────────────
    Loader {
        id: previewPopupLoader
        active: Config.options.dock.enablePreview ?? true
        sourceComponent: DockPreviewPopup {
            dockRoot: root
            dockWindow: root.QsWindow.window
            appTopLevel: root.lastHoveredButton?.appToplevel
        }
    }
}

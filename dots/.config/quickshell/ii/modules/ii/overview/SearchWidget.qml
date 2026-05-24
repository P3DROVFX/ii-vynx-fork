pragma ComponentBehavior: Bound

import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    signal requestToggleActions()
    id: root

    readonly property string xdgConfigHome: Directories.config
    readonly property int typingDebounceInterval: 200
    readonly property int typingResultLimit: 15
    readonly property bool isSearching: debounceTimer.running && searchingText !== ""
    readonly property bool showSkeletons: isSearching && (typeof resultModel === "undefined" || !resultModel || resultModel.values.length === 0 || (resultModel.values.length === 1 && resultModel.values[0] && resultModel.values[0].key === "mpris:now-playing"))

    property string searchingText: LauncherSearch.query
    readonly property bool isClipboardMode: root.searchingText.startsWith(Config.options.search.prefix.clipboard)
    property bool showResults: searchingText != "" || isClipboardMode || (searchingText === "" && LauncherSearch.results.length > 0)
    property string overviewPosition: Config.options.overview.position
    implicitWidth: (root.isClipboardMode ? (Config.options.search.clipboard.panelWidth ?? 860) : searchWidgetContent.implicitWidth) + Appearance.sizes.elevationMargin * 2
    implicitHeight: (root.isClipboardMode ? (clipboardPanelLoader.item ? clipboardPanelLoader.item.implicitHeight : 560) : searchWidgetContent.implicitHeight) + searchBar.verticalPadding * 2 + Appearance.sizes.elevationMargin * 2

    function focusFirstItem() {
        if (root.isClipboardMode) {
        } else {
            appResults.currentIndex = 0;
        }
    }

    function focusSearchInput() {
        searchBar.forceFocus();
    }

    function disableExpandAnimation() {
        searchBar.animateWidth = false;
    }

    function cancelSearch() {
        searchBar.searchInput.selectAll();
        LauncherSearch.query = "";
        searchBar.animateWidth = true;
    }

    function setSearchingText(text) {
        searchBar.searchInput.text = text;
        LauncherSearch.query = text;
    }

    function areResultsDifferent(newResults, currentValues) {
        if (!newResults || !currentValues) return true;
        const newLen = newResults.length;
        const curLen = currentValues.length;
        if (newLen !== curLen) return true;
        for (let i = 0; i < newLen; i++) {
            if (!newResults[i] || !currentValues[i]) return true;
            if (newResults[i].key !== currentValues[i].key) return true;
        }
        return false;
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
            if (appResults.visible) {
                root.requestToggleActions();
                event.accepted = true;
            }
            return;
        }

        // Prevent Esc and Backspace from registering
        if (event.key === Qt.Key_Escape)
            return;

        // Handle Backspace: focus and delete character if not focused
        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                if (event.modifiers & Qt.ControlModifier) {
                    // Delete word before cursor
                    let text = searchBar.searchInput.text;
                    let pos = searchBar.searchInput.cursorPosition;
                    if (pos > 0) {
                        // Find the start of the previous word
                        let left = text.slice(0, pos);
                        let match = left.match(/(\s*\S+)\s*$/);
                        let deleteLen = match ? match[0].length : 1;
                        searchBar.searchInput.text = text.slice(0, pos - deleteLen) + text.slice(pos);
                        searchBar.searchInput.cursorPosition = pos - deleteLen;
                    }
                } else {
                    // Delete character before cursor if any
                    if (searchBar.searchInput.cursorPosition > 0) {
                        searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition - 1) + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                        searchBar.searchInput.cursorPosition -= 1;
                    }
                }
                // Always move cursor to end after programmatic edit
                searchBar.searchInput.cursorPosition = searchBar.searchInput.text.length;
                event.accepted = true;
            }
            // If already focused, let TextField handle it
            return;
        }

        // Only handle visible printable characters (ignore control chars, arrows, etc.)
        if (event.text && event.text.length === 1 && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) // ignore control chars like Backspace, Tab, etc.
        {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                // Insert the character at the cursor position
                searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition) + event.text + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                searchBar.searchInput.cursorPosition += 1;
                event.accepted = true;
                root.focusFirstItem();
            }
        }
    }

    StyledRectangularShadow {
        target: searchWidgetContent
    }
    Rectangle {
        id: searchWidgetContent
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true
        implicitWidth: root.isClipboardMode ? (Config.options.search.clipboard.panelWidth ?? 860) : gridLayout.implicitWidth
        implicitHeight: root.isClipboardMode ? (clipboardPanelLoader.item ? clipboardPanelLoader.item.implicitHeight + searchBar.height + searchBar.verticalPadding * 2 + 10 : 560) : gridLayout.implicitHeight
        radius: searchBar.height / 2 + searchBar.verticalPadding
        color: Appearance.colors.colBackgroundSurfaceContainer

        Behavior on implicitWidth {
            id: searchWidthBehavior
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        Behavior on implicitHeight {
            id: searchHeightBehavior
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
            }
        }

        GridLayout {
            id: gridLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            columns: 1

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: searchWidgetContent.width
                    height: searchWidgetContent.height
                    radius: searchWidgetContent.radius
                }
            }

            SearchBar {
                id: searchBar
                property real verticalPadding: 4
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 4
                Layout.topMargin: verticalPadding
                Layout.bottomMargin: verticalPadding
                Layout.row: root.overviewPosition == "bottom" ? 2 : 0
                animateWidth: true
                Synchronizer on searchingText {
                    property alias source: root.searchingText
                }

                clipboardMode: root.isClipboardMode
                clipboardWidth: 830
                currentResultIndex: appResults.currentIndex

                onCtrlKPressed: {
                    if (appResults.visible) {
                        root.requestToggleActions();
                    }
                }

                onNavigateUp: {
                    if (root.isClipboardMode) {
                        if (clipboardPanelLoader.item)
                            clipboardPanelLoader.item.navigateUp();
                    } else {
                        if (appResults.count > 0 && appResults.currentIndex > 0)
                            appResults.currentIndex--;
                    }
                }

                onNavigateDown: {
                    if (root.isClipboardMode) {
                        if (clipboardPanelLoader.item)
                            clipboardPanelLoader.item.navigateDown();
                    } else {
                        if (appResults.count > 0 && appResults.currentIndex < appResults.count - 1)
                            appResults.currentIndex++;
                    }
                }

                onNavigateLeft: {
                    if (root.isClipboardMode && clipboardPanelLoader.item)
                        clipboardPanelLoader.item.navigateLeft();
                }

                onNavigateRight: {
                    if (root.isClipboardMode && clipboardPanelLoader.item)
                        clipboardPanelLoader.item.navigateRight();
                }

                onActivate: {
                    if (root.isClipboardMode && clipboardPanelLoader.item)
                        clipboardPanelLoader.item.activateSelected();
                }

                onDeleteSelected: {
                    if (root.isClipboardMode && clipboardPanelLoader.item) {
                        clipboardPanelLoader.item.activateSelected();
                    }
                }
            }

            Rectangle {
                visible: root.showResults || root.isClipboardMode
                Layout.fillWidth: true
                height: 1
                color: Appearance.colors.colOutlineVariant
                Layout.row: 1
            }

            Item {
                visible: root.showResults && !root.isClipboardMode
                Layout.fillWidth: true
                implicitHeight: root.showSkeletons ? searchSkeletons.implicitHeight + 20 : Math.min(600, appResults.contentHeight + appResults.topMargin + appResults.bottomMargin)
                Layout.row: root.overviewPosition == "bottom" ? 0 : 2

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                    }
                }

                ListView {
                    id: appResults
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: root.showSkeletons ? 0.0 : 1.0
                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                    }
                    clip: true
                    topMargin: 10
                    bottomMargin: 10
                    spacing: 2
                    KeyNavigation.up: searchBar
                    highlightMoveDuration: 100

                    Connections {
                        target: root
                        function onSearchingTextChanged() {
                            if (appResults.count > 0)
                                appResults.currentIndex = 0;
                        }
                    }

                    Timer {
                        id: debounceTimer
                        interval: root.typingDebounceInterval
                        onTriggered: {
                            resultModel.values = LauncherSearch.results.slice(0, root.typingResultLimit);
                            root.focusFirstItem();
                        }
                    }

                    Connections {
                        target: LauncherSearch
                        function onResultsChanged() {
                            const newResults = LauncherSearch.results;
                            const currentValues = resultModel.values;

                            // If the incoming search results are exactly identical to what is
                            // currently displayed, do not trigger any loading state or restart timers.
                            if (!root.areResultsDifferent(newResults, currentValues)) {
                                return;
                            }

                            if (LauncherSearch.query === "" || newResults.length === 0) {
                                debounceTimer.stop();
                                resultModel.values = newResults.slice(0, root.typingResultLimit);
                                root.focusFirstItem();
                            } else {
                                debounceTimer.restart();
                            }
                        }
                    }

                    model: ScriptModel {
                        id: resultModel
                        objectProp: "key"
                        onValuesChanged: Qt.callLater(() => {
                            if (appResults.count > 0) {
                                appResults.currentIndex = 0;
                            }
                        })
                        Component.onCompleted: {
                            values = LauncherSearch.results.slice(0, root.typingResultLimit);
                        }
                    }

                    delegate: SearchItem {
                        id: searchItem
                        required property int index
                        listIndex: index
                        listCurrentIndex: appResults.currentIndex
                        required property var modelData
                        anchors.left: parent?.left
                        anchors.right: parent?.right
                        entry: modelData
                        query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])

                        Connections {
                            target: root
                            function onRequestToggleActions() {
                                if (searchItem.listIndex === appResults.currentIndex) {
                                    searchItem.actionPanelOpen = !searchItem.actionPanelOpen;
                                    searchItem.actionSelectedIndex = 0;
                                    if (searchItem.actionPanelOpen) {
                                        searchItem.forceActiveFocus();
                                    } else {
                                        root.focusSearchInput();
                                    }
                                }
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
                                searchItem.actionPanelOpen = !searchItem.actionPanelOpen;
                                searchItem.actionSelectedIndex = 0;
                                if (searchItem.actionPanelOpen) {
                                    searchItem.forceActiveFocus();
                                } else {
                                    root.focusSearchInput();
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                if (searchItem.actionPanelOpen) return;
                                if (LauncherSearch.results.length === 0)
                                    return;
                                const tabbedText = searchItem.modelData.name;
                                LauncherSearch.query = tabbedText;
                                searchBar.searchInput.text = tabbedText;
                                event.accepted = true;
                                root.focusSearchInput();
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: searchSkeletons
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 8
                    visible: opacity > 0
                    opacity: root.showSkeletons ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                    }

                    Repeater {
                        model: 4
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colSurfaceContainerHigh
                            antialiasing: true

                            // Shimmer animation with wave phase shift
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: searchSkeletons.visible
                                NumberAnimation { from: 0.25; to: 0.65; duration: 600 + index * 100; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: 0.65; to: 0.25; duration: 600 + index * 100; easing.type: Easing.InOutQuad }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: Appearance.rounding.full
                                    color: Appearance.colors.colSurfaceContainerHighest
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 120
                                        implicitHeight: 12
                                        radius: Appearance.rounding.verysmall
                                        color: Appearance.colors.colSurfaceContainerHighest
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 80
                                        implicitHeight: 8
                                        radius: Appearance.rounding.verysmall
                                        color: Appearance.colors.colSurfaceContainerHighest
                                    }
                                }
                            }
                        }
                    }
                }
            }


            Loader {
                id: clipboardPanelLoader
                visible: root.isClipboardMode
                active: root.isClipboardMode
                Layout.fillWidth: true
                source: "ClipboardPanel.qml"
                Layout.row: root.overviewPosition == "bottom" ? 0 : 2

                // Fade+slide in when clipboard panel loads
                opacity: root.isClipboardMode ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                    }
                }

                Binding {
                    target: clipboardPanelLoader.item
                    property: "searchQuery"
                    value: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.clipboard])
                    when: clipboardPanelLoader.status === Loader.Ready
                }
            }
        }
    }
}

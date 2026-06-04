pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string searchQuery: ""

    readonly property int panelWidth: Config.options.search.clipboard.panelWidth ?? 860
    implicitWidth: panelWidth
    implicitHeight: 520

    // Signals for parent communication
    signal requestSetSearchQuery(string query)
    signal requestFocusSearchInput()

    // Colors
    property color colLangBtn: Appearance.colors.colSecondaryContainer
    property color colLangBtnHover: Appearance.colors.colSecondaryContainerHover
    property color colLangBtnActive: Appearance.colors.colSecondaryContainerActive
    property color colLangText: Appearance.colors.colOnSecondaryContainer

    property color colSwapBtn: Appearance.colors.colTertiaryContainer
    property color colSwapBtnHover: Appearance.colors.colTertiaryContainerHover
    property color colSwapBtnActive: Appearance.colors.colTertiaryContainerActive
    property color colSwapIcon: Appearance.colors.colOnTertiaryContainer

    property color colInputBox: Appearance.colors.colSurfaceContainerHigh
    property color colInputText: Appearance.colors.colOnSurface

    property color colResultBox: Appearance.colors.colSurfaceContainerHigh
    property color colResultText: Appearance.colors.colOnSurface

    property color colBtn: Appearance.colors.colSurfaceContainerHighest
    property color colBtnHover: Appearance.colors.colSurfaceContainerHighestHover
    property color colBtnActive: Appearance.colors.colSurfaceContainerHighestActive
    property color colIcon: Appearance.colors.colOnSurfaceVariant

    // States & Options
    property string targetLanguage: {
        let def = Config.options.language.translator.defaultTargetLanguage;
        if (def && def !== "" && def !== "auto") return def;
        return Config.options.language.translator.targetLanguage || "pt";
    }
    property string sourceLanguage: {
        let def = Config.options.language.translator.defaultSourceLanguage;
        if (def && def !== "" && def !== "auto") return def;
        return Config.options.language.translator.sourceLanguage || "auto";
    }

    property string translatedText: ""
    property list<string> languages: []
    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false // true for target, false for source

    // Keyboard navigation focus index
    // -1 = SearchBar (default)
    // 0 = Source Lang Button, 1 = Swap, 2 = Target Lang Button
    // 3 = Paste, 4 = Clear, 5 = Copy, 6 = Search Web
    property int focusedControlIndex: -1

    function showLanguageSelectorDialog(isTargetLang) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true;
    }

    function swapLanguages() {
        let temp = root.sourceLanguage;
        root.sourceLanguage = root.targetLanguage;
        root.targetLanguage = temp;
        // Trigger translation
        if (root.searchQuery.trim().length > 0) {
            translateTimer.restart();
        }
    }

    function pasteFromClipboard() {
        let clipboardText = Quickshell.clipboardText;
        if (clipboardText) {
            root.requestSetSearchQuery(clipboardText);
        }
    }

    function clearInput() {
        root.requestSetSearchQuery("");
    }

    function copyTranslation() {
        if (root.translatedText.length > 0) {
            Quickshell.clipboardText = root.translatedText;
        }
    }

    function searchWeb() {
        if (root.translatedText.length > 0) {
            let url = Config.options.search.engineBaseUrl + root.translatedText;
            for (let site of Config.options.search.excludedSites) {
                url += ` -site:${site}`;
            }
            Qt.openUrlExternally(url);
        }
    }

    function isControlVisible(index) {
        if (index === 0 || index === 1 || index === 2 || index === 3) return true;
        if (index === 4) return root.searchQuery.length > 0;
        if (index === 5 || index === 6) return root.translatedText.length > 0;
        return false;
    }

    function navigateDown() {
        if (focusedControlIndex === -1) {
            focusedControlIndex = 0;
        } else if (focusedControlIndex === 0) {
            focusedControlIndex = 3;
        } else if (focusedControlIndex === 1) {
            if (isControlVisible(4)) focusedControlIndex = 4;
            else if (isControlVisible(5)) focusedControlIndex = 5;
            else focusedControlIndex = 3;
        } else if (focusedControlIndex === 2) {
            if (isControlVisible(6)) focusedControlIndex = 6;
            else if (isControlVisible(5)) focusedControlIndex = 5;
            else if (isControlVisible(4)) focusedControlIndex = 4;
            else focusedControlIndex = 3;
        }
    }

    function navigateUp() {
        if (focusedControlIndex === 3 || focusedControlIndex === 4) {
            focusedControlIndex = 0;
        } else if (focusedControlIndex === 5 || focusedControlIndex === 6) {
            focusedControlIndex = 2;
        } else if (focusedControlIndex === 0 || focusedControlIndex === 1 || focusedControlIndex === 2) {
            focusedControlIndex = -1;
            root.requestFocusSearchInput();
        }
    }

    function navigateLeft() {
        if (focusedControlIndex === 2) {
            focusedControlIndex = 1;
        } else if (focusedControlIndex === 1) {
            focusedControlIndex = 0;
        } else if (focusedControlIndex > 3 && focusedControlIndex <= 6) {
            for (let i = focusedControlIndex - 1; i >= 3; i--) {
                if (isControlVisible(i)) {
                    focusedControlIndex = i;
                    break;
                }
            }
        }
    }

    function navigateRight() {
        if (focusedControlIndex === 0) {
            focusedControlIndex = 1;
        } else if (focusedControlIndex === 1) {
            focusedControlIndex = 2;
        } else if (focusedControlIndex >= 3 && focusedControlIndex < 6) {
            for (let i = focusedControlIndex + 1; i <= 6; i++) {
                if (isControlVisible(i)) {
                    focusedControlIndex = i;
                    break;
                }
            }
        }
    }

    function activateSelected() {
        if (focusedControlIndex === -1) {
            root.copyTranslation();
        } else if (focusedControlIndex === 0) {
            root.showLanguageSelectorDialog(false);
        } else if (focusedControlIndex === 1) {
            root.swapLanguages();
        } else if (focusedControlIndex === 2) {
            root.showLanguageSelectorDialog(true);
        } else if (focusedControlIndex === 3) {
            root.pasteFromClipboard();
        } else if (focusedControlIndex === 4) {
            root.clearInput();
        } else if (focusedControlIndex === 5) {
            root.copyTranslation();
        } else if (focusedControlIndex === 6) {
            root.searchWeb();
        }
    }

    function focusInput() {
        focusedControlIndex = -1;
        root.requestFocusSearchInput();
    }

    // Translation logic
    onSearchQueryChanged: {
        translateTimer.restart();
        focusedControlIndex = -1;
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay ?? 300
        repeat: false
        onTriggered: () => {
            if (root.searchQuery.trim().length > 0) {
                translateProc.running = false;
                translateProc.buffer = "";
                translateProc.running = true;
            } else {
                root.translatedText = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -brief -no-bidi` + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'` + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'` + ` '${StringUtils.shellSingleQuoteEscape(root.searchQuery.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.translatedText = translateProc.buffer.trim();
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            let langs = getLanguagesProc.bufferList.filter(lang => lang.trim().length > 0 && lang !== "auto").sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = [];
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Top Row: Language Selectors & Swap Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            RippleButton {
                id: srcLangBtn
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 46
                buttonRadius: Appearance.rounding.full
                colBackground: pressed ? colLangBtnActive : (hovered ? colLangBtnHover : colLangBtn)
                PointingHandInteraction {}

                contentItem: Item {
                    RowLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 24, implicitWidth)
                        spacing: 6

                        StyledText {
                            text: root.sourceLanguage
                            color: colLangText
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        MaterialSymbol {
                            text: "arrow_drop_down"
                            color: colLangText
                            iconSize: Appearance.font.pixelSize.larger
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
                onClicked: {
                    root.focusedControlIndex = 0;
                    root.showLanguageSelectorDialog(false);
                }

                // Keyboard focus highlight ring
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    border.color: root.focusedControlIndex === 0 ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2
                    radius: parent.buttonRadius + 3
                }
            }

            RippleButton {
                id: swapBtn
                implicitWidth: 46
                implicitHeight: 46
                buttonRadius: Appearance.rounding.full
                colBackground: pressed ? colSwapBtnActive : (hovered ? colSwapBtnHover : colSwapBtn)
                PointingHandInteraction {}

                contentItem: Item {
                    anchors.fill: parent
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "swap_horiz"
                        color: colSwapIcon
                        iconSize: Appearance.font.pixelSize.larger
                    }
                }
                onClicked: {
                    root.focusedControlIndex = 1;
                    root.swapLanguages();
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    border.color: root.focusedControlIndex === 1 ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2
                    radius: parent.buttonRadius + 3
                }
            }

            RippleButton {
                id: targetLangBtn
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 46
                buttonRadius: Appearance.rounding.full
                colBackground: pressed ? colLangBtnActive : (hovered ? colLangBtnHover : colLangBtn)
                PointingHandInteraction {}

                contentItem: Item {
                    RowLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 24, implicitWidth)
                        spacing: 6

                        StyledText {
                            text: root.targetLanguage
                            color: colLangText
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        MaterialSymbol {
                            text: "arrow_drop_down"
                            color: colLangText
                            iconSize: Appearance.font.pixelSize.larger
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
                onClicked: {
                    root.focusedControlIndex = 2;
                    root.showLanguageSelectorDialog(true);
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    border.color: root.focusedControlIndex === 2 ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2
                    radius: parent.buttonRadius + 3
                }
            }
        }

        // Horizontal Split View (Input / Output columns)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Left Side: Input Preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.large
                color: colInputBox

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    StyledFlickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: inputPreviewText.implicitHeight

                        StyledText {
                            id: inputPreviewText
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: root.searchQuery !== "" ? root.searchQuery : Translation.tr("Start typing to translate...")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: root.searchQuery !== "" ? colInputText : Appearance.colors.colSubtext
                            opacity: root.searchQuery !== "" ? 1.0 : 0.6
                        }
                    }

                    // Left Bottom Actions Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: root.searchQuery.length + " " + Translation.tr("characters")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            id: pasteBtn
                            implicitWidth: 38
                            implicitHeight: 38
                            buttonRadius: Appearance.rounding.full
                            colBackground: pressed ? colBtnActive : (hovered ? colBtnHover : colBtn)
                            PointingHandInteraction {}

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "content_paste"
                                    color: colIcon
                                    iconSize: 18
                                }
                            }
                            onClicked: {
                                root.focusedControlIndex = 3;
                                root.pasteFromClipboard();
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                color: "transparent"
                                border.color: root.focusedControlIndex === 3 ? Appearance.colors.colPrimary : "transparent"
                                border.width: 2
                                radius: parent.buttonRadius + 2
                            }

                            StyledToolTip { text: Translation.tr("Paste from Clipboard") }
                        }

                        RippleButton {
                            id: clearBtn
                            implicitWidth: 38
                            implicitHeight: 38
                            buttonRadius: Appearance.rounding.full
                            colBackground: pressed ? colBtnActive : (hovered ? colBtnHover : colBtn)
                            visible: root.searchQuery.length > 0
                            PointingHandInteraction {}

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    color: colIcon
                                    iconSize: 18
                                }
                            }
                            onClicked: {
                                root.focusedControlIndex = 4;
                                root.clearInput();
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                color: "transparent"
                                border.color: root.focusedControlIndex === 4 ? Appearance.colors.colPrimary : "transparent"
                                border.width: 2
                                radius: parent.buttonRadius + 2
                            }

                            StyledToolTip { text: Translation.tr("Clear Input") }
                        }
                    }
                }
            }

            // Right Side: Translated Output
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.large
                color: colResultBox

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    StyledFlickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: outputText.implicitHeight

                        StyledText {
                            id: outputText
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: root.translatedText !== "" ? root.translatedText : Translation.tr("Translation will appear here...")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: root.translatedText !== "" ? colResultText : Appearance.colors.colSubtext
                            opacity: root.translatedText !== "" ? 1.0 : 0.6
                        }
                    }

                    // Right Bottom Actions Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            id: copyBtn
                            implicitWidth: 38
                            implicitHeight: 38
                            buttonRadius: Appearance.rounding.full
                            colBackground: pressed ? colBtnActive : (hovered ? colBtnHover : colBtn)
                            visible: root.translatedText.length > 0
                            PointingHandInteraction {}

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "content_copy"
                                    color: colIcon
                                    iconSize: 18
                                }
                            }
                            onClicked: {
                                root.focusedControlIndex = 5;
                                root.copyTranslation();
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                color: "transparent"
                                border.color: root.focusedControlIndex === 5 ? Appearance.colors.colPrimary : "transparent"
                                border.width: 2
                                radius: parent.buttonRadius + 2
                            }

                            StyledToolTip { text: Translation.tr("Copy Translation") }
                        }

                        RippleButton {
                            id: searchBtn
                            implicitWidth: 38
                            implicitHeight: 38
                            buttonRadius: Appearance.rounding.full
                            colBackground: pressed ? colBtnActive : (hovered ? colBtnHover : colBtn)
                            visible: root.translatedText.length > 0
                            PointingHandInteraction {}

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "travel_explore"
                                    color: colIcon
                                    iconSize: 18
                                }
                            }
                            onClicked: {
                                root.focusedControlIndex = 6;
                                root.searchWeb();
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -2
                                color: "transparent"
                                border.color: root.focusedControlIndex === 6 ? Appearance.colors.colPrimary : "transparent"
                                border.width: 2
                                radius: parent.buttonRadius + 2
                            }

                            StyledToolTip { text: Translation.tr("Search on Web") }
                        }
                    }
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog
            titleText: Translation.tr("Select Language")
            items: root.languages
            defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.showLanguageSelector = false;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    if (choiceListView.currentIndex < choiceListView.count - 1) {
                        choiceListView.currentIndex++;
                        choiceListView.positionViewAtIndex(choiceListView.currentIndex, ListView.Contain);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (choiceListView.currentIndex > 0) {
                        choiceListView.currentIndex--;
                        choiceListView.positionViewAtIndex(choiceListView.currentIndex, ListView.Contain);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    let result = choiceListView.currentIndex === -1 ? null : root.languages[choiceListView.currentIndex];
                    root.showLanguageSelector = false;
                    if (result) {
                        if (root.languageSelectorTarget) {
                            root.targetLanguage = result;
                            Config.options.language.translator.targetLanguage = result;
                        } else {
                            root.sourceLanguage = result;
                            Config.options.language.translator.sourceLanguage = result;
                        }
                        translateTimer.restart();
                    }
                    event.accepted = true;
                }
            }
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: result => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0)
                    return;

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    Config.options.language.translator.targetLanguage = result;
                } else {
                    root.sourceLanguage = result;
                    Config.options.language.translator.sourceLanguage = result;
                }

                translateTimer.restart();
            }
            Component.onCompleted: {
                forceActiveFocus();
            }
        }
    }
}

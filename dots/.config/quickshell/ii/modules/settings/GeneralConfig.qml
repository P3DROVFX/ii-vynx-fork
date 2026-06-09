import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: page
    readonly property int index: 1
    property bool register: parent.register ?? false
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    Process {
        id: pickImageProc
        command: ["bash", "-c", "FILE=$(kdialog --getopenfilename \"$HOME\" \"*.png *.jpg *.jpeg\" 2>/dev/null || zenity --file-selection --file-filter=\"Images | *.png *.jpg *.jpeg\" 2>/dev/null); if [ -n \"$FILE\" ] && [ -f \"$FILE\" ]; then cp \"$FILE\" ~/.config/quickshell/ii/assets/profile.png; echo 'success'; fi"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "success") {
                    Config.options.sidebar.dashboardHeader.profileImagePath = "file://" + Quickshell.env("HOME") + "/.config/quickshell/ii/assets/profile.png?rand=" + Math.random();
                }
            }
        }
    }

    ContentSection {
        icon: "dashboard"
        title: Translation.tr("Dashboard Header")

        ConfigRow {
            uniform: false
            ContentSubsection {
                title: Translation.tr("Profile Image")
                StyledComboBox {
                    buttonIcon: "image"
                    textRole: "displayName"
                    model: [
                        {
                            displayName: Translation.tr("Custom Image"),
                            value: "custom"
                        },
                        {
                            displayName: Translation.tr("Distro Icon"),
                            value: "distro"
                        },
                        {
                            displayName: Translation.tr("None"),
                            value: "none"
                        }
                    ]
                    currentIndex: {
                        const index = model.findIndex(item => item.value === Config.options.sidebar.dashboardHeader.profileImageType);
                        return index !== -1 ? index : 0;
                    }
                    onActivated: index => {
                        Config.options.sidebar.dashboardHeader.profileImageType = model[index].value;
                    }
                }
            }

            RippleButtonWithIcon {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignBottom
                visible: Config.options.sidebar.dashboardHeader.profileImageType === "custom"
                nerdIcon: ""
                mainText: Translation.tr("Select Image")
                onClicked: {
                    pickImageProc.running = false;
                    pickImageProc.running = true;
                }
            }
        }

        ConfigRow {
            uniform: false
            ContentSubsection {
                title: Translation.tr("Header Text")
                StyledComboBox {
                    buttonIcon: "text_fields"
                    textRole: "displayName"
                    model: [
                        {
                            displayName: Translation.tr("Username"),
                            value: "username"
                        },
                        {
                            displayName: Translation.tr("Uptime"),
                            value: "uptime"
                        },
                        {
                            displayName: Translation.tr("Custom Text"),
                            value: "custom"
                        },
                        {
                            displayName: Translation.tr("None"),
                            value: "none"
                        }
                    ]
                    currentIndex: {
                        const index = model.findIndex(item => item.value === Config.options.sidebar.dashboardHeader.textMode);
                        return index !== -1 ? index : 0;
                    }
                    onActivated: index => {
                        Config.options.sidebar.dashboardHeader.textMode = model[index].value;
                    }
                }
            }

            MaterialTextArea {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                visible: Config.options.sidebar.dashboardHeader.textMode === "custom"
                placeholderText: Translation.tr("Enter custom text")
                text: Config.options.sidebar.dashboardHeader.customText
                onTextChanged: {
                    Config.options.sidebar.dashboardHeader.customText = text;
                }
            }
        }
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max allowed increase")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: false
            ContentSubsection {
                title: Translation.tr("Battery Icon Style")
                StyledComboBox {
                    buttonIcon: "style"
                    textRole: "displayName"
                    model: [
                        {
                            displayName: Translation.tr("Windows 11"),
                            value: "windows11"
                        },
                        {
                            displayName: Translation.tr("Android 16"),
                            value: "android16"
                        },
                        {
                            displayName: Translation.tr("One UI"),
                            value: "oneui"
                        }
                    ]

                    currentIndex: {
                        const index = model.findIndex(item => item.value === Config.options.battery.style);
                        return index !== -1 ? index : 0;
                    }

                    onActivated: index => {
                        Config.options.battery.style = model[index].value;
                    }
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full warning")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {
            Layout.fillHeight: false

            ContentSubsection {
                title: Translation.tr("AI")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Weeb")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }

        ConfigRow {
            Layout.fillHeight: false

            ContentSubsection {
                title: Translation.tr("Wallpaper browser")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.policies.wallpapers
                    onSelected: newValue => {
                        Config.options.policies.wallpapers = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Translator")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.policies.translator
                    onSelected: newValue => {
                        Config.options.policies.translator = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        }
                    ]
                }
            }
        }

        ConfigRow {
            Layout.fillHeight: false

            ContentSubsection {
                title: Translation.tr("Sidebar player")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.policies.player
                    onSelected: newValue => {
                        Config.options.policies.player = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ConfigSwitch {
            buttonIcon: "today"
            text: Translation.tr("Start week on Monday")
            checked: Config.options.time.firstDayOfWeek === 0
            onCheckedChanged: {
                Config.options.time.firstDayOfWeek = checked ? 0 : 6;
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }

        ContentSubsection {
            id: worldClocksSubsection
            title: Translation.tr("World Clocks")
            tooltip: Translation.tr("Manage timezones displayed in the clock widget popup")
            Layout.fillWidth: true

            function addWorldClock() {
                let list = Config.options.time.worldClocks ? Array.from(Config.options.time.worldClocks) : [];
                list.push({ "name": "", "tz": "" });
                Config.options.time.worldClocks = list;
            }

            function removeWorldClock(index) {
                let list = Config.options.time.worldClocks ? Array.from(Config.options.time.worldClocks) : [];
                if (index >= 0 && index < list.length) {
                    list.splice(index, 1);
                    Config.options.time.worldClocks = list;
                }
            }

            function updateWorldClock(index, key, value) {
                let current = Config.options.time.worldClocks || [];
                if (index < 0 || index >= current.length) return;
                
                let list = [];
                for (let i = 0; i < current.length; i++) {
                    let item = current[i] || { "name": "", "tz": "" };
                    if (i === index) {
                        let newItem = { "name": item.name || "", "tz": item.tz || "" };
                        newItem[key] = value;
                        list.push(newItem);
                    } else {
                        list.push(item);
                    }
                }
                Config.options.time.worldClocks = list;
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: Config.options.time.worldClocks

                    ColumnLayout {
                        id: clockRow
                        Layout.fillWidth: true
                        spacing: 2

                        required property var modelData
                        required property int index
                        property bool searchFailed: false
                        property bool isSearching: false

                        Process {
                            id: tzSearchProc
                            command: ["bash", "-c", "QUERY=$(echo '" + (clockRow.modelData.name || "").replace(/'/g, "'\\''").replace(/ /g, "_") + "' | iconv -f UTF-8 -t ASCII//TRANSLIT | sed 's/[^a-zA-Z0-9_]//g'); [ -n \"$QUERY\" ] && timedatectl list-timezones | grep -i \"$QUERY\" | head -n 1 || true"]
                            property string buffer: ""
                            stdout: SplitParser {
                                onRead: data => tzSearchProc.buffer += data
                            }
                            onStarted: {
                                buffer = "";
                                clockRow.searchFailed = false;
                                clockRow.isSearching = true;
                            }
                            onExited: {
                                clockRow.isSearching = false;
                                let res = buffer.trim();
                                if (res) {
                                    worldClocksSubsection.updateWorldClock(clockRow.index, "tz", res);
                                    let prettyName = res.split("/").pop().replace(/_/g, " ");
                                    if ((clockRow.modelData.name || "") === "" || clockRow.modelData.name.toLowerCase() === prettyName.toLowerCase()) {
                                        worldClocksSubsection.updateWorldClock(clockRow.index, "name", prettyName);
                                    }
                                } else {
                                    clockRow.searchFailed = true;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialTextField {
                                id: cityField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                Layout.minimumWidth: 80
                                placeholderText: Translation.tr("City Name (e.g. Tokyo)")
                                text: clockRow.modelData.name || ""
                                wrapMode: TextEdit.NoWrap
                                onEditingFinished: {
                                    if (text !== (clockRow.modelData.name || "")) {
                                        worldClocksSubsection.updateWorldClock(clockRow.index, "name", text);
                                        if ((clockRow.modelData.tz || "") === "") {
                                            tzSearchProc.running = true;
                                        }
                                    }
                                }
                            }

                            // Timezone chip (visible when detected)
                            Rectangle {
                                visible: (clockRow.modelData.tz || "") !== "" && !clockRow.searchFailed
                                Layout.preferredHeight: 36
                                Layout.preferredWidth: Math.max(tzChipText.implicitWidth + 16, 60)
                                color: Appearance.colors.colSurfaceContainerHigh
                                radius: Appearance.rounding.full

                                StyledText {
                                    id: tzChipText
                                    anchors.centerIn: parent
                                    text: clockRow.modelData.tz || ""
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnSurfaceVariant
                                    elide: Text.ElideRight
                                    width: parent.width - 16
                                }
                            }

                            MaterialLoadingIndicator {
                                loading: true
                                visible: clockRow.isSearching
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24
                            }

                            IconToolbarButton {
                                text: "search"
                                Layout.preferredHeight: 36
                                Layout.preferredWidth: 36
                                enabled: (clockRow.modelData.tz || "") === "" && !clockRow.isSearching
                                onClicked: tzSearchProc.running = true
                                StyledToolTip { text: Translation.tr("Auto-detect Timezone from City Name") }
                            }

                            IconToolbarButton {
                                text: "delete"
                                Layout.preferredHeight: 36
                                Layout.preferredWidth: 36
                                onClicked: {
                                    worldClocksSubsection.removeWorldClock(clockRow.index);
                                }
                            }
                        }

                        // Fallback manual timezone field
                        MaterialTextField {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.minimumWidth: 80
                            visible: clockRow.searchFailed
                            placeholderText: Translation.tr("Timezone ID (e.g. Asia/Tokyo)")
                            text: clockRow.modelData.tz || ""
                            wrapMode: TextEdit.NoWrap
                            onEditingFinished: {
                                if (text !== (clockRow.modelData.tz || "")) {
                                    worldClocksSubsection.updateWorldClock(clockRow.index, "tz", text);
                                    clockRow.searchFailed = false;
                                }
                            }
                        }

                        StyledText {
                            Layout.leftMargin: 8
                            Layout.bottomMargin: 4
                            visible: clockRow.searchFailed
                            text: Translation.tr("Timezone not found for '%1'. Try a different name or enter the ID manually.").arg(clockRow.modelData.name || "")
                            color: Appearance.colors.colError
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                }

                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "add"
                    mainText: Translation.tr("Add World Clock")
                    onClicked: {
                        worldClocksSubsection.addWorldClock();
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "calendar_month"
        title: Translation.tr("Date")

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: Translation.tr("Changes the date format in the bar")

            ConfigSelectionArray {
                currentValue: Config.options.time.dateFormat
                onSelected: newValue => {
                    Config.options.time.dateFormat = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Date First dd/MM"),
                        value: "ddd dd/MM"
                    },
                    {
                        displayName: Translation.tr("Month First MM/dd"),
                        value: "ddd MM/dd"
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }
    }
}

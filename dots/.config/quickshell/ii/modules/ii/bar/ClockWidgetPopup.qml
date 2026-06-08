import qs.modules.common
import qs.modules.common.widgets
import "./cards"
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large

    property var timezoneOffsets: ({})
    property var worldClocksOption: Config.options.time.worldClocks
    onWorldClocksOptionChanged: {
        root.refreshTimezoneOffsets();
    }

    function refreshTimezoneOffsets() {
        let timezones = Config.options.time.worldClocks || [];
        if (timezones.length === 0) {
            root.timezoneOffsets = {};
            return;
        }

        let script = "";
        for (let i = 0; i < timezones.length; i++) {
            let tz = timezones[i].tz;
            if (tz) {
                let safeTz = tz.replace(/'/g, "'\\''");
                script += `TZ='${safeTz}' date +'%H:%M %z %Z ${safeTz}'; `;
            }
        }

        if (script === "") {
            root.timezoneOffsets = {};
            return;
        }

        _worldClocksProcess.offsetFetcher.command = ["bash", "-c", script];
        _worldClocksProcess.offsetFetcher.running = true;
    }

    property QtObject _worldClocksProcess: QtObject {
        property Process offsetFetcher: Process {
            stdout: StdioCollector {
                id: offsetCollector
                onStreamFinished: {
                    let lines = offsetCollector.text.split("\n");
                    let newOffsets = {};
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i].trim();
                        if (!line) continue;
                        let parts = line.split(" ");
                        if (parts.length >= 4) {
                            let timeStr = parts[0];
                            let offsetStr = parts[1];
                            let tzName = parts[2];
                            let tz = parts.slice(3).join(" ");

                            let sign = offsetStr.charAt(0) === "-" ? -1 : 1;
                            let hours = parseInt(offsetStr.substring(1, 3));
                            let mins = parseInt(offsetStr.substring(3, 5));
                            let offsetMins = sign * (hours * 60 + mins);

                            newOffsets[tz] = {
                                offsetMins: offsetMins,
                                tzName: tzName
                            };
                        }
                    }
                    root.timezoneOffsets = newOffsets;
                }
            }
        }
    }

    required property bool compact
    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "MMMM dd, dddd")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos(Todo.list)
    property bool todosEmpty: todosSection === ""
    stickyHover: true

    property bool stopwatchPaused: !TimerService.stopwatchRunning && TimerService.stopwatchTime > 0

    function getUpcomingTodos(todos) {
        const unfinishedTodos = todos.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return "";
        }

        // Limit to first 3 todos
        const limitedTodos = unfinishedTodos.slice(0, 3);
        let todoText = limitedTodos.map(function (item, index) {
            return `  • ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 3) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 3)}`;
        }

        return todoText;
    }

    function formatTimerDisplay(seconds) {
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function getDayProgressPercent() {
        const date = DateTime.clock.date
        const secondsPassed = date.getHours() * 3600 + date.getMinutes() * 60 +date.getSeconds()

        return Math.floor((secondsPassed / 86400) * 100)
    }

    function getUtcTimeForTz(tz, date) {
        try {
            const data = root.timezoneOffsets[tz];
            if (!data) return NaN;
            return date.getTime() + (data.offsetMins * 60000);
        } catch (e) {
            return NaN;
        }
    }

    function getTimezoneOffsetString(tz, date) {
        try {
            const data = root.timezoneOffsets[tz];
            if (!data) return "";

            const localOffsetMins = -date.getTimezoneOffset();
            const targetOffsetMins = data.offsetMins;

            const diffMins = targetOffsetMins - localOffsetMins;
            if (diffMins === 0) {
                return "";
            }

            const diffHrs = diffMins / 60;
            const sign = diffHrs > 0 ? "+" : "";

            if (diffMins % 60 === 0) {
                return sign + diffHrs + "h";
            }

            const hrs = Math.floor(Math.abs(diffMins) / 60);
            const mins = Math.abs(diffMins) % 60;
            return `${sign}${diffHrs < 0 ? "-" : ""}${hrs}h ${mins}m`;
        } catch (e) {
            return "";
        }
    }

    function getFormattedTime(tz, date) {
        try {
            const data = root.timezoneOffsets[tz];
            if (!data) return "--:--";

            const offsetMins = data.offsetMins;
            const targetDate = new Date(date.getTime() + (offsetMins * 60000));

            const formatStr = Config.options?.time?.format ?? "hh:mm";
            const use12h = formatStr.includes("ap") || formatStr.includes("AP");
            const showSeconds = Config.options?.time?.secondPrecision ?? false;

            let hour = targetDate.getUTCHours();
            let minute = targetDate.getUTCMinutes();
            let second = targetDate.getUTCSeconds();

            let ampm = "";
            if (use12h) {
                ampm = hour >= 12 ? (formatStr.includes("AP") ? " PM" : " pm") : (formatStr.includes("AP") ? " AM" : " am");
                hour = hour % 12 || 12;
            }

            let hrStr = String(hour).padStart(2, "0");
            let minStr = String(minute).padStart(2, "0");
            let secStr = showSeconds ? ":" + String(second).padStart(2, "0") : "";

            return hrStr + ":" + minStr + secStr + ampm;
        } catch (e) {
            return "--:--";
        }
    }

    function getFormattedDate(tz, date) {
        try {
            const data = root.timezoneOffsets[tz];
            if (!data) return "";

            const offsetMins = data.offsetMins;
            const targetDate = new Date(date.getTime() + (offsetMins * 60000));

            const dateFormatStr = Config.options?.time?.dateFormat ?? "ddd dd/MM";
            const showMonthFirst = dateFormatStr.includes("MM/dd");

            const days = [Translation.tr("Sun"), Translation.tr("Mon"), Translation.tr("Tue"), Translation.tr("Wed"), Translation.tr("Thu"), Translation.tr("Fri"), Translation.tr("Sat")];
            const weekday = days[targetDate.getUTCDay()];

            const day = String(targetDate.getUTCDate()).padStart(2, "0");
            const month = String(targetDate.getUTCMonth() + 1).padStart(2, "0");

            if (showMonthFirst) {
                return `${weekday} ${month}/${day}`;
            } else {
                return `${weekday} ${day}/${month}`;
            }
        } catch (e) {
            return "";
        }
    }

    contentItem: ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 12

        HeroCard {
            id: clockHero
            icon: "schedule"
            adaptiveWidth: true

            title: root.formattedTime
            subtitle: root.formattedDate

            pillText: getDayProgressPercent() + "%"
            pillIcon: "clock_loader_60"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            InfoPill {
                visible: !root.compact ? LocalSend.currentTransfer == null || LocalSend.droppedFiles.length > 0 : false
                text: root.formattedUptime

                shapeContent: CustomIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnSecondary
                }
            }

            InfoPill {
                visible: !root.compact ? LocalSend.currentTransfer == null || LocalSend.droppedFiles.length > 0 : false
                textContent: Loader {
                    anchors.centerIn: parent
                    sourceComponent: TimerService.pomodoroRunning ? pomodoroText : (TimerService.stopwatchTime > 0 ? stopwatchText : timerOffText)
                }
                
                containerColor: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainer : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer)
                color: containerColor
                shapeColor: TimerService.pomodoroBreak ? Appearance.colors.colTertiary : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colPrimary : Appearance.colors.colSecondary)
                symbolColor: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiary : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondary)
                textColor: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiaryContainer : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer)
                icon: TimerService.pomodoroBreak ? "coffee" : root.stopwatchPaused ? "timer_pause" : TimerService.stopwatchRunning ? "timer_play" : "timer"
            }

            LocalSendPill {
                visible: LocalSend.available
            }
        }

        Component {
            id: timerOffText
            StyledText {
                text: Translation.tr("Timer Off")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Bold
            }
        }

        Component {
            id: pomodoroText
            StyledText {
                visible: TimerService.pomodoroRunning
                text: root.formatTimerDisplay(TimerService.pomodoroSecondsLeft)
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Bold
            }
        }

        Component {
            id: stopwatchText
            RowLayout {
                id: textLayout
                visible: TimerService.stopwatchTime > 0
                width: 70 // To prevent shakiness
                anchors.centerIn: parent
                spacing: 0

                SequentialAnimation {
                    running: root.stopwatchPaused
                    loops: Animation.Infinite

                    ScriptAction { script: textLayout.visible = true }
                    PauseAnimation { duration: 700 }
                    ScriptAction { script: textLayout.visible = false }
                    PauseAnimation { duration: 700 }

                    onStopped: {
                        if (TimerService.stopwatchTime <= 0) return
                        textLayout.visible = true
                    }
                }

                StyledText {
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.family: Appearance.font.family.title
                    font.weight: Font.Bold

                    text: {
                        let totalSeconds = Math.floor(TimerService.stopwatchTime) / 100
                        let minutes = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
                        let seconds = Math.floor(totalSeconds % 60).toString().padStart(2, '0')
                        return `${minutes}:${seconds}`
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.family: Appearance.font.family.title
                    font.weight: Font.Bold

                    text: {
                        return `:<sub>${(Math.floor(TimerService.stopwatchTime) % 100).toString().padStart(2, '0')}</sub>`
                    }
                }
            }
        }

        Loader {
            id: worldClocksLoader
            Layout.fillWidth: true
            visible: active
            active: Config.options.time.worldClocks && Config.options.time.worldClocks.length > 0
            sourceComponent: worldClocksComponent
        }

        Loader {
            Layout.fillWidth: true
            visible: active
            active: root.compact ? sourceComponent !== todoSection : true
            sourceComponent: LocalSend.currentTransfer !== null ? transferCard : LocalSend.droppedFiles.length > 0 ? sendCard : todoSection
        }

        Component {
            id: todoSection
            SectionCard {
                title: Translation.tr("To-Do Tasks")
                icon: "checklist"
                subtitle: root.todosSection

                LoadingPlaceholder {
                    Layout.preferredHeight: 30
                    visible: root.todosEmpty
                    loading: false
                    emptyText: Translation.tr("No pending tasks")
                }
            }
        }

        Component {
            id: worldClocksComponent
            SectionCard {
                title: Translation.tr("World Clocks")
                icon: "public"
                showDivider: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: Config.options.time.worldClocks

                        RowLayout {
                            id: clockRow
                            Layout.fillWidth: true
                            spacing: 12

                            required property var modelData
                            required property int index

                            ColumnLayout {
                                spacing: 2

                                StyledText {
                                    text: clockRow.modelData.name || clockRow.modelData.tz || Translation.tr("Unnamed")
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                }

                                StyledText {
                                    text: {
                                        let offset = root.getTimezoneOffsetString(clockRow.modelData.tz, DateTime.clock.date);
                                        if (offset === "") {
                                            return Translation.tr("Same time");
                                        }
                                        return offset + " " + Translation.tr("relative to local");
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                StyledText {
                                    text: root.getFormattedTime(clockRow.modelData.tz, DateTime.clock.date)
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                    Layout.alignment: Qt.AlignRight
                                }

                                StyledText {
                                    text: root.getFormattedDate(clockRow.modelData.tz, DateTime.clock.date)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            MaterialSymbol {
                                text: {
                                    try {
                                        const targetUtc = root.getUtcTimeForTz(clockRow.modelData.tz, DateTime.clock.date);
                                        if (isNaN(targetUtc)) {
                                            return "question_mark";
                                        }
                                        const targetDate = new Date(targetUtc);
                                        const hour = targetDate.getUTCHours();
                                        return (hour < 6 || hour >= 18) ? "dark_mode" : "light_mode";
                                    } catch (e) {
                                        return "question_mark";
                                    }
                                }
                                iconSize: 20
                                color: text === "light_mode" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: transferCard
            LocalSendTransferCard {}
        }

        Component {
            id: sendCard
            LocalSendSendCard {}
        }
    }
}
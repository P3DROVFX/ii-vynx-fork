pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell

Singleton {
    id: root

    property bool automatic: Config.options?.light?.darkMode?.automatic ?? false
    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes

    onAutomaticChanged: {
        if (automatic) {
            checkTime();
        }
    }

    onClockHourChanged: {
        if (automatic) {
            checkTime();
        }
    }

    Component.onCompleted: {
        if (automatic) {
            checkTime();
        }
    }

    function checkTime() {
        if (!automatic)
            return;
        if (clockHour >= 18 || clockHour < 6) {
            enableDarkMode();
        } else {
            disableDarkMode();
        }
    }

    function enableDarkMode() {
        if (!Appearance.m3colors.darkmode) {
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
        }
    }

    function disableDarkMode() {
        if (Appearance.m3colors.darkmode) {
            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
        }
    }
}

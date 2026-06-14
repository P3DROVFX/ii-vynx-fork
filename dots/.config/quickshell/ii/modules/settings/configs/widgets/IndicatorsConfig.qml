import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: false

    signal goBack()

    RowLayout {
        spacing: 12

        RippleButton {
            implicitWidth: implicitHeight
            implicitHeight: 40
            topLeftRadius: Appearance.rounding.full
            topRightRadius: Appearance.rounding.full
            bottomLeftRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive

            MaterialSymbol {
                anchors.centerIn: parent
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSecondaryContainer
            }

            onClicked: root.goBack()
        }

        StyledText {
            text: Translation.tr("Indicators & Timers")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer0
        }
    }

    ContentSection {
        icon: "timer"
        title: Translation.tr("Indicators & Timers")

        ConfigSwitch {
            buttonIcon: "timer"
            text: Translation.tr("Show stopwatch")
            checked: Config.options.bar.timers.showStopwatch
            onCheckedChanged: {
                Config.options.bar.timers.showStopwatch = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "search_activity"
            text: Translation.tr("Show pomodoro")
            checked: Config.options.bar.timers.showPomodoro
            onCheckedChanged: {
                Config.options.bar.timers.showPomodoro = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "check_indeterminate_small"
            text: Translation.tr("Record - Minimal mode")
            checked: Config.options.bar.indicators.record.minimal
            onCheckedChanged: {
                Config.options.bar.indicators.record.minimal = checked;
            }
        }
    }
}

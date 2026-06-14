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
            text: Translation.tr("Resources Tracker")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer0
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Resources Tracker")

        ConfigSwitch {
            buttonIcon: "percent"
            text: Translation.tr("Show percentage text")
            checked: Config.options.bar.resources.showPercentageText
            onCheckedChanged: {
                Config.options.bar.resources.showPercentageText = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "memory"
            text: Translation.tr("Always show RAM")
            checked: Config.options.bar.resources.alwaysShowRam
            onCheckedChanged: Config.options.bar.resources.alwaysShowRam = checked
        }
        ConfigSwitch {
            buttonIcon: "planner_review"
            text: Translation.tr("Always show CPU")
            checked: Config.options.bar.resources.alwaysShowCpu
            onCheckedChanged: Config.options.bar.resources.alwaysShowCpu = checked
        }
        ConfigSwitch {
            buttonIcon: "thermostat"
            text: Translation.tr("Always show Temp")
            checked: Config.options.bar.resources.alwaysShowCpuTemp
            onCheckedChanged: Config.options.bar.resources.alwaysShowCpuTemp = checked
        }
        ConfigSwitch {
            buttonIcon: "hard_drive"
            text: Translation.tr("Always show Disk")
            checked: Config.options.bar.resources.alwaysShowDisk
            onCheckedChanged: Config.options.bar.resources.alwaysShowDisk = checked
        }
        ConfigSwitch {
            buttonIcon: "swap_horiz"
            text: Translation.tr("Always show Swap")
            checked: Config.options.bar.resources.alwaysShowSwap
            onCheckedChanged: Config.options.bar.resources.alwaysShowSwap = checked
        }
        ConfigSwitch {
            buttonIcon: "dns"
            text: Translation.tr("Always show Docker")
            checked: Config.options.bar.resources.showDocker
            onCheckedChanged: Config.options.bar.resources.showDocker = checked
        }
    }
}

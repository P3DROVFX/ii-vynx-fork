import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool vertical: false
    implicitWidth: rowLayout.implicitWidth + 10
    implicitHeight: Appearance.sizes.baseBarHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        spacing: 0
        anchors.centerIn: parent

        Resource {
            iconName: "memory"
            shown: Config.options.bar.resources.alwaysShowRam
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            shown: Config.options.bar.resources.alwaysShowCpu
            percentage: ResourceUsage.cpuUsage
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "thermostat"
            shown: Config.options.bar.resources.alwaysShowCpuTemp
            percentage: ResourceUsage.cpuTemp / 100
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "hard_drive"
            shown: Config.options.bar.resources.alwaysShowDisk
            percentage: ResourceUsage.diskUsedPercentage
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "swap_horiz"
            shown: Config.options.bar.resources.alwaysShowSwap
            percentage: ResourceUsage.swapUsedPercentage
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }
    }

    Loader {
        active: Config.options.bar.resources.expressivePopup
        source: "ExpressiveResourcesPopup.qml"
        onLoaded: item.hoverTarget = root
    }

    Loader {
        active: !Config.options.bar.resources.expressivePopup
        source: "ResourcesPopup.qml"
        onLoaded: item.hoverTarget = root
    }
}

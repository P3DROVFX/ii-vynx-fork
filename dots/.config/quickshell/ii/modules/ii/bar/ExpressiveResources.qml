import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool vertical: false
    property bool alwaysShowAllResources: false
    property bool isMaterial: true // Forced expressive

    implicitWidth: vertical ? (mainCol.implicitWidth) : (mainRow.implicitWidth)
    implicitHeight: vertical ? (mainCol.implicitHeight) : (mainRow.implicitHeight)
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    // ── Horizontal Layout ──────────────────────────────────────────────
    RowLayout {
        id: mainRow
        visible: !root.vertical
        spacing: 8
        anchors.centerIn: parent

        // 1. Resources Capsule
        Rectangle {
            id: resourcesCapsule
            implicitWidth: rowLayout.implicitWidth + 12
            implicitHeight: Appearance.sizes.baseBarHeight - 8
            color: Appearance.colors.colTertiaryContainer
            radius: Config.options.bar.barGroupStyle === 1 ? Appearance.rounding.windowRounding : Appearance.rounding.full

            RowLayout {
                id: rowLayout
                spacing: 0
                anchors.centerIn: parent

                Resource {
                    iconName: "memory"
                    shown: Config.options.bar.resources.alwaysShowRam
                    percentage: ResourceUsage.memoryUsedPercentage
                    warningThreshold: Config.options.bar.resources.memoryWarningThreshold
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    iconName: "planner_review"
                    shown: Config.options.bar.resources.alwaysShowCpu
                    percentage: ResourceUsage.cpuUsage
                    Layout.leftMargin: shown ? 6 : 0
                    warningThreshold: Config.options.bar.resources.cpuWarningThreshold
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    iconName: "thermostat"
                    shown: Config.options.bar.resources.alwaysShowCpuTemp
                    percentage: ResourceUsage.cpuTemp / 100
                    Layout.leftMargin: shown ? 6 : 0
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    iconName: "hard_drive"
                    shown: Config.options.bar.resources.alwaysShowDisk
                    percentage: ResourceUsage.diskUsedPercentage
                    Layout.leftMargin: shown ? 6 : 0
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    iconName: "swap_horiz"
                    shown: Config.options.bar.resources.alwaysShowSwap
                    percentage: ResourceUsage.swapUsedPercentage
                    Layout.leftMargin: shown ? 6 : 0
                    warningThreshold: Config.options.bar.resources.swapWarningThreshold
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
            }
        }

        // 2. Standalone Docker Capsule
        Rectangle {
            id: dockerCapsule
            property bool shown: Config.options.bar.resources.showDocker
            visible: shown
            clip: true
            implicitWidth: shown ? (dockerRow.implicitWidth + 16) : 0
            implicitHeight: Appearance.sizes.baseBarHeight - 8
            color: Appearance.colors.colTertiaryContainer
            radius: Config.options.bar.barGroupStyle === 1 ? Appearance.rounding.windowRounding : Appearance.rounding.full

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                }
            }

            RowLayout {
                id: dockerRow
                spacing: 6
                anchors.centerIn: parent

                CustomIcon {
                    source: "docker.svg"
                    width: 18
                    height: 18
                    colorize: true
                    color: Appearance.colors.colOnTertiaryContainer
                }

                StyledText {
                    text: DockerService.runningCount.toString()
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnTertiaryContainer
                }
            }
        }
    }

    // ── Vertical Layout ────────────────────────────────────────────────
    ColumnLayout {
        id: mainCol
        visible: root.vertical
        spacing: 6
        anchors.centerIn: parent

        // 1. Resources Column Capsule
        Rectangle {
            implicitWidth: Appearance.sizes.verticalBarWidth - 8
            implicitHeight: colLayout.implicitHeight + 10
            color: Appearance.colors.colTertiaryContainer
            radius: Config.options.bar.barGroupStyle === 1 ? Appearance.rounding.windowRounding : Appearance.rounding.full

            ColumnLayout {
                id: colLayout
                spacing: 6
                anchors.centerIn: parent
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "memory"
                    shown: Config.options.bar.resources.alwaysShowRam
                    percentage: ResourceUsage.memoryUsedPercentage
                    warningThreshold: Config.options.bar.resources.memoryWarningThreshold
                    implicitHeight: 24
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "planner_review"
                    shown: Config.options.bar.resources.alwaysShowCpu
                    percentage: ResourceUsage.cpuUsage
                    warningThreshold: Config.options.bar.resources.cpuWarningThreshold
                    implicitHeight: 24
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "thermostat"
                    shown: Config.options.bar.resources.alwaysShowCpuTemp
                    percentage: ResourceUsage.cpuTemp / 100
                    implicitHeight: 24
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "hard_drive"
                    shown: Config.options.bar.resources.alwaysShowDisk
                    percentage: ResourceUsage.diskUsedPercentage
                    implicitHeight: 24
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
                Resource {
                    Layout.alignment: Qt.AlignHCenter
                    iconName: "swap_horiz"
                    shown: Config.options.bar.resources.alwaysShowSwap
                    percentage: ResourceUsage.swapUsedPercentage
                    warningThreshold: Config.options.bar.resources.swapWarningThreshold
                    implicitHeight: 24
                    colorActive: Appearance.colors.colOnTertiaryContainer
                    colorIcon: Appearance.colors.colOnTertiaryContainer
                    colorText: Appearance.colors.colOnTertiaryContainer
                }
            }
        }

        // 2. Standalone Docker Vertical Capsule
        Rectangle {
            id: dockerCapsuleCol
            property bool shown: Config.options.bar.resources.showDocker
            visible: shown
            clip: true
            implicitWidth: Appearance.sizes.verticalBarWidth - 8
            implicitHeight: shown ? 40 : 0
            color: Appearance.colors.colTertiaryContainer
            radius: Config.options.bar.barGroupStyle === 1 ? Appearance.rounding.windowRounding : Appearance.rounding.full

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                }
            }

            ColumnLayout {
                spacing: 2
                anchors.centerIn: parent

                CustomIcon {
                    Layout.alignment: Qt.AlignHCenter
                    source: "docker.svg"
                    width: 18
                    height: 18
                    colorize: true
                    color: Appearance.colors.colOnTertiaryContainer
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: DockerService.runningCount.toString()
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnTertiaryContainer
                }
            }
        }
    }

    Loader {
        active: true
        source: "ExpressiveResourcesPopup.qml"
        onLoaded: {
            item.hoverTarget = root;
            item.activeChanged.connect(() => {
                if (item.active) {
                    DockerService.refreshForPopup();
                }
            });
        }
    }
}

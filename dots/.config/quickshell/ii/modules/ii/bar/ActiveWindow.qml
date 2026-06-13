import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    property bool vertical: false
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    readonly property bool isFixedSize: Config.options.bar.activeWindow.fixedSize

    readonly property int maxSize: 350
    property int popupWidth: 350
    property int maxPopupWidth: 600
    readonly property int fixedSize: root.vertical ? 150 : 225

    property string appClassText: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.appId : (root.biggestWindow?.class) ?? Translation.tr("Desktop")

    property string appTitleText: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.title : (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`

    implicitHeight: isFixedSize ? fixedSize : (root.vertical ? Math.max(classText.implicitWidth, titleText.implicitWidth) + 20 : colLayout.implicitHeight)
    implicitWidth: isFixedSize ? fixedSize : Math.min(Math.max(classText.implicitWidth, titleText.implicitWidth) + 20, maxSize)
    clip: true

    property bool containsMouse: mouseArea.containsMouse

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    StyledPopup {
        id: titlePopup
        hoverTarget: root
        stickyHover: true
        active: (stickyHover ? _stickyActive : (hoverTarget && hoverTarget.containsMouse)) && !root.vertical && root.appTitleText !== ""

        ColumnLayout {
            spacing: 12

            StyledPopupHeaderRow {
                Layout.leftMargin: 12
                icon: "desktop_windows"
                label: Translation.tr("Active Window")
            }

            Rectangle {
                Layout.preferredWidth: Math.max(root.popupWidth, Math.min(root.maxPopupWidth, popupText.implicitWidth + 32))
                Layout.preferredHeight: contentCol.implicitHeight + 32
                radius: Appearance.rounding.normal
                color: Appearance.colors.colSurfaceContainerHigh

                ColumnLayout {
                    id: contentCol
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 12

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            color: Appearance.colors.colPrimaryContainer
                            radius: Appearance.rounding.verysmall
                            implicitWidth: appNameText.implicitWidth + 16
                            implicitHeight: appNameText.implicitHeight + 8
                            
                            StyledText {
                                id: appNameText
                                anchors.centerIn: parent
                                text: root.appClassText
                                font.weight: Font.Bold
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: root.activeWindowAddress
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.family: Appearance.font.family.numbers
                            color: Appearance.colors.colSubtext
                            visible: root.activeWindowAddress !== "0xundefined"
                        }
                    }

                    StyledText {
                        id: popupText
                        Layout.fillWidth: true
                        text: root.appTitleText
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurface
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.colors.colLayer0Border
                    }

                    RowLayout {
                        spacing: 6
                        
                        MaterialSymbol {
                            text: "computer"
                            iconSize: 14
                            color: Appearance.colors.colSubtext
                        }
                        
                        StyledText {
                            text: root.monitor?.name ?? "Unknown"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: "•"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        MaterialSymbol {
                            text: "grid_view"
                            iconSize: 14
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: `${Translation.tr("Workspace")} ${root.monitor?.activeWorkspace?.id ?? 1}`
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }

    Behavior on implicitWidth {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    ColumnLayout {
        visible: true
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -4

        width: root.vertical ? implicitWidth : root.width
        height: root.vertical ? root.height : implicitHeight

        StyledText {
            id: classText
            Layout.leftMargin: 6
            visible: !root.vertical
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.appClassText
        }

        StyledText {
            id: titleText
            Layout.leftMargin: root.vertical ? 0 : 6
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            rotation: root.vertical ? 90 : 0
            text: root.vertical ? root.appClassText : root.appTitleText
        }
    }
}
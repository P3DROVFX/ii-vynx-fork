import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import qs.modules.common.functions
import "./widgets"

Item {
    id: root

    property bool isVertical: false

    readonly property real buttonSize: Appearance.sizes.dockButtonSize
    readonly property real dotMargin: (Config.options?.dock.height ?? 60) * 0.2
    readonly property real slotSize: buttonSize + dotMargin * 2
    readonly property real fixedSlots: isVertical ? 2.5 : 3
    readonly property real fixedLength: fixedSlots * slotSize

    readonly property real artSize: Math.round(buttonSize * 0.8)
    readonly property real artInner: artSize

    readonly property real controlSize: Math.round(buttonSize * 0.68)

    readonly property int textSizeL: Math.round(buttonSize * (isVertical ? 0.24 : 0.26))
    readonly property int textSizeS: Math.round(buttonSize * (isVertical ? 0.20 : 0.22))
    readonly property int marqueeRunningThreshold: isVertical ? 10 : 14

    implicitWidth: isVertical ? slotSize : fixedLength
    implicitHeight: isVertical ? buttonSize + dotMargin * 1.3 : slotSize

    readonly property MprisPlayer currentPlayer: MprisController.activePlayer
    readonly property bool isPlaying: currentPlayer?.isPlaying ?? false

    readonly property string finalTitle: StringUtils.cleanMusicTitle(currentPlayer?.trackTitle) || Translation.tr("Unknown Title")
    readonly property string finalArtist: currentPlayer?.trackArtist || Translation.tr("Unknown Artist")
    readonly property string finalArtUrl: MprisController.artUrl

    property bool mediaHovered: false

    Rectangle {
        id: bgRect
        anchors.fill: parent
        anchors.margins: root.dotMargin
        color: Appearance.colors.colSurfaceContainerHighest
        radius: Appearance.rounding.normal
    }

    MouseArea {
        id: mediaMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton

        onEntered: root.mediaHovered = true
        onExited: root.mediaHovered = false

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton || mouse.button === Qt.LeftButton) {
                root.currentPlayer?.togglePlaying();
            } else if (mouse.button === Qt.RightButton) {
                root.currentPlayer?.next();
            } else if (mouse.button === Qt.BackButton) {
                root.currentPlayer?.previous();
            } else if (mouse.button === Qt.ForwardButton) {
                root.currentPlayer?.next();
            }
        }
    }

    component ArtworkItem: Item {
        width: root.artSize
        height: root.artSize

        Rectangle {
            id: artRect
            anchors.centerIn: parent
            width: root.artInner
            height: root.artInner
            radius: Appearance.rounding.small
            color: Appearance.colors.colPrimaryContainer

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: artRect.width
                    height: artRect.height
                    radius: Appearance.rounding.small
                }
            }

            Image {
                id: artImg
                anchors.fill: parent
                source: root.finalArtUrl
                fillMode: Image.PreserveAspectCrop
                cache: true
                antialiasing: true
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        MaterialSymbol {
            anchors.centerIn: artRect
            visible: artImg.status !== Image.Ready
            text: "music_note"
            iconSize: root.artInner * 0.48
            color: Appearance.colors.colPrimary
        }
    }

    Loader {
        active: !root.isVertical
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent

            ArtworkItem {
                id: artH
                anchors.left: parent.left
                anchors.leftMargin: root.dotMargin + 6
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: playPauseBtn
                anchors.right: parent.right
                anchors.rightMargin: root.dotMargin + 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.buttonSize * 0.65
                height: root.buttonSize * 0.65
                radius: root.isPlaying ? Appearance.rounding.small : width / 2
                color: Appearance.colors.colPrimary
                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "pause" : "play_arrow"
                    color: Appearance.m3colors.m3onPrimary
                    fill: root.isPlaying ? 1.0 : 0.0
                    iconSize: parent.height * 0.55
                }
            }

            ColumnLayout {
                anchors.left: artH.right
                anchors.right: playPauseBtn.left
                anchors.leftMargin: root.dotMargin * 0.6
                anchors.rightMargin: root.dotMargin * 0.6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Item {
                    Layout.fillWidth: true
                    implicitHeight: titleH.implicitHeight
                    clip: true
                    MarqueeText {
                        id: titleH
                        width: parent.width
                        text: root.finalTitle
                        fontSize: root.textSizeL
                        fontWeight: Font.DemiBold
                        textColor: Appearance.colors.colOnLayer0
                        running: root.mediaHovered && text.length > root.marqueeRunningThreshold
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: artistH.implicitHeight
                    clip: true
                    StyledText {
                        id: artistH
                        width: parent.width
                        text: root.finalArtist
                        font.pixelSize: root.textSizeS
                        font.weight: Font.Normal
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }

    Loader {
        active: root.isVertical
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent

            ArtworkItem {
                id: artV
                anchors.top: parent.top
                anchors.topMargin: root.dotMargin + 6
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    DockTooltip {
        id: mediaTooltip
        parentItem: root
        text: root.finalTitle + " - " + root.finalArtist
        showTooltip: root.mediaHovered
        tooltipOffset: -root.dotMargin * 0.5
    }
}

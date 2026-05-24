import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 10
    implicitHeight: Appearance.sizes.baseBarHeight
    property color colText: dropArea.containsDrag ? Appearance.colors.colPrimary : rootItem.highlighted ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: root.colText
            text: DateTime.time
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.colText
            text: "•"
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.colText
            text: DateTime.longDate
        }

        // LocalSend files attached chip
        Rectangle {
            id: attachedChip
            visible: LocalSend.droppedFiles.length > 0
            implicitWidth: chipRow.implicitWidth + 12
            implicitHeight: 20
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimaryContainer
            border.width: 1
            border.color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4

            scale: visible ? 1.0 : 0.0
            Behavior on scale {
                NumberAnimation { duration: 250; easing.type: Easing.OutBack }
            }

            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: 3
                
                MaterialSymbol {
                    text: "attach_file"
                    iconSize: 12
                    color: Appearance.colors.colOnPrimaryContainer
                }
                
                StyledText {
                    text: LocalSend.droppedFiles.length
                    font.pixelSize: 10
                    font.weight: Font.Black
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: (drop) => {
            if (!drop.hasUrls) return
            for (let i = 0; i < drop.urls.length; i++)
                LocalSend.addDroppedFile(drop.urls[i])
            drop.accept(Qt.CopyAction)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            compact: Config.options.bar.tooltips.compactPopups
            hoverTarget: mouseArea
        }
    }

    // Drag & Drop visual overlay feedback
    Rectangle {
        id: dropOverlay
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colPrimaryContainer
        border.width: 1.5
        border.color: Appearance.colors.colPrimary
        visible: opacity > 0
        opacity: dropArea.containsDrag ? 0.95 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: "download"
                iconSize: 14
                color: Appearance.colors.colOnPrimaryContainer
                
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: dropArea.containsDrag
                    NumberAnimation { from: 1.0; to: 1.25; duration: 500; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.25; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                }
            }

            StyledText {
                text: Translation.tr("Drop")
                font.pixelSize: 10
                font.weight: Font.Black
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
    }
}
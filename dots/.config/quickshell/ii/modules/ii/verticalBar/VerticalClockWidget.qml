import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

Item {
    id: root
    implicitHeight: clockColumn.implicitHeight + 10
    implicitWidth: Appearance.sizes.verticalBarWidth
    ColumnLayout {
        id: clockColumn
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: DateTime.time.split(/[: ]/)
            delegate: StyledText {
                required property string modelData
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: modelData.match(/am|pm/i) ? 
                    Appearance.font.pixelSize.smaller // Smaller "am"/"pm" text
                    : Appearance.font.pixelSize.large
                color: dropArea.containsDrag ? Appearance.colors.colPrimary : rootItem.highlighted ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                text: modelData.padStart(2, "0")
            }
        }

        // LocalSend files attached chip
        Rectangle {
            id: attachedChip
            visible: LocalSend.droppedFiles.length > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            implicitWidth: chipRow.implicitWidth + 12
            implicitHeight: 20
            radius: Appearance.rounding.full
            color: Appearance.colors.colPrimaryContainer
            border.width: 1
            border.color: Appearance.colors.colPrimary

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

        Bar.ClockWidgetPopup {
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

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
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
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Drop")
                font.pixelSize: 9
                font.weight: Font.Black
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
    }
}

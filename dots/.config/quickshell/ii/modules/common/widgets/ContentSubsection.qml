import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property string title: ""
    property string tooltip: ""
    property string icon: ""
    default property alias contentData: sectionContent.data

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 16

    color: Appearance.colors.colLayer2Base

    readonly property int itemIndex: {
        var p = parent;
        if (!p)
            return 0;
        var idx = 0;
        for (var i = 0; i < p.children.length; ++i) {
            if (p.children[i] === root)
                return idx;
            if (p.children[i].visible && typeof p.children[i].topLeftRadius !== "undefined")
                idx++;
        }
        return 0;
    }

    readonly property int totalItems: {
        var p = parent;
        if (!p)
            return 1;
        var count = 0;
        for (var i = 0; i < p.children.length; ++i) {
            if (p.children[i].visible && typeof p.children[i].topLeftRadius !== "undefined")
                count++;
        }
        return count;
    }

    property bool isFirst: itemIndex === 0
    property bool isLast: itemIndex === totalItems - 1

    topLeftRadius: isFirst ? Appearance.rounding.large : Appearance.rounding.verysmall
    topRightRadius: isFirst ? Appearance.rounding.large : Appearance.rounding.verysmall
    bottomLeftRadius: isLast ? Appearance.rounding.large : Appearance.rounding.verysmall
    bottomRightRadius: isLast ? Appearance.rounding.large : Appearance.rounding.verysmall

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Loader {
                active: root.icon && root.icon.length > 0
                visible: active
                Layout.alignment: Qt.AlignVCenter
                opacity: root.enabled ? 1 : 0.4

                sourceComponent: MaterialSymbol {
                    text: root.icon
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }

            ContentSubsectionLabel {
                opacity: 1 - highlightOverlay.opacity
                visible: root.title && root.title.length > 0
                text: root.title
                Layout.fillWidth: true
                color: Appearance.colors.colOnLayer2
            }

            MaterialSymbol {
                opacity: 1 - highlightOverlay.opacity
                visible: root.tooltip && root.tooltip.length > 0
                text: "info"
                iconSize: Appearance.font.pixelSize.large

                color: Appearance.colors.colSubtext
                MouseArea {
                    id: infoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.WhatsThisCursor
                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: infoMouseArea.containsMouse
                        text: root.tooltip
                    }
                }
            }
        }

        ColumnLayout {
            id: sectionContent
            Layout.fillWidth: true
            spacing: 2
        }
    }

    HighlightOverlay {
        id: highlightOverlay
        anchors.fill: parent
        radius: Math.max(root.topLeftRadius, root.bottomLeftRadius)
        visible: false
    }
}

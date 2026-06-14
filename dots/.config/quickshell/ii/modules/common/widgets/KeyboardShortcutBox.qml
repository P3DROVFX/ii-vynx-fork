import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: "Action description"
    property list<string> keys: ["Super", "W"]

    readonly property int itemIndex: {
        var p = parent;
        if (!p) return 0;
        var idx = 0;
        for (var i = 0; i < p.children.length; ++i) {
            if (p.children[i] === root) return idx;
            if (p.children[i].visible && typeof p.children[i].topLeftRadius !== "undefined") idx++;
        }
        return 0;
    }

    readonly property int totalItems: {
        var p = parent;
        if (!p) return 1;
        var count = 0;
        for (var i = 0; i < p.children.length; ++i) {
            if (p.children[i].visible && typeof p.children[i].topLeftRadius !== "undefined") count++;
        }
        return count;
    }

    property bool isFirst: itemIndex === 0
    property bool isLast: itemIndex === totalItems - 1

    topLeftRadius: isFirst ? Appearance.rounding.large : Appearance.rounding.verysmall
    topRightRadius: isFirst ? Appearance.rounding.large : Appearance.rounding.verysmall
    bottomLeftRadius: isLast ? Appearance.rounding.large : Appearance.rounding.verysmall
    bottomRightRadius: isLast ? Appearance.rounding.large : Appearance.rounding.verysmall

    color: Appearance.colors.colSurfaceContainer
    implicitWidth: mainRowLayout.implicitWidth + mainRowLayout.anchors.margins * 2
    implicitHeight: mainRowLayout.implicitHeight + mainRowLayout.anchors.margins * 2

    RowLayout {
        id: mainRowLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        RowLayout {
            spacing: 6
            Repeater {
                model: root.keys
                delegate: RowLayout {
                    spacing: 6
                    
                    Rectangle {
                        implicitWidth: keyText.implicitWidth + 16
                        implicitHeight: keyText.implicitHeight + 8
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colSurfaceContainerHigh
                        border.color: Appearance.colors.colOutlineVariant
                        border.width: 1

                        StyledText {
                            id: keyText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurface
                        }
                    }

                    StyledText {
                        visible: index < root.keys.length - 1
                        text: "+"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSurfaceVariant
            wrapMode: Text.WordWrap
        }
    }
}

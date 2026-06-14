import qs.modules.common.widgets
import qs.modules.common
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property real iconSize: 18
    property Component extraComponent: null

    Layout.fillWidth: true
    implicitHeight: contentLayout.implicitHeight + 32
    font.pixelSize: Appearance.font.pixelSize.small

    onClicked: checked = !checked

    property color normalColor: Appearance.colors.colLayer2Base
    property color highlightColor: Appearance.colors.colSecondaryContainer

    colBackground: normalColor
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active

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

    HighlightOverlay {
        id: highlightOverlay
        anchors.fill: parent
        radius: root.buttonEffectiveRadius
        color: root.highlightColor
    }

    contentItem: Item {
        anchors.fill: parent

        RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Loader {
                active: root.buttonIcon && root.buttonIcon.length > 0
                visible: active
                Layout.alignment: Qt.AlignVCenter
                opacity: root.enabled ? 1 : 0.4

                sourceComponent: MaterialShapeWrappedMaterialSymbol {
                    id: iconWidget
                    text: root.buttonIcon
                    shape: root.checked ? MaterialShape.Shape.Cookie4Sided : MaterialShape.Shape.Circle
                    iconSize: 18
                    padding: 6
                    fill: root.checked ? 1 : 0
                    color: root.checked ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3
                    colSymbol: root.checked ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer3
                }
            }

            StyledText {
                id: labelWidget
                Layout.fillWidth: true
                text: root.text
                font.pixelSize: root.font.pixelSize
                color: Appearance.colors.colOnLayer2
                opacity: root.enabled ? 1 : 0.4
                wrapMode: Text.WordWrap
            }

            Loader {
                active: root.extraComponent !== null
                visible: active
                sourceComponent: root.extraComponent
                Layout.alignment: Qt.AlignVCenter
            }

            StyledSwitch {
                id: switchWidget
                down: root.down
                Layout.fillWidth: false
                checked: root.checked
                onClicked: root.clicked()
            }
        }
    }
}

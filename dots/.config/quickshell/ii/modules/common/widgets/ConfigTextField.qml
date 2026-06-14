import qs.modules.common.widgets
import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property string tooltip: ""
    
    // TextField properties
    property alias placeholderText: textFieldWidget.placeholderText
    property alias inputText: textFieldWidget.text
    property alias textField: textFieldWidget
    
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 32

    color: Appearance.colors.colLayer2Base

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

    HighlightOverlay {
        id: highlightOverlay
        anchors.fill: parent
        radius: Math.max(root.topLeftRadius, root.bottomLeftRadius)
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Loader {
                active: root.icon && root.icon.length > 0
                visible: active
                Layout.alignment: Qt.AlignVCenter
                opacity: root.enabled ? 1 : 0.4
                
                sourceComponent: MaterialShapeWrappedMaterialSymbol {
                    text: root.icon
                    shape: textFieldWidget.activeFocus ? MaterialShape.Shape.Cookie6Sided : MaterialShape.Shape.Circle
                    iconSize: 18
                    padding: 6
                    color: textFieldWidget.activeFocus ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3
                    colSymbol: textFieldWidget.activeFocus ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer3

                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on colSymbol { ColorAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
            }

            StyledText {
                id: labelWidget
                Layout.fillWidth: true
                text: root.text
                color: Appearance.colors.colOnLayer2
                opacity: root.enabled ? 1 : 0.4
            }
            
            MaterialSymbol {
                opacity: root.enabled ? 1 - highlightOverlay.opacity : 0.4
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

        MaterialTextField {
            id: textFieldWidget
            Layout.fillWidth: true
        }
    }
}
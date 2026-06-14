import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls

/**
 * Material 3 styled SpinBox component mimicking CustomSpinBoxRow from email settings.
 */
SpinBox {
    id: root

    property real baseHeight: 35
    property real outerRadius: Appearance.rounding.large
    property real innerRadius: Appearance.rounding.small
    property real buttonSpacing: 4
    editable: true

    opacity: root.enabled ? 1 : 0.4

    leftPadding: baseHeight + buttonSpacing
    rightPadding: baseHeight + buttonSpacing

    background: Item {}

    contentItem: Rectangle {
        implicitHeight: root.baseHeight
        implicitWidth: Math.max(labelText.implicitWidth + 20, root.baseHeight)
        radius: root.innerRadius
        color: Appearance.colors.colSurfaceContainerHigh

        StyledTextInput {
            id: labelText
            anchors.centerIn: parent
            text: root.value
            color: Appearance.colors.colOnSurface
            font.family: Appearance.font.family.numbers
            font.variableAxes: Appearance.font.variableAxes.numbers
            font.pixelSize: Appearance.font.pixelSize.normal
            validator: root.validator
            onTextChanged: {
                root.value = parseFloat(text);
            }
        }
    }

    down.indicator: Rectangle {
        id: downIndicatorRect
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
        }
        implicitHeight: root.baseHeight
        implicitWidth: root.baseHeight
        topLeftRadius: root.outerRadius
        bottomLeftRadius: root.outerRadius
        topRightRadius: root.innerRadius
        bottomRightRadius: root.innerRadius

        color: downMouse.pressed ? Appearance.colors.colSurfaceContainerHighestActive : (downMouse.containsMouse ? Appearance.colors.colSurfaceContainerHighestHover : Appearance.colors.colSurfaceContainerHigh)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(downIndicatorRect)
        }

        scale: downMouse.pressed ? 0.9 : 1.0
        Behavior on scale {
            animation: Appearance.animation.clickBounce.numberAnimation.createObject(downIndicatorRect)
        }

        StyledText {
            anchors.centerIn: parent
            text: "-"
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurface
        }

        MouseArea {
            id: downMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.decrease()
        }
    }

    up.indicator: Rectangle {
        id: upIndicatorRect
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
        }
        implicitHeight: root.baseHeight
        implicitWidth: root.baseHeight
        topRightRadius: root.outerRadius
        bottomRightRadius: root.outerRadius
        topLeftRadius: root.innerRadius
        bottomLeftRadius: root.innerRadius

        color: upMouse.pressed ? Appearance.colors.colSurfaceContainerHighestActive : (upMouse.containsMouse ? Appearance.colors.colSurfaceContainerHighestHover : Appearance.colors.colSurfaceContainerHigh)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(upIndicatorRect)
        }

        scale: upMouse.pressed ? 0.9 : 1.0
        Behavior on scale {
            animation: Appearance.animation.clickBounce.numberAnimation.createObject(upIndicatorRect)
        }

        StyledText {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurface
        }

        MouseArea {
            id: upMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.increase()
        }
    }
}

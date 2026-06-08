import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

import "./widgets"

DockButton {
    id: root

    property var dockContent: null
    property int delegateIndex: -1
    property int symbolSize: Math.round(root.buttonSize * 0.5)
    property string symbolName: ""
    property string toggledSymbolName: ""
    property color activeColor: Appearance.m3colors.m3onPrimary
    property color inactiveColor: Appearance.colors.colOnLayer0
    property bool dragActive: false
    property string dragSymbol: ""
    property int normalShape: MaterialShape.Shape.Pill
    property int activeShape: MaterialShape.Shape.Cookie9Sided
    property bool dragOver: false
    property string fileDropIcon: ""
    property bool fileDropActive: false
    property string customImageSource: ""
    property real symbolFill: root.toggled ? 1.0 : 0.0
    property bool _pressed: false
    readonly property bool isDragging: dragActive || fileDropActive

    background.implicitWidth: 0
    background.implicitHeight: 0

    Loader {
        anchors.fill: parent
        z: 10
        active: true
        sourceComponent: MouseArea {
            id: actionDragOverlay
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property real pressCoord: 0
            property bool dragActive: false

            onPressed: (event) => {
                pressCoord = root.dockContent?.isVertical ? event.y : event.x
                root._pressed = true
            }
            onPositionChanged: (event) => {
                if (!pressed) return
                var cur = root.dockContent?.isVertical ? event.y : event.x
                var dist = Math.abs(cur - pressCoord)
                if (!dragActive && dist > 5 && root.dockContent) {
                    dragActive = true
                    root._pressed = false
                    root.dockContent.startItemDrag(root.delegateIndex, actionDragOverlay, event.x, event.y)
                }
                if (dragActive && root.dockContent) {
                    root.dockContent.moveItemDrag(actionDragOverlay, event.x, event.y)
                }
            }
            onReleased: {
                root._pressed = false
                if (dragActive) {
                    dragActive = false
                    if (root.dockContent) root.dockContent.endItemDrag()
                } else {
                    root.clicked()
                }
            }
            onCanceled: {
                root._pressed = false
                if (dragActive) {
                    dragActive = false
                    if (root.dockContent) root.dockContent.cancelDrag()
                }
            }
        }
    }

    contentItem: Item {
        id: contentContainer
        implicitWidth: root.buttonSize
        implicitHeight: root.buttonSize
        anchors.fill: parent
        clip: false // Allow larger icons to overflow slightly if needed

        MaterialShapeWrappedMaterialSymbol {
            id: shapeSymbol
            anchors.centerIn: parent
            visible: root.customImageSource === ""
            // ... (rest of the properties)
            shape: root.isDragging ? root.activeShape : root.normalShape
            implicitSize: root.dragOver ? root.buttonSize * 1.1 : root.buttonSize * 0.9
            rotation: root.dragOver ? 90 : (root.isDragging ? 45 : 0)
            color: {
                if (root.isDragging) {
                    return root._pressed ? Appearance.colors.colSecondaryContainerActive :
                           root.hovered ? Appearance.colors.colSecondaryContainerHover :
                           Appearance.colors.colSecondaryContainer
                }
                if (root.toggled) {
                    return root._pressed ? Appearance.colors.colPrimaryActive :
                           root.hovered ? Appearance.colors.colPrimaryHover :
                           Appearance.colors.colPrimary
                }
                return root._pressed ? Appearance.colors.colLayer1Active :
                       root.hovered ? Appearance.colors.colLayer1Hover :
                       "transparent"
            }
            text: root.fileDropActive ? root.fileDropIcon
                : root.dragActive ? root.dragSymbol
                : root.symbolName
            fill: root.symbolFill
            iconSize: root.isDragging
                ? Math.round(root.buttonSize * 0.4)
                : root.symbolSize
            colSymbol: root.isDragging
                ? Appearance.colors.colOnSecondaryContainer
                : (root.toggled ? root.activeColor : root.inactiveColor)
        }

        // Custom image (for trash icon, etc.)
        Image {
            visible: root.customImageSource !== ""
            source: root.customImageSource
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.buttonSize * 0.08 // Back to previous stable position
            width: root.buttonSize * 1.0 // Standard size
            height: root.buttonSize * 1.0
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
            mipmap: true
        }
    }
}

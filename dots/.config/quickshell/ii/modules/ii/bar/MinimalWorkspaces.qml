import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    property bool vertical: false
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    
    readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    readonly property bool dynamicWorkspaces: Config.options.bar.workspaces.dynamicWorkspaces

    property var shapesList: [
        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill", "Triangle",
        "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided",
        "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst",
        "SoftBurst", "Flower", "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
    ]
    property string currentRandomShape: "Circle"
    property real randomRotation: 0

    readonly property real stableActivePosition: (tabHighlight ? tabHighlight.getPosForIndex(root.getWsIndex(activeWsId)) : 0) + (root.vertical ? mainLayout.y : mainLayout.x)
    property real animatedStablePosition: stableActivePosition
    Behavior on animatedStablePosition {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    function updateRandomShape() {
        if (!Config.options.bar.workspaces.useRandomShapeForActiveIndicator) return;
        let nextShape = currentRandomShape;
        let attempts = 0;
        while (nextShape === currentRandomShape && attempts < 10) {
            let randIdx = Math.floor(Math.random() * shapesList.length);
            nextShape = shapesList[randIdx];
            attempts++;
        }
        currentRandomShape = nextShape;
        randomRotation = randomRotation + 90;
    }

    onActiveWsIdChanged: {
        updateRandomShape();
    }
    
    // Pagination logic
    readonly property int startWsId: Math.floor((activeWsId - 1) / workspacesShown) * workspacesShown + 1
    
    property var workspaceOccupied: ({})
    
    function updateOccupied() {
        let occupied = {};
        for (let ws of Hyprland.workspaces.values) {
            occupied[ws.id] = true;
        }
        workspaceOccupied = occupied;
    }

    Component.onCompleted: updateOccupied()
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { updateOccupied() }
    }

    implicitWidth: vertical ? 34 : (mainLayout.implicitWidth + 12)
    implicitHeight: vertical ? (mainLayout.implicitHeight + 12) : 34

    // Helper to get index within the shown workspaces
    function getWsIndex(wsId) {
        if (dynamicWorkspaces) {
            // Find index in the list of visible workspaces
            for (let i = 0; i < visibleWsModel.length; i++) {
                if (visibleWsModel[i] === wsId) return i;
            }
            return 0;
        }
        return (wsId - 1) % workspacesShown;
    }

    readonly property var visibleWsModel: {
        if (!dynamicWorkspaces) {
            return Array.from({length: workspacesShown}, (_, i) => startWsId + i);
        }
        let list = [];
        for (let ws of Hyprland.workspaces.values) {
            if (!list.includes(ws.id)) list.push(ws.id);
        }
        if (!list.includes(activeWsId)) list.push(activeWsId);
        list.sort((a, b) => a - b);
        return list;
    }

    // The animated highlight (pill)
    Loader {
        id: tabHighlight
        z: 1
        
        readonly property real dotSize: 18
        readonly property real spacing: 6
        
        function getPosForIndex(i) {
            return i * (dotSize + spacing)
        }
        
        AnimatedTabIndexPair {
            id: idxPair
            index: root.getWsIndex(activeWsId)
        }
        
        readonly property real animX1: getPosForIndex(idxPair.idx1)
        readonly property real animX2: getPosForIndex(idxPair.idx2)
        
        x: root.vertical ? (parent.width - width) / 2 : (Config.options.bar.workspaces.useRandomShapeForActiveIndicator ? root.animatedStablePosition : Math.min(animX1, animX2) + (root.vertical ? 0 : mainLayout.x))
        y: root.vertical ? (Config.options.bar.workspaces.useRandomShapeForActiveIndicator ? root.animatedStablePosition : Math.min(animX1, animX2) + mainLayout.y) : (parent.height - height) / 2
        
        width: root.vertical ? dotSize : (Config.options.bar.workspaces.useRandomShapeForActiveIndicator ? dotSize : Math.abs(animX2 - animX1) + dotSize)
        height: root.vertical ? (Config.options.bar.workspaces.useRandomShapeForActiveIndicator ? dotSize : Math.abs(animX2 - animX1) + dotSize) : dotSize

        sourceComponent: (Config.options.bar.workspaces.useMaterialShapeForActiveIndicator || Config.options.bar.workspaces.useRandomShapeForActiveIndicator) ? materialShapeComponent : rectangleComponent

        Component {
            id: rectangleComponent
            Rectangle {
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimary
                opacity: Config.options.bar.workspaces.activeIndicatorOpacity / 100
            }
        }

        Component {
            id: materialShapeComponent
            MaterialShape {
                anchors.fill: parent
                transformOrigin: Item.Center
                shapeString: Config.options.bar.workspaces.useRandomShapeForActiveIndicator ? root.currentRandomShape : Config.options.bar.workspaces.activeIndicatorShape
                color: Appearance.colors.colPrimary
                opacity: Config.options.bar.workspaces.activeIndicatorOpacity / 100
                rotation: Config.options.bar.workspaces.useRandomShapeForActiveIndicator ? root.randomRotation : 0
                Behavior on rotation {
                    RotationAnimation {
                        duration: 350
                        direction: RotationAnimation.Clockwise
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
    }

    GridLayout {
        id: mainLayout
        anchors.centerIn: parent
        columns: root.vertical ? 1 : visibleWsModel.length
        rows: root.vertical ? visibleWsModel.length : 1
        columnSpacing: 6
        rowSpacing: 6

        Repeater {
            model: root.visibleWsModel
            delegate: Rectangle {
                id: dot
                required property int index
                required property var modelData
                readonly property int wsId: modelData
                readonly property bool isActive: wsId === root.activeWsId
                readonly property bool isOccupied: root.workspaceOccupied[wsId] ?? false
                
                width: 18
                height: 18
                radius: Appearance.rounding.full
                color: "transparent"
                z: 2 // Above the highlight

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }
                
                Rectangle {
                    anchors.centerIn: parent
                    width: isOccupied ? 8 : 4
                    height: width
                    radius: width / 2
                    color: {
                        if (isActive) return "transparent";
                        if (hover.hovered) return Appearance.colors.colPrimary;
                        return isOccupied ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant;
                    }
                    opacity: (isOccupied || hover.hovered) ? 1.0 : 0.4
                    
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: isActive ? "-" : (dot.wsId).toString()
                    font.pixelSize: isActive ? 14 : 10
                    font.weight: isActive ? Font.Bold : Font.Normal
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colOnPrimary
                    opacity: isActive ? 1.0 : 0.0
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = '" + dot.wsId + "' })")
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (dynamicWorkspaces) {
                // In dynamic mode, scroll through existing workspaces (skipping empty)
                if (wheel.angleDelta.y > 0) Hyprland.dispatch("hl.dsp.focus({workspace = 'r-1'})");
                else Hyprland.dispatch("hl.dsp.focus({workspace = 'r+1'})");
            } else {
                // In pagination mode, scroll through all IDs (1, 2, 3...)
                let nextId = activeWsId + (wheel.angleDelta.y > 0 ? -1 : 1);
                if (nextId < 1) return;
                Hyprland.dispatch("hl.dsp.focus({ workspace = '" + nextId + "' })");
            }
        }
    }
}

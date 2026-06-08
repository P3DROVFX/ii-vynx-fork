import QtQuick
import qs.modules.common

Item {
    id: root
    anchors.fill: parent
    
    property string groupKey: ""
    property var dockContent: null
    
    DragHandler {
        id: handler
        target: null
        xAxis.enabled: !dockContent.isVertical
        yAxis.enabled: dockContent.isVertical
        
        onActiveChanged: {
            if (active) {
                dockContent.startGroupDrag(root.groupKey, handler.centroid.scenePosition)
            } else {
                dockContent.endGroupDrag()
            }
        }
        onCentroidChanged: {
            if (active) {
                dockContent.moveGroupDrag(handler.centroid.scenePosition)
            }
        }
    }
}

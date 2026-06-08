import QtQuick
import QtQuick.Layouts
import qs.modules.common
import "../"

Item {
    property bool show: true
    readonly property bool processedShow: show && (Config.options?.dock?.showDividers ?? true)
    visible: processedShow || opacity > 0
    opacity: processedShow ? 1.0 : 0.0
    Layout.alignment: Qt.AlignCenter
    Layout.preferredWidth: processedShow ? (root.isVertical ? root.buttonSlotSize : root.sepThickness) : 0
    Layout.preferredHeight: processedShow ? (root.isVertical ? root.sepThickness : root.buttonSlotSize) : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on Layout.preferredWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on Layout.preferredHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    DockSeparator {
        anchors.fill: parent
    }
}
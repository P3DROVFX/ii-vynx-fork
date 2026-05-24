import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets

GroupButton {
    id: root

    // Info to be passed to by repeaterestou
    required property int buttonIndex
    required property var buttonData
    required property bool expandedSize
    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing
    required property int cellSize

    // Signals
    signal openMenu

    // Declared in specific toggles
    property QuickToggleModel toggleModel
    property string name: toggleModel?.name ?? ""
    property string statusText: (toggleModel?.hasStatusText) ? (toggleModel?.statusText || (toggled ? Translation.tr("Active") : Translation.tr("Inactive"))) : ""
    property string tooltipText: toggleModel?.tooltipText ?? ""
    property string buttonIcon: toggleModel?.icon ?? "close"
    property bool available: toggleModel?.available ?? true
    toggled: toggleModel?.toggled ?? false
    property var mainAction: toggleModel?.mainAction ?? null
    altAction: toggleModel?.hasMenu ? (() => root.openMenu()) : (toggleModel?.altAction ?? null)

    // Edit mode state
    property bool editMode: false

    // Sizing shenanigans
    baseWidth: root.baseCellWidth * cellSize + cellSpacing * (cellSize - 1)
    baseHeight: root.baseCellHeight
    enableImplicitWidthAnimation: !editMode && root.mouseArea.containsMouse
    enableImplicitHeightAnimation: !editMode && root.mouseArea.containsMouse
    Behavior on baseWidth {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on baseHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    opacity: 0
    Component.onCompleted: {
        opacity = 1;
    }
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    enabled: available || editMode
    padding: 6
    horizontalPadding: padding
    verticalPadding: padding

    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: (altAction && expandedSize) ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
    colBackgroundToggledHover: (altAction && expandedSize) ? Appearance.colors.colLayer2Hover : Appearance.colors.colPrimaryHover
    colBackgroundToggledActive: (altAction && expandedSize) ? Appearance.colors.colLayer2Active : Appearance.colors.colPrimaryActive
    readonly property int fullRadius: Config.options.appearance.sharpMode ? Appearance.rounding.full : height / 2
    buttonRadius: toggled ? Appearance.rounding.large : fullRadius
    buttonRadiusPressed: Appearance.rounding.normal
    property color colText: (toggled && !(altAction && expandedSize) && enabled) ? Appearance.colors.colOnPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer2, enabled ? 0 : 0.7)
    property color colIcon: expandedSize ? ((root.toggled) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3) : colText

    onClicked: {
        if (root.expandedSize && root.altAction)
            root.altAction();
        else
            root.mainAction();
    }

    contentItem: RowLayout {
        id: contentItem
        spacing: 4
        anchors {
            centerIn: root.expandedSize ? undefined : parent
            fill: root.expandedSize ? parent : undefined
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        // Icon
        MouseArea {
            id: iconMouseArea
            hoverEnabled: true
            acceptedButtons: (root.expandedSize && root.altAction) ? Qt.LeftButton : Qt.NoButton
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.topMargin: root.verticalPadding
            Layout.bottomMargin: root.verticalPadding
            implicitHeight: iconBackground.implicitHeight
            implicitWidth: iconBackground.implicitWidth
            cursorShape: Qt.PointingHandCursor

            onClicked: root.mainAction()

            Rectangle {
                id: iconBackground
                anchors.fill: parent
                implicitWidth: height
                radius: root.radius - root.verticalPadding
                color: {
                    const baseColor = root.toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer3;
                    const transparentizeAmount = (root.altAction && root.expandedSize) ? 0 : 1;
                    return ColorUtils.transparentize(baseColor, transparentizeAmount);
                }

                Behavior on radius {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: root.toggled ? 1 : 0
                    iconSize: root.expandedSize ? 22 : 24
                    color: root.colIcon
                    text: root.buttonIcon
                }

                // State layer
                Loader {
                    anchors.fill: parent
                    active: (root.expandedSize && root.altAction)
                    sourceComponent: Rectangle {
                        radius: iconBackground.radius
                        color: ColorUtils.transparentize(root.colIcon, iconMouseArea.containsPress ? 0.88 : iconMouseArea.containsMouse ? 0.95 : 1)
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                }
            }
        }

        // Text column for expanded size
        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            visible: root.expandedSize
            active: visible
            sourceComponent: Column {
                spacing: -2

                StyledText {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.weight: 600
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.name
                }

                StyledText {
                    visible: root.statusText
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: 100
                    }
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.statusText
                }
            }
        }
    }

    // Page awareness for edit operations
    property int pageIndex: 0

    MouseArea { // Blocking MouseArea for edit interactions
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        // list<var> returns a copy — MUST deep-clone, mutate, reassign
        function mutatePages(mutatorFn) {
            var cloned = JSON.parse(JSON.stringify(Config.options.sidebar.quickToggles.android.pages));
            mutatorFn(cloned);
            Config.options.sidebar.quickToggles.android.pages = cloned;
        }

        function toggleEnabled() {
            const buttonType = root.buttonData.type;
            const pi = root.pageIndex;

            mutatePages(function(pages) {
                if (pi < 0 || pi >= pages.length) return;
                var page = pages[pi];
                var existingIdx = -1;
                for (var i = 0; i < page.length; i++) {
                    if (page[i].type === buttonType) { existingIdx = i; break; }
                }
                if (existingIdx === -1) {
                    // Not in this page — add it
                    page.push({ type: buttonType, size: 1 });
                } else {
                    // Already in this page — remove it
                    page.splice(existingIdx, 1);
                }
            });
        }

        function toggleSize() {
            const buttonType = root.buttonData.type;
            const pi = root.pageIndex;

            mutatePages(function(pages) {
                if (pi < 0 || pi >= pages.length) return;
                var page = pages[pi];
                for (var i = 0; i < page.length; i++) {
                    if (page[i].type === buttonType) {
                        page[i].size = 3 - page[i].size; // Alternate 1 ↔ 2
                        return;
                    }
                }
            });
        }

        function movePositionBy(offset) {
            const buttonType = root.buttonData.type;
            const pi = root.pageIndex;

            mutatePages(function(pages) {
                if (pi < 0 || pi >= pages.length) return;
                var page = pages[pi];
                var idx = -1;
                for (var i = 0; i < page.length; i++) {
                    if (page[i].type === buttonType) { idx = i; break; }
                }
                if (idx === -1) return;
                var targetIdx = idx + offset;
                if (targetIdx < 0 || targetIdx >= page.length) return;
                var temp = page[idx];
                page[idx] = page[targetIdx];
                page[targetIdx] = temp;
            });
        }

        onReleased: event => {
            if (event.button === Qt.LeftButton)
                toggleEnabled();
        }
        onPressed: event => {
            if (event.button === Qt.RightButton)
                toggleSize();
        }
        onPressAndHold: event => {
            toggleSize();
        }
        onWheel: event => {
            if (event.angleDelta.y < 0) {
                movePositionBy(1);
            } else if (event.angleDelta.y > 0) {
                movePositionBy(-1);
            }
            event.accepted = true;
        }
    }

    StyledToolTip {
        extraVisibleCondition: root.tooltipText !== ""
        text: root.tooltipText
    }
}

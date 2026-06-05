pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property bool isOpen: false
    readonly property bool isExitAnimRunning: exitAnim.running

    // Spacing and offset properties passed down from the window wrapper
    property real topMarginValue: 0

    // Control animations based on isOpen state changes
    onIsOpenChanged: {
        if (isOpen) {
            exitAnim.stop();
            entranceAnim.start();
        } else {
            entranceAnim.stop();
            delayedSlideTimer.stop(); // cancel delayed transitions if closing
            exitAnim.start();
        }
    }

    // Spacing and sizing - Spacious premium height
    property real horizontalPadding: 20
    property real verticalPadding: 10

    implicitWidth: contentLayout.implicitWidth + 2 * horizontalPadding + 2 * Appearance.sizes.elevationMargin
    implicitHeight: 64 + 2 * Appearance.sizes.elevationMargin

    // Expose a static, unscaled item for the window input mask
    property alias staticMaskTarget: staticMaskTarget
    Item {
        id: staticMaskTarget
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
    }

    // Timer to delay the horizontal layout slide animation until the popup is fully opened and visible.
    // This solves the issue where rapid keypresses would finish their slide animation before the popup finishes sliding down.
    Timer {
        id: delayedSlideTimer
        interval: 200 // Wait 200ms for entrance animation to be fully visible before starting horizontal slide
        repeat: false
        onTriggered: {
            layoutsContainer.highlightIndex = layoutsContainer.activeIndex;
        }
    }

    // Shadow fully synchronized with background opacity, translation, and scale
    StyledRectangularShadow {
        id: shadow
        target: contentBackground
        opacity: contentBackground.opacity
        scale: contentBackground.scale
        transform: Translate {
            y: contentBackground.yOffset
        }
    }

    Rectangle {
        id: contentBackground
        
        // Positioned dynamically below the screen top-margin offset
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: root.topMarginValue + Appearance.sizes.elevationMargin
        }
        
        width: parent.width - 2 * Appearance.sizes.elevationMargin
        height: 64
        radius: Appearance.rounding.full
        
        // Sleek, expressive container styling
        color: Config.options.appearance.transparency.popups ? Appearance.colors.colLayer0 : Appearance.m3colors.m3surfaceContainer
        
        // Clean layout design - NO BORDER
        border.width: 0
        border.color: "transparent"

        // Slide Y offset - starts completely above the absolute top of the screen
        readonly property real slideOffset: -(root.topMarginValue + Appearance.sizes.elevationMargin + height + 40)
        
        opacity: 0
        scale: 1.0 // kept stable to match the search widget
        property real yOffset: slideOffset

        transform: Translate {
            y: contentBackground.yOffset
        }

        // Entrance animation matching the SearchWidget (480ms slide-in with expressiveFastSpatial bounce curve)
        ParallelAnimation {
            id: entranceAnim
            NumberAnimation {
                target: contentBackground
                property: "yOffset"
                from: contentBackground.slideOffset
                to: 0
                duration: 480
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial // premium overshoot bounce
            }
            NumberAnimation {
                target: contentBackground
                property: "opacity"
                from: 0
                to: 1
                duration: 480
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedDecel // clean fade
            }
        }

        // Exit animation matching the SearchWidget (200ms slide-up back into the top edge)
        ParallelAnimation {
            id: exitAnim
            NumberAnimation {
                target: contentBackground
                property: "yOffset"
                to: contentBackground.slideOffset
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
            NumberAnimation {
                target: contentBackground
                property: "opacity"
                to: 0
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
            }
        }

        // Core row layout
        RowLayout {
            id: contentLayout
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: root.horizontalPadding
                rightMargin: root.horizontalPadding
            }
            spacing: 16

            // Left side: Keyboard Icon inside Clover/Cookie shape
            MaterialShape {
                id: iconShape
                shapeString: "Cookie12Sided"
                color: Appearance.colors.colPrimaryContainer
                implicitWidth: 44
                implicitHeight: 44

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "keyboard"
                    iconSize: 22
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            // Right side: Slide container for layout codes
            Item {
                id: layoutsContainer
                Layout.fillWidth: true
                implicitHeight: 44
                implicitWidth: (70 * HyprlandXkb.layoutCodes.length) + (4 * (HyprlandXkb.layoutCodes.length - 1))

                readonly property int itemWidth: 70
                readonly property int spacingValue: 4
                
                // Track active indexes
                readonly property int activeIndex: getActiveIndex()
                property int previousActiveIndex: activeIndex
                property int highlightIndex: activeIndex

                onActiveIndexChanged: {
                    if (root.isOpen && !delayedSlideTimer.running) {
                        // Already fully open: slide smoothly in real-time
                        highlightIndex = activeIndex;
                    } else {
                        // Was closed or currently opening: freeze selection at the old layout
                        // to show a gorgeous slide animation only AFTER the entrance animation is complete
                        highlightIndex = previousActiveIndex;
                        delayedSlideTimer.restart();
                    }
                    previousActiveIndex = activeIndex;
                    iconShapePulse.restart();
                }

                function getActiveIndex() {
                    const current = (HyprlandXkb.currentLayoutCode || "").toLowerCase().trim();
                    for (let i = 0; i < HyprlandXkb.layoutCodes.length; i++) {
                        const code = HyprlandXkb.layoutCodes[i].toLowerCase().trim();
                        if (current.startsWith(code) || code.startsWith(current)) {
                            return i;
                        }
                    }
                    return 0;
                }

                // Generates beautiful two-line layout code and variant formatting
                function getLayoutDisplayString(code, isActive) {
                    let fullCode = code;
                    if (isActive && HyprlandXkb.currentLayoutCode) {
                        fullCode = HyprlandXkb.currentLayoutCode;
                    }
                    
                    fullCode = (fullCode || "").toLowerCase().trim();
                    
                    // 1. Parenthesis format e.g. "br(abnt2)" or "us(intl)"
                    const parenMatch = fullCode.match(/^([a-zA-Z]{2,3})\((.+)\)$/);
                    if (parenMatch) {
                        return parenMatch[1].toUpperCase() + "\n" + parenMatch[2].toUpperCase();
                    }
                    
                    // 2. Combined format e.g. "brabnt2" or "usintl"
                    if (fullCode.startsWith("br") && fullCode.length > 2) {
                        return "BR\n" + fullCode.substring(2).toUpperCase();
                    }
                    if (fullCode.startsWith("us") && fullCode.length > 2) {
                        const variant = fullCode.substring(2).toUpperCase();
                        if (variant.startsWith("INTL")) {
                            return "US\nINTL";
                        }
                        return "US\n" + variant;
                    }
                    
                    // 3. Hyphen or colon format
                    if (fullCode.includes("-")) {
                        const parts = fullCode.split("-");
                        return parts[0].toUpperCase() + "\n" + parts[1].toUpperCase();
                    }
                    if (fullCode.includes(":")) {
                        const parts = fullCode.split(":");
                        return parts[0].toUpperCase() + "\n" + parts[1].toUpperCase();
                    }
                    
                    // Default fallback: return layout code on 1 line
                    return fullCode.toUpperCase();
                }

                // Sliding capsule selection background
                Rectangle {
                    id: highlightPill
                    width: layoutsContainer.itemWidth
                    height: parent.height
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colPrimary

                    x: layoutsContainer.highlightIndex * (layoutsContainer.itemWidth + layoutsContainer.spacingValue)
                    y: 0

                    Behavior on x {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutExpo
                        }
                    }
                }

                // Horizontal Row of Layout Labels
                Row {
                    spacing: layoutsContainer.spacingValue
                    anchors.fill: parent

                    Repeater {
                        model: HyprlandXkb.layoutCodes
                        delegate: Item {
                            width: layoutsContainer.itemWidth
                            height: 44

                            required property int index
                            required property string modelData

                            StyledText {
                                anchors.centerIn: parent
                                text: layoutsContainer.getLayoutDisplayString(modelData, index === layoutsContainer.activeIndex)
                                font.family: Appearance.font.family.title
                                font.pixelSize: index === layoutsContainer.activeIndex ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.smallie
                                font.weight: index === layoutsContainer.activeIndex ? Font.Black : Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                lineHeight: 0.85 // elegant tight spacing
                                color: index === layoutsContainer.activeIndex ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dynamic icon shape micro-interaction pulse
    SequentialAnimation {
        id: iconShapePulse
        NumberAnimation { target: iconShape; property: "scale"; to: 1.25; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { target: iconShape; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.OutBack }
    }
}

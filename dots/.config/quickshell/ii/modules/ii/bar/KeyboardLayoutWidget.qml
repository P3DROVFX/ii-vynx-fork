import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property bool vertical: false
    property bool uppercaseLayout: Config.options.bar.keyboardLayout.uppercaseLayout

    readonly property bool hasMultipleLayouts: HyprlandXkb.layoutCodes.length > 1

    // Visible if there is at least 1 layout registered
    visible: HyprlandXkb.layoutCodes.length >= 1

    implicitWidth: visible ? layout.implicitWidth + 16 : 0
    implicitHeight: visible ? Appearance.sizes.baseBarHeight : 0

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    function abbreviateLayoutCode(fullCode) {
        if (!fullCode)
            return "";
        let abbr = fullCode.split(':').map(layout => {
            const baseLayout = layout.split('-')[0];
            return baseLayout.slice(0, 2);
        }).join('\n')
        return root.uppercaseLayout ? abbr.toUpperCase() : abbr.toLowerCase();
    }

    Process {
        id: switchProc
        command: ["bash", "-c", "hyprctl switchxkblayout all next"]
    }

    onClicked: {
        if (hasMultipleLayouts) {
            switchProc.running = false;
            switchProc.running = true;
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.large
            text: "keyboard"
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: root.abbreviateLayoutCode(HyprlandXkb.currentLayoutCode).replace(/\n/g, ' ')
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer1
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
            animateChange: true
        }
    }

    KeyboardLayoutPopup {
        id: popup
        hoverTarget: root
    }
}

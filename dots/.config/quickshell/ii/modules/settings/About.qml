import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "box"
        title: Translation.tr("Distro")
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath(SystemInfo.logo)
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: SystemInfo.distroName
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    text: SystemInfo.homeUrl
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.documentationUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "support"
                mainText: Translation.tr("Help & Support")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.supportUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Report a Bug")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.bugReportUrl)
                }
            }
            RippleButtonWithIcon {
                materialIcon: "policy"
                materialIconFill: false
                mainText: Translation.tr("Privacy Policy")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.privacyPolicyUrl)
                }
            }
            
        }

    }
    ContentSection {
        icon: "folder_managed"
        title: Translation.tr("Parent-Dots")

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            IconImage {
                implicitSize: 80
                source: Quickshell.iconPath("illogical-impulse")
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: Translation.tr("illogical-impulse")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/end-4/dots-hyprland"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: Translation.tr("Donate")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/sponsors/end-4")
                }
            }

            
        }
    }

    ContentSection {
        icon: "folder_data"
        title: Translation.tr("Dotfiles")

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            CustomIcon {
                width: 80
                height: 80
                source: "ii-vynx"
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                // spacing: 10
                StyledText {
                    text: Translation.tr("ii-vynx")
                    font.pixelSize: Appearance.font.pixelSize.title
                }
                StyledText {
                    text: "https://github.com/vaguesyntax/ii-vynx"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    textFormat: Text.MarkdownText
                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                    }
                    PointingHandLinkHover {}
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/vaguesyntax/ii-vynx/issues")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/vaguesyntax/ii-vynx/wiki")
                }
            }
            RippleButtonWithIcon {
                materialIcon: "bug_report"
                mainText: Translation.tr("Known Issues")
                onClicked: {
                    Qt.openUrlExternally("https://github.com/vaguesyntax/ii-vynx/wiki/Known-Issues-and-Limitations")
                }
            }
            

            
        }
    }
}

    ContentSection {
        id: sourceSwitchSection
        icon: "swap_horiz"
        title: Translation.tr("Quickshell Source")

        property string stateFile: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/quickshell/user/generated/qs-source.txt"
        property string installScript: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/ii-vynx/setup-ii-vynx.sh"
        property string activeSource: "fork"

        Component.onCompleted: { sourceReadProc.running = true }

        Process {
            id: sourceReadProc
            command: ["bash", "-c", "cat " + sourceSwitchSection.stateFile + " 2>/dev/null || echo fork"]
            stdout: SplitParser {
                onRead: data => { sourceSwitchSection.activeSource = data.trim() }
            }
        }

        Process {
            id: switchProc
            property string nextSource: ""
            onExited: code => { if (code === 0) sourceSwitchSection.activeSource = switchProc.nextSource }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                    text: Translation.tr("Switch between your fork and the official ii-vynx quickshell.")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    wrapMode: Text.WordWrap
                }
                StyledText {
                    text: Translation.tr("Uses local repos only (no network). Restarts Quickshell automatically.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 5
            RippleButtonWithIcon {
                materialIcon: "fork_right"
                mainText: Translation.tr("My Fork")
                property bool isActive: sourceSwitchSection.activeSource !== "ii-vynx"
                buttonColor: isActive ? Appearance.colors.colPrimary : undefined
                labelColor: isActive ? Appearance.colors.colOnPrimary : undefined
                onClicked: {
                    switchProc.nextSource = "fork"
                    switchProc.command = ["bash", "-c", sourceSwitchSection.installScript + " --force-install --no-pull --no-confirm && echo fork > " + sourceSwitchSection.stateFile]
                    switchProc.running = true
                }
            }
            RippleButtonWithIcon {
                materialIcon: "deployed_code"
                mainText: Translation.tr("ii-vynx Official")
                property bool isActive: sourceSwitchSection.activeSource === "ii-vynx"
                buttonColor: isActive ? Appearance.colors.colPrimary : undefined
                labelColor: isActive ? Appearance.colors.colOnPrimary : undefined
                onClicked: {
                    switchProc.nextSource = "ii-vynx"
                    switchProc.command = ["bash", "-c", sourceSwitchSection.installScript + " --force-install --no-pull --no-confirm --ii-vynx && echo ii-vynx > " + sourceSwitchSection.stateFile]
                    switchProc.running = true
                }
            }
        }
    }
}

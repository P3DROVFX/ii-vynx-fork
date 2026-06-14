import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: false
    signal goBack()

    RowLayout {
        spacing: 12

        RippleButton {
            implicitWidth: implicitHeight
            implicitHeight: 40
            topLeftRadius: Appearance.rounding.full
            topRightRadius: Appearance.rounding.full
            bottomLeftRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive

            MaterialSymbol {
                anchors.centerIn: parent
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSecondaryContainer
            }

            onClicked: root.goBack()
        }

        StyledText {
            text: Translation.tr("Work Safety & Policies")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer0
        }
    }
    ContentSection {
        icon: "policy"
        title: Translation.tr("Work Safety & Policies")

        ContentSubsectionLabel { text: Translation.tr("Hiding Suspects") }

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide suspect/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }

        ContentSubsectionLabel { text: Translation.tr("Policies settings") }

            ContentSubsection {
                title: Translation.tr("AI policy")
                icon: "smart_toy"
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("No"), icon: "close", value: 0 },
                        { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                        { displayName: Translation.tr("Local"), icon: "sync_saved_locally", value: 2 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Weeb policy")
                icon: "face"
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("No"), icon: "close", value: 0 },
                        { displayName: Translation.tr("Yes"), icon: "check", value: 1 },
                        { displayName: Translation.tr("Closet"), icon: "ev_shadow", value: 2 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Wallpaper browser policy")
                icon: "wallpaper"
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.policies.wallpapers
                    onSelected: newValue => {
                        Config.options.policies.wallpapers = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("No"), icon: "close", value: 0 },
                        { displayName: Translation.tr("Yes"), icon: "check", value: 1 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Translator policy")
                icon: "translate"
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.policies.translator
                    onSelected: newValue => {
                        Config.options.policies.translator = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("No"), icon: "close", value: 0 },
                        { displayName: Translation.tr("Yes"), icon: "check", value: 1 }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Sidebar player policy")
                icon: "music_note"
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.policies.player
                    onSelected: newValue => {
                        Config.options.policies.player = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("No"), icon: "close", value: 0 },
                        { displayName: Translation.tr("Yes"), icon: "check", value: 1 }
                    ]
                }
            }
    }
}

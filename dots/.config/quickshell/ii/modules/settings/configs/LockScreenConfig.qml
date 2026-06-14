import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    forceWidth: false

    ContentSection {
        icon: "lock"
        title: Translation.tr("General")

        ConfigSwitch {
            buttonIcon: "lock_outline"
            text: Translation.tr("Use Hyprlock instead of Quickshell")
            checked: Config.options.lock.useHyprlock
            onCheckedChanged: {
                Config.options.lock.useHyprlock = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enforce the use of the external Hyprlock over the default Quickshell lockscreen overlay.")
            }
        }

        ConfigSwitch {
            buttonIcon: "power_settings_new"
            text: Translation.tr("Launch on startup")
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
            StyledToolTip {
                text: Translation.tr("Start the lock screen daemon when the session begins.")
            }
        }
    }

    ContentSection {
        icon: "security"
        title: Translation.tr("Security")

        ConfigSwitch {
            buttonIcon: "password"
            text: Translation.tr("Require password to power off/restart")
            checked: Config.options.lock.security.requirePasswordToPower
            onCheckedChanged: {
                Config.options.lock.security.requirePasswordToPower = checked;
            }
            StyledToolTip {
                text: Translation.tr("Block the system power menu until the screen is unlocked.")
            }
        }

        ConfigSwitch {
            buttonIcon: "key"
            text: Translation.tr("Also unlock keyring")
            checked: Config.options.lock.security.unlockKeyring
            onCheckedChanged: {
                Config.options.lock.security.unlockKeyring = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically unlock the login keyring when unlocking the session.")
            }
        }
    }

    ContentSection {
        icon: "style"
        title: Translation.tr("Style: General")

        ConfigSwitch {
            buttonIcon: "align_horizontal_center"
            text: Translation.tr("Center clock")
            checked: Config.options.lock.centerClock
            onCheckedChanged: {
                Config.options.lock.centerClock = checked;
            }
            StyledToolTip {
                text: Translation.tr("Position the clock directly in the center of the screen.")
            }
        }

        ConfigSwitch {
            buttonIcon: "text_fields"
            text: Translation.tr("Show \"Locked\" text")
            checked: Config.options.lock.showLockedText
            onCheckedChanged: {
                Config.options.lock.showLockedText = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display an explicit indicator text below the password field.")
            }
        }

        ConfigSwitch {
            buttonIcon: "category"
            text: Translation.tr("Use varying shapes for password characters")
            checked: Config.options.lock.materialShapeChars
            onCheckedChanged: {
                Config.options.lock.materialShapeChars = checked;
            }
            StyledToolTip {
                text: Translation.tr("Replace the standard dots with random Material You shapes when typing the password.")
            }
        }
    }

    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Style: Blurred")

        ConfigSwitch {
            buttonIcon: "lens_blur"
            text: Translation.tr("Enable blur")
            checked: Config.options.lock.blur.enable
            onCheckedChanged: {
                Config.options.lock.blur.enable = checked;
            }
        }

        ConfigSpinBox {
            enabled: Config.options.lock.blur.enable
            icon: "zoom_in"
            text: Translation.tr("Extra wallpaper zoom (%)")
            value: Config.options.lock.blur.extraZoom * 100
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.lock.blur.extraZoom = value / 100;
            }
        }
    }
}

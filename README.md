# 🌌 ii-vynx: Quickshell Dotfiles Manager

A powerful and flexible environment manager for [ii-vynx](https://github.com/vaguesyntax/ii-vynx) (Quickshell + Hyprland). This fork adds advanced source switching and update capabilities directly from your Quickshell settings.

---

## 🚀 Installation

To install **ii-vynx** and set up the management environment, clone this repository and run the setup script:

```bash
git clone https://github.com/P3DROVFX/ii-vynx.git ~/Downloads/ii-vynx
cd ~/Downloads/ii-vynx
./setup-ii-vynx.sh
```

> [!TIP]
> The first run will automatically bootstrap the environment into `~/.local/share/ii-vynx/` and create a dedicated fork repository at `~/.local/share/ii-vynx-fork/`.

---

## 🌟 Custom Features

### 🔍 Revamped Search Launcher (Power-User)
This repository includes a completely revamped search launcher widget (`Super + D` or `Super + Space`) designed for power-users, complete with:
*   **Prefix-less Math & Unit Converter**: Real-time evaluation of mathematical expressions (including functions like `sqrt`, `sin`, `cos`) and units/currency conversions (e.g. `120 usd to eur` or `50c to f`) right inside the preview results block without needing a prefix.
*   **Secure System Controls**: Instantly lock the screen (`lock`), suspend the PC (`suspend`), reboot (`reboot`), shutdown (`poweroff`), or restart the Quickshell shell (`restart`) directly from the search bar.
*   **Two-Step Confirmation Safeguard**: Clicking or hitting Enter on critical system commands dynamically prompts for confirmation inside the launcher (e.g., `Reboot PC (Are you sure?)`), keeping the launcher open and requiring a second Enter/click to execute, while cancelling automatically if you type or move away.

For a full setup guide, code diffs, and detailed configuration parameters, check out the [Search Upgrades & Implementation Guide](dots/.config/quickshell/ii/modules/ii/overview/IMPLEMENTATION_GUIDE.md).

---

## 🔄 Managing Sources

You can switch between your personal fork and the official upstream repository directly from the **About** page in Quickshell Settings (`Super + S` -> About).

### 🎛 UI Controls (Settings > About)

The **Quickshell Source** section provides four main actions:

1.  **Switch Source (My Fork / Official)**:
    *   **My Fork**: Installs the configuration from your local fork (`~/.local/share/ii-vynx-fork/`).
    *   **ii-vynx Official**: Installs the configuration from the official upstream cache (`~/.local/share/ii-vynx-upstream/`).
    *   *Both actions are local and fast, requiring no internet connection once cached.*

2.  **Update (Update Fork / Update ii-vynx)**:
    *   Performs a `git pull` on the respective local repository.
    *   Does **not** automatically apply the changes to your active `~/.config/quickshell/ii` until you click a "Switch" button.
    *   Displays a real-time log of the update process in the UI.

---

## 🛡 Safety & Persistence

The installation script is designed to be "user-aware" and preserves your customizations:

*   **About.qml Persistence**: The settings page containing these controls is never overwritten during a switch or update.
*   **Environment Files**: All `.env` files and patterns defined in `PROTECTED_PATTERNS` are automatically backed up and restored.
*   **Backups**: Every switch operation creates a full backup of your previous `~/.config/quickshell/ii` directory with a timestamp.

---

## 🛠 Command Line Interface

You can also manage the environment using the `vynx` CLI (automatically symlinked to `~/.local/bin/vynx`):

```bash
# Switch to official upstream
vynx --ii-vynx --force-install --no-confirm

# Switch to your fork
vynx --force-install --no-confirm

# Update your fork repo only
vynx --update-only
```

---

## 📝 Configuration

The script auto-detects your environment. For developers, the `FORK_DIR` will prioritize `~/.local/share/ii-vynx-fork` if it exists, otherwise it will use the directory where the script is being executed.

---

*Powered by [Antigravity AI](https://github.com/google-deepmind) and the ii-vynx community.*

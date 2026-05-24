# Advanced Search Launcher Upgrades: Implementation & Usage Guide

This guide provides a comprehensive, step-by-step documentation for integrating the **Prefix-less Power-User Search Launcher** into the Quickshell/II environment. It allows seamless, secure, prefix-less system operations (lock, shutdown, reboot, suspend, restart) with a dynamic two-step confirmation system and premium, real-time math/unit conversion structured previews.

---

## 1. Feature Architecture Overview

### 🛠️ Built-in System Controls (Prefix-less & Secure)
* **Direct Actions**: Instant triggering of core system commands:
  * `lock` / `:lock` ➔ Locks the screen directly using `/usr/bin/hyprlock`.
  * `poweroff` / `:poweroff` ➔ Shuts down the system (`systemctl poweroff`).
  * `reboot` / `:reboot` ➔ Reboots the system (`systemctl reboot`).
  * `suspend` / `:suspend` ➔ Suspends the system (`systemctl suspend`).
  * `restart` / `:restart` ➔ Seamlessly restarts/reloads the Quickshell shell in-process via `Quickshell.reload()`.
* **Smart Noise Filtering**: Typing a single character will not match system commands to prevent search clutter (e.g., typing `r` for "Rofi" or "Rust"). Prefix-less matching triggers on **2+ characters** (e.g., `re` matches `reboot` and `restart`). However, typing the colon prefix `:` immediately displays all matching system commands.
* **Double-Step Secure Confirmation**: To prevent accidental triggers, selecting a command and pressing `Enter` transitions the item into a dynamic confirmation state. The title becomes `Reboot PC (Are you sure?)`, the comment changes to `Press Enter again to confirm`, and the action verb changes to `Confirm`. The launcher stays open. Typing or moving away automatically cancels the pending action.

### 🧮 Integrated Math & Unit Converter (Prefix-less & Structured)
* **Smart Parsing**: Automatically identifies complex math formulas, functions (`sqrt`, `sin`, `cos`, `log`, etc.), and unit/currency conversions (like `120 usd to eur` or `50c to f`) without requiring any explicit prefix, while ignoring standard text queries.
* **Premium Structured Layout**: Instead of single-line text, results are parsed into:
  * **LHS (Input)**: Cleaned expression displayed in a modern, lightweight monospace font.
  * **Arrow Indicator**: A primary-colored pointer (`arrow_forward`) representing the evaluation stream.
  * **RHS (Result)**: The bold, highlighted evaluation, replacing raw `qalc` symbols with standard human-readable symbols (e.g., converting `approx.` to `≈` and `deg` to `°`).

---

## 2. Step-by-Step Implementation Files

### File 1: Central Configuration (`modules/common/Config.qml`)
Register the two toggles inside the central search options schema to allow users to enable or disable these features.

```qml
// Inside Config.qml -> property var search options object
property bool enableSystemControls: true
property bool enableMathPreview: true
```

---

### File 2: Settings UI Panel (`modules/settings/SearchConfig.qml`)
Expose the custom switches in the Search configuration tab so users can toggle them with tooltips.

```qml
ConfigSwitch {
    label: Translation.tr("Enable System Controls")
    description: Translation.tr("Allows typing commands like reboot, poweroff, suspend, and lock directly in the search bar.")
    checked: Config.options.search.enableSystemControls
    onCheckedChanged: Config.options.search.enableSystemControls = checked
}

ConfigSwitch {
    label: Translation.tr("Enable Math Preview")
    description: Translation.tr("Displays mathematical calculations and unit conversions in a structured premium layout.")
    checked: Config.options.search.enableMathPreview
    onCheckedChanged: Config.options.search.enableMathPreview = checked
}
```

---

### File 3: Core Search Logic (`services/LauncherSearch.qml`)
This is the core engine containing prefix-less system matching, advanced math triggers, and reactive two-step confirmation.

#### Key Additions & Edits:

1. **State Declaration**:
   ```qml
   property string mathResult: ""
   property string confirmKey: "" // Stores the currently pending system command
   ```

2. **Advanced Math Query Detection** (placed in the root component helper functions):
   ```js
   function isMathQuery(expr) {
       expr = expr.trim();
       if (expr.length === 0) return false;
       
       // Starts with math prefix '='
       if (expr.startsWith(Config.options.search.prefix.math)) return true;
       
       // Starts with a number or negative sign and number
       if (/^[-]?\d/.test(expr)) return true;
       
       // Contains a number AND contains math operators or 'to' keyword
       const hasNumber = /\d/.test(expr);
       if (hasNumber) {
           if (/[+\*\/^()]/.test(expr)) return true;
           if (/\bto\b/i.test(expr)) return true;
       }
       
       // Starts with basic math functions
       if (/^(sqrt|sin|cos|tan|log|ln)\b/i.test(expr)) return true;
       
       return false;
   }
   ```

3. **Timer & Query Updates**:
   Update `nonAppResultsTimer` and `onQueryChanged` to trigger based on `isMathQuery(expr)` and automatically reset `confirmKey = ""` on any typing change:
   ```qml
   Timer {
       id: nonAppResultsTimer
       interval: Config.options.search.nonAppResultDelay
       onTriggered: {
           let expr = root.query;
           if (!root.isMathQuery(expr)) return;

           if (expr.startsWith(Config.options.search.prefix.math)) {
               expr = expr.slice(Config.options.search.prefix.math.length);
           }
           mathProc.calculateExpression(expr);
       }
   }

   onQueryChanged: {
       // ... existing file search & browser checks ...

       if (!root.isMathQuery(root.query)) {
           root.mathResult = "";
       }
       root.confirmKey = ""; // Reset pending confirmation immediately on query change
   }
   ```

4. **Result Construct & Instantiation**:
   Configure the `mathResultObject` to expose the boolean `isMath` state:
   ```js
   const mathResultObject = resultComp.createObject(null, {
       key: "math:result",
       name: root.mathResult || Translation.tr("Evaluate math..."),
       verb: Translation.tr("Copy"),
       type: Translation.tr("Math result"),
       fontType: LauncherSearchResult.FontType.Monospace,
       iconName: 'calculate',
       iconType: LauncherSearchResult.IconType.Material,
       isMath: Config.options.search.enableMathPreview && !!root.mathResult,
       execute: () => {
           Quickshell.clipboardText = root.mathResult;
       }
   });
   ```

5. **Prefix-less System Commands & Result Aggregation**:
   Filter prefix-less commands and construct their dynamic confirmation properties:
   ```js
   const isMath = root.isMathQuery(root.query);
   const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
   const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch);

   // System Controls matches
   const systemControlResults = [];
   let queryClean = root.query.toLowerCase().trim();
   const hasColonPrefix = queryClean.startsWith(":");
   if (hasColonPrefix) {
       queryClean = queryClean.slice(1);
   }

   if (Config.options.search.enableSystemControls && (hasColonPrefix || queryClean.length >= 2)) {
       const sysCommands = [
           { cmd: "lock", label: Translation.tr("Lock Screen"), execute: () => Quickshell.execDetached(["hyprlock"]), icon: "lock", desc: Translation.tr("Lock the current session") },
           { cmd: "poweroff", label: Translation.tr("Shutdown PC"), execute: () => Quickshell.execDetached(["systemctl", "poweroff"]), icon: "power_settings_new", desc: Translation.tr("Power off the computer") },
           { cmd: "reboot", label: Translation.tr("Reboot PC"), execute: () => Quickshell.execDetached(["systemctl", "reboot"]), icon: "restart_alt", desc: Translation.tr("Restart the computer") },
           { cmd: "suspend", label: Translation.tr("Suspend PC"), execute: () => Quickshell.execDetached(["systemctl", "suspend"]), icon: "bedtime", desc: Translation.tr("Put the computer to sleep") },
           { cmd: "restart", label: Translation.tr("Restart Quickshell"), execute: () => Quickshell.reload(), icon: "refresh", desc: Translation.tr("Restart Quickshell shell seamlessly") },
       ];
       const matches = sysCommands.filter(c => c.cmd.startsWith(queryClean));
       for (const match of matches) {
           const isPendingConfirm = root.confirmKey === match.cmd;
           systemControlResults.push(resultComp.createObject(null, {
               key: "sys:" + match.cmd,
               name: isPendingConfirm ? match.label + " (" + Translation.tr("Are you sure?") + ")" : match.label,
               type: Translation.tr("System Control"),
               comment: isPendingConfirm ? Translation.tr("Press Enter again to confirm") : match.desc,
               verb: isPendingConfirm ? Translation.tr("Confirm") : Translation.tr("Execute"),
               iconName: match.icon,
               iconType: LauncherSearchResult.IconType.Material,
               execute: () => {
                   if (root.confirmKey === match.cmd) {
                       root.confirmKey = "";
                       match.execute();
                   } else {
                       root.confirmKey = match.cmd;
                   }
               }
           }));
       }
   }

   if (systemControlResults.length > 0) {
       result = result.concat(systemControlResults);
   }
   
   if (isMath) {
       result.push(mathResultObject);
   } else if (startsWithShellCommandPrefix) {
       result.push(commandResultObject);
   } else if (startsWithWebSearchPrefix) {
       result.push(webSearchResultObject);
   }
   ```

---

### File 4: Search Rendering Item (`modules/ii/overview/SearchItem.qml`)
Updates how the search launcher delegates render their content.

#### Key Additions & Edits:

1. **Math Formatter Function** (placed in the root component):
   ```js
   function formatMathResult(raw) {
       if (!raw) return { expression: "", value: "" };
       let parts = raw.split("=");
       if (parts.length >= 2) {
           let lhs = parts[0].trim();
           let rhs = parts.slice(1).join("=").trim();
           
           // Clean up LHS multiplying operators and degrees
           lhs = lhs.replace(/\s*\*\s*/g, " ")
                    .replace(/\bdeg\s*\*\s*/gi, "°")
                    .replace(/\bdeg\b/gi, "°");
                    
           // Clean up RHS, swap approx. to 
           rhs = rhs.replace(/\s*\*\s*/g, " ")
                    .replace(/\bdeg\s*\*\s*/gi, "°")
                    .replace(/\bdeg\b/gi, "°")
                    .replace(/\bapprox\.\s*/gi, "≈ ");
                    
           return { expression: lhs, value: rhs };
       }
       return { expression: "", value: raw };
   }
   ```

2. **Custom Content Row & Columns** (inside `contentColumn`):
   Support description titles for system controls, hide standard items when `entry.isMath` is active, and render the premium structured math layout:
   ```qml
   // System Control Comment Subtitle
   StyledText {
       text: root.entry?.comment ?? ""
       font.pixelSize: Appearance.font.pixelSize.smaller
       color: root.isSelected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
       font.family: Appearance.font.family.main
       visible: !!root.entry?.comment && !root.entry?.isMath
       opacity: 0.7
   }

   // Standard Search row layout
   RowLayout {
       visible: !root.entry?.isMath
       // ... standard search icons, urls, and nameText ...
   }

   // Structured Math & Unit Conversion breakdown
   ColumnLayout {
       Layout.fillWidth: true
       visible: !!root.entry?.isMath
       spacing: 4

       StyledText {
           text: Translation.tr("Math & Unit Converter")
           font.pixelSize: Appearance.font.pixelSize.smaller
           color: root.isSelected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
           font.family: Appearance.font.family.main
           opacity: 0.7
       }

       RowLayout {
           spacing: 8
           Layout.fillWidth: true

           // Input Expression (LHS)
           StyledText {
               text: {
                   let parsed = root.formatMathResult(root.itemName);
                   return parsed.expression || root.query;
               }
               font.pixelSize: Appearance.font.pixelSize.small
               font.family: Appearance.font.family.monospace
               color: root.isSelected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
           }

           // Elegant Arrow Indicator
           MaterialSymbol {
               text: "arrow_forward"
               iconSize: Appearance.font.pixelSize.small
               color: Appearance.colors.colPrimary
           }

           // Evaluated Result (RHS)
           StyledText {
               Layout.fillWidth: true
               text: {
                   let parsed = root.formatMathResult(root.itemName);
                   return parsed.value;
               }
               font.pixelSize: Appearance.font.pixelSize.small
               font.family: Appearance.font.family.monospace
               font.bold: true
               color: root.isSelected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colPrimary
           }
       }
   }
   ```

3. **Confirmation Safety Checks (Overview close guards)**:
   Prevent the overview panel from closing when system commands enter their first confirmation step:
   ```js
   // Inside root.allActionItems primary action execute() and onClicked handler:
   const isSystemControl = root.entry?.key?.startsWith("sys:");
   const cmdKey = isSystemControl ? root.entry.key.slice(4) : "";
   const isConfirming = isSystemControl && LauncherSearch.confirmKey !== cmdKey;

   if (!isConfirming) {
       GlobalStates.overviewOpen = false;
   }
   root.itemExecute();
   ```

---

## 3. How to Use & Customize

### Direct Commands
Open the search widget and type one of the system commands:
* **Shutdown**: Type `poweroff` or `pow` ➔ Press `Enter` (Shows confirmation) ➔ Press `Enter` again.
* **Reboot**: Type `reboot` or `re` ➔ Press `Enter` ➔ Press `Enter` again.
* **Lock Session**: Type `lock` or `lo` ➔ Press `Enter` ➔ Press `Enter` again.
* **Suspend (Sleep)**: Type `suspend` or `sus` ➔ Press `Enter` ➔ Press `Enter` again.
* **Restart Shell**: Type `restart` ➔ Press `Enter` ➔ Press `Enter` again.

### Calculations & Conversions
Type equations or conversion formats naturally:
* Mathematical formulas: `(55 + 45) * 4 / 2` or `sqrt(256) * sin(45)`
* Currency conversions: `120 usd to eur` or `450 brl to usd`
* Temperature conversions: `50c to f` or `100f to c`
* Distance/weight conversions: `50 miles to km` or `10 kg to lbs`

The launcher will instantly split the expression, highlight the evaluation in your primary accent color, and show the structured breakdown card directly in the search result pane. Hitting `Enter` will instantly copy the raw evaluated answer to your clipboard!

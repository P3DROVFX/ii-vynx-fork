pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * LocalSend service for receiving/sending files via localsend-cli.
 * Monitors incoming file transfers, scans for devices, and sends files.
 * 
 * Note for the process':
 * I have no idea why, but we have to use bash -lc and also set the PATH environment variable manually
 * Or else it cannot detect localsend-cli and cannot use it's functionalities. 
 * The stupid part is that when we run the shell from the terminal "qs -c ii", everything works perfectly fine without the need of "bash -lc" or setting the PATH. 
 * But it doesnt work when we run it from the keybind. So it may be the problem of the lua integration of hyprland or pip's installation path idk.
 */
Singleton {
    id: root

    property bool available: false
    property bool serverRunning: receiveProc.running
    property bool autoStart: Config.options?.localsend?.autoStart ?? false
    property string downloadPath: Config.options?.localsend?.downloadPath
    property bool showNotifications: Config.options?.localsend?.showNotifications ?? true
    property bool preferPopupOverNotification: Config.options?.localsend?.preferPopupOverNotification ?? true

    // Receive state
    property var currentTransfer: null
    property list<var> pendingTransfers: []

    // Send state
    property list<var> droppedFiles: []
    property list<var> discoveredDevices: []
    property bool sending: false
    property bool scanning: false

    signal transferRequested(var transfer)
    signal transferStarted(var transfer)
    signal transferCompleted(var transfer)
    signal transferCancelled(var transfer)
    signal serverStarted()
    signal serverStopped()
    signal sendCompleted()
    signal sendFailed(string message)

    function isReady(): bool {
        return Config.ready
    }

    function addDroppedFile(fileUrl: string): void {
        const cleanPath = fileUrl.toString().replace(/^file:\/\//, "")
        const name = cleanPath.split("/").pop() || "unknown"
        for (let i = 0; i < root.droppedFiles.length; i++) {
            if (root.droppedFiles[i].path === cleanPath) return
        }
        const newList = root.droppedFiles.slice()
        newList.push({ path: cleanPath, name: name, size: 0 })
        root.droppedFiles = newList
    }

    function removeDroppedFile(index: int): void {
        const newList = root.droppedFiles.slice()
        newList.splice(index, 1)
        root.droppedFiles = newList
    }

    function clearDroppedFiles(): void {
        root.droppedFiles = []
    }

    function formatFileSize(bytes: int): string {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        return (bytes / (1024 * 1024)).toFixed(1) + " MB"
    }

    function sendToDevice(deviceIp: string): void {
        if (!root.available || root.sending || root.droppedFiles.length === 0) return
        root.sending = true
        
        const filePaths = root.droppedFiles.map(f => f.path)
        const cliPath = Directories.home.toString().replace(/^file:\/\//, "") + "/.local/bin/localsend-cli"
        
        const cmd = [cliPath, "send", deviceIp]
        for (let i = 0; i < filePaths.length; i++) {
            cmd.push(filePaths[i])
        }
        cmd.push("--json")
        
        sendProc.command = cmd
        sendProc.running = true
    }

    function cancelSend(): void {
        sendProc.running = false
        root.sending = false
    }

    function startScanning(): void {
        if (!root.available) return
        if (root.scanning) {
            scanProc.running = false
        }
        root.scanning = true
        root.discoveredDevices = []
        scanProc.running = true
    }

    function stopScanning(): void {
        scanProc.running = false
        root.scanning = false
    }

    function openFilePicker(): void {
        if (fileDialogProc.running) return
        fileDialogProc.running = true
    }

    // Process to scan for LocalSend devices on the network using custom hybrid script
    Process {
        id: scanProc
        running: false
        command: ["python3", Directories.home.toString().replace(/^file:\/\//, "") + "/.config/quickshell/ii/services/localsend_scan.py"]
        stdout: SplitParser {
            onRead: line => {
                if (!line || line.trim().length === 0) return
                try {
                    const device = JSON.parse(line)
                    if (device && device.ip) {
                        const newList = root.discoveredDevices.slice()
                        let found = false
                        for (let i = 0; i < newList.length; i++) {
                            if (newList[i].ip === device.ip) { found = true; break }
                        }
                        if (!found) {
                            newList.push({
                                ip: device.ip,
                                name: device.alias || device.name || "Unknown",
                                port: device.port || 53317
                            })
                            root.discoveredDevices = newList
                        }
                    }
                } catch (e) {
                    console.error("[LocalSend] Failed to parse scan line:", line, e)
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            console.log("[LocalSend] Scan completed or exited.")
            root.scanning = false
        }
    }

    // Process to pick multiple files using kdialog (preferred) or zenity (fallback) asynchronously
    Process {
        id: fileDialogProc
        running: false
        command: [
            "bash", "-c",
            "if command -v kdialog >/dev/null; then " +
            "  FILES=$(kdialog --getopenfilename \"$HOME\" \"\" --multiple 2>/dev/null); " +
            "  if [ -n \"$FILES\" ]; then echo -n \"$FILES\" | tr '\\n' '|'; fi; " +
            "elif command -v zenity >/dev/null; then " +
            "  zenity --file-selection --multiple --separator=\"|\" 2>/dev/null; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length === 0) return
                const paths = this.text.trim().split("|")
                for (let i = 0; i < paths.length; i++) {
                    const path = paths[i].trim()
                    if (path.length > 0) {
                        root.addDroppedFile(path)
                    }
                }
            }
        }
    }

    // Check if localsend-cli is available
    Process {
        id: checkAvailabilityProc
        running: true
        command: ["bash", "-lc", "which localsend-cli"]
        environment: ({
            "PATH": Directories.home.toString().replace(/^file:\/\//, "") + "/.local/bin:/usr/local/bin:/usr/bin:/bin"
        })
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0)
            if (root.available && root.autoStart) {
                Qt.callLater(() => {
                    root.startServer()
                })
            }
        }
    }

    // Notification process for incoming transfers
    Process {
        id: notificationProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === "") return
                const action = this.text.trim()
                console.log("[LocalSend] Notification action received:", action)
                if (action === "accept") {
                    root.acceptTransfer()
                } else if (action === "deny") {
                    root.denyTransfer()
                }
            }
        }
    }

    function showIncomingNotification(transfer: var): void {
        const fileNames = transfer.files.map(f => f.name).join(", ")
        const fileSizes = transfer.files.map(f => {
            const size = f.size || 0
            if (size < 1024) return size + " B"
            if (size < 1024 * 1024) return (size / 1024).toFixed(1) + " KB"
            return (size / (1024 * 1024)).toFixed(1) + " MB"
        }).join(", ")

        notificationProc.command = [
            "notify-send",
            Translation.tr("LocalSend: Incoming Transfer"),
            Translation.tr("From: %1\nCheck the clock widget popup on the bar for more information").arg(transfer.sender),
            "-A", "accept=" + Translation.tr("Accept"),
            "-A", "deny=" + Translation.tr("Reject"),
            "-a", "LocalSend",
        ]
        notificationProc.running = true
    }

    // Main receive server process
    Process {
        id: receiveProc
        running: false
        stdinEnabled: true

        environment: ({
            "PATH": Directories.home.toString().replace(/^file:\/\//, "") + "/.local/bin:/usr/local/bin:/usr/bin:/bin"
        })

        stdout: SplitParser {
            onRead: line => {
                if (!line || line.trim().length === 0) return
                try {
                    const event = JSON.parse(line)
                    root.handleLocalSendEvent(event)
                } catch (e) {
                    console.error("[LocalSend] Failed to parse JSON:", line, e)
                }
            }
        }

        stderr: SplitParser {
            onRead: line => {
                console.log("[LocalSend] stderr:", line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("[LocalSend] Server stopped with exit code:", exitCode)
            root.serverStopped()
        }
    }

    // Send process for sending files to a device
    Process {
        id: sendProc
        running: false

        environment: ({
            "PATH": Directories.home.toString().replace(/^file:\/\//, "") + "/.local/bin:/usr/local/bin:/usr/bin:/bin"
        })

        stdout: SplitParser {
            onRead: line => {
                if (!line || line.trim().length === 0) return
                console.log("[LocalSend] Send progress:", line)
                try {
                    const event = JSON.parse(line)
                    if (event.event === "completed" || event.event === "saved" || event.event === "done") {
                        root.clearDroppedFiles()
                        root.sendCompleted()
                    } else if (event.event === "cancelled" || event.error) {
                        root.sendFailed(event.error || "Transfer cancelled")
                    }
                } catch (e) {
                    console.log("[LocalSend] Failed to parse send line:", line, e)
                }
            }
        }

        stderr: SplitParser {
            onRead: line => {
                console.log("[LocalSend] Send stderr:", line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.sending = false
            if (exitCode !== 0) {
                root.sendFailed("Send process exited with code: " + exitCode)
            }
        }
    }

    function handleLocalSendEvent(event: var): void {
        if (!event || !event.event) return
        console.log("[LocalSend] Event:", JSON.stringify(event))

        switch (event.event) {
            case "ready":
                root.serverStarted()
                break

            case "device":
                console.log("[LocalSend] Device registered:", event.alias, event.ip)
                if (event.ip) {
                    const newList = root.discoveredDevices.slice()
                    let found = false
                    for (let i = 0; i < newList.length; i++) {
                        if (newList[i].ip === event.ip) { found = true; break }
                    }
                    if (!found) {
                        newList.push({
                            ip: event.ip,
                            name: event.alias || event.name || "Unknown",
                            port: event.port || 53317
                        })
                        root.discoveredDevices = newList
                    }
                }
                break

            case "incoming":
                const transfer = {
                    sender: event.sender || "Unknown",
                    senderIp: event.ip || "",
                    files: event.files || [],
                    isText: event.is_text || false,
                    sessionId: ""
                }
                root.currentTransfer = transfer
                root.pendingTransfers.push(transfer)
                root.transferRequested(transfer)
                GlobalStates.localSendPopupTransfer = transfer
                if (root.preferPopupOverNotification) {
                    GlobalStates.localSendPopupOpen = true
                }
                break

            case "prompt":
                console.log("[LocalSend] Prompt received, showing notification")
                if (root.currentTransfer && root.showNotifications && !root.preferPopupOverNotification) {
                    root.showIncomingNotification(root.currentTransfer)
                }
                break

            case "text":
                const textTransfer = {
                    sender: event.sender || "Unknown",
                    text: event.text || "",
                    timestamp: Date.now()
                }
                root.transferCompleted(textTransfer)
                if (root.showNotifications) {
                    Quickshell.execDetached([
                        "notify-send",
                        Translation.tr("LocalSend: Text Received"),
                        Translation.tr("From: %1\n%2").arg(event.sender || "Unknown").arg(event.text || ""),
                        "-a", "LocalSend",
                    ])
                }
                root.currentTransfer = null
                GlobalStates.localSendPopupOpen = false
                break

            case "saved":
                console.log("[LocalSend] File saved:", event.path || "unknown path")
                const fileTransfer = {
                    sender: event.sender || "Unknown",
                    fileName: event.name || "",
                    filePath: event.path || root.downloadPath + "/" + (event.name || ""),
                    fileSize: event.size || 0,
                    timestamp: Date.now()
                }
                root.transferCompleted(fileTransfer)
                if (root.showNotifications) {
                    Quickshell.execDetached([
                        "notify-send",
                        Translation.tr("LocalSend: File Received"),
                        Translation.tr("From: %1\nOutput path: %2").arg(event.sender || "Unknown").arg(event.path || "unknown path"),
                        "-a", "LocalSend",
                    ])
                }
                root.currentTransfer = null
                GlobalStates.localSendPopupOpen = false
                break

            case "cancelled":
                root.transferCancelled(event)
                root.currentTransfer = null
                GlobalStates.localSendPopupOpen = false
                break
        }
    }
    
    Timer {
        id: serverStartDelayTimer
        interval: 500
        onTriggered: {
            const cliPath = Directories.home.toString().replace(/^file:\/\//, "") + "/.local/bin/localsend-cli"
            receiveProc.command = [cliPath, "receive", "--interactive-json", "--output", root.downloadPath]
            console.log("[LocalSend] Starting receive server with output dir:", root.downloadPath)
            receiveProc.running = true
        }
    }

    function startServer(): void {
        if (!root.available) {
            Quickshell.execDetached(["notify-send", Translation.tr("LocalSend Error"), Translation.tr("localsend-cli is not available. You can install it with <tt>pip install localsend-cli</tt>. Check the docs for further details."), "-a", "LocalSend"])
            console.warn("[LocalSend] localsend-cli is not available")
            return
        }
        if (receiveProc.running) {
            console.log("[LocalSend] Server is already running")
            return
        }

        // kill any existing servers
        // or else it gives an error saying "address already in use" and doesn't start
        Quickshell.execDetached(["pkill", "-f", "localsend-cli"])
        serverStartDelayTimer.restart()
    }

    function stopServer(): void {
        console.log("[LocalSend] Stopping receive server...")
        receiveProc.running = false
    }

    function restartServer(): void {
        if (receiveProc.running) {
            console.log("[LocalSend] Restarting server...")
            receiveProc.running = false
            // Wait for process to stop, then start again
            restartDelayTimer.restart()
        } else if (root.available) {
            root.startServer()
        }
    }

    Timer {
        id: restartDelayTimer
        interval: 2000 // 2 seconds delay
        repeat: false
        onTriggered: {
            console.log("[LocalSend] Restarting server after delay...")
            root.startServer()
        }
    }

    function acceptTransfer(): void {
        console.log("[LocalSend] Accepting transfer...")
        receiveProc.write("y\n")
        root.currentTransfer = null
        GlobalStates.localSendPopupOpen = false
    }

    function denyTransfer(): void {
        console.log("[LocalSend] Denying transfer...")
        root.currentTransfer = null
        receiveProc.write("n\n")
        GlobalStates.localSendPopupOpen = false
    }

    function getPendingTransfers(): list<var> {
        return root.pendingTransfers
    }

    function clearPendingTransfers(): void {
        root.pendingTransfers = []
    }

    onDownloadPathChanged: {
        // Restart server if download path changed while running
        if (receiveProc.running) {
            console.log("[LocalSend] Download path changed, restarting server...")
            root.restartServer()
        }
    }

    IpcHandler {
        target: "localsend"

        function start(): void {
            root.startServer()
        }

        function stop(): void {
            root.stopServer()
        }

        function status(): string {
            return JSON.stringify({
                available: root.available,
                running: root.serverRunning,
                downloadPath: root.downloadPath
            })
        }
    }
}
